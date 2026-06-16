import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../providers/customer_provider.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';

enum PaperType { blank, dots, grid, lines }
enum MannequinType { none, male, female, boy, girl }
enum NotebookMode { draw, text, pan }

class TextNote {
  String text;
  Offset position;
  Color color;
  double fontSize;

  TextNote({
    required this.text,
    required this.position,
    required this.color,
    this.fontSize = 16.0,
  });
}

class Stroke {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;
  final bool isHighlighter;

  Stroke({
    required this.points,
    required this.color,
    required this.strokeWidth,
    this.isHighlighter = false,
  });
}

class ScribbleScreen extends StatefulWidget {
  final String customerId;

  const ScribbleScreen({Key? key, required this.customerId}) : super(key: key);

  @override
  State<ScribbleScreen> createState() => _ScribbleScreenState();
}

class _ScribbleScreenState extends State<ScribbleScreen> {
  final SupabaseService _service = SupabaseService();
  bool _isSaving = false;
  
  NotebookMode _notebookMode = NotebookMode.draw;
  bool get _isScrollMode => _notebookMode == NotebookMode.pan;
  bool get _isTextMode => _notebookMode == NotebookMode.text;
  bool get _isDrawMode => _notebookMode == NotebookMode.draw;

  double _canvasHeight = 800; // Dynamically updated
  bool _isInitialized = false;
  final GlobalKey _boundaryKey = GlobalKey();

  Color _selectedColor = Colors.black;
  double _selectedStroke = 3.0;
  MannequinType _mannequinType = MannequinType.none;
  bool _isHighlighter = false;
  PaperType _paperType = PaperType.dots;
  bool _showPaperSelector = false;
  bool _showMannequinSelector = false;

  List<Stroke> _strokes = [];
  List<Stroke> _redoStrokes = [];
  Stroke? _currentStroke;
  List<TextNote> _textNotes = [];

  String? _customerName;

  @override
  void initState() {
    super.initState();
    _loadCustomerName();
  }

  void _loadCustomerName() {
    try {
      final provider = Provider.of<CustomerProvider>(context, listen: false);
      final customer = provider.customers.firstWhere((c) => c.id == widget.customerId);
      setState(() {
        _customerName = customer.name;
      });
    } catch (_) {}
  }

  String _formatToday() {
    final now = DateTime.now();
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${now.day} ${months[now.month - 1]}, ${now.year}';
  }

  void _onPanStart(DragStartDetails details) {
    if (!_isDrawMode) return;
    setState(() {
      _currentStroke = Stroke(
        points: [details.localPosition],
        color: _selectedColor,
        strokeWidth: _selectedStroke,
        isHighlighter: _isHighlighter,
      );
      _redoStrokes.clear();
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isDrawMode || _currentStroke == null) return;
    setState(() {
      final updatedPoints = List<Offset>.from(_currentStroke!.points)..add(details.localPosition);
      _currentStroke = Stroke(
        points: updatedPoints,
        color: _currentStroke!.color,
        strokeWidth: _currentStroke!.strokeWidth,
        isHighlighter: _currentStroke!.isHighlighter,
      );
      
      // Auto-expand canvas if drawing reaches near bottom bounds
      if (details.localPosition.dy > _canvasHeight - 150) {
        _canvasHeight += 600;
      }
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (!_isDrawMode || _currentStroke == null) return;
    setState(() {
      _strokes.add(_currentStroke!);
      _currentStroke = null;
    });
  }

  void _undo() {
    if (_strokes.isNotEmpty) {
      setState(() {
        _redoStrokes.add(_strokes.removeLast());
      });
    }
  }

  void _redo() {
    if (_redoStrokes.isNotEmpty) {
      setState(() {
        _strokes.add(_redoStrokes.removeLast());
      });
    }
  }

  void _clear() {
    setState(() {
      _strokes.clear();
      _redoStrokes.clear();
      _currentStroke = null;
      _textNotes.clear();
    });
  }

  String _getMannequinFrontImagePath(MannequinType type) {
    switch (type) {
      case MannequinType.male:
        return 'lib/Mannequin/Male Manequin Front.png';
      case MannequinType.female:
        return 'lib/Mannequin/Female Manequin Front.png';
      case MannequinType.boy:
        return 'lib/Mannequin/Boy Manequin Front.png';
      case MannequinType.girl:
        return 'lib/Mannequin/Girl Manequin Front.png';
      case MannequinType.none:
        return '';
    }
  }

  String _getMannequinBackImagePath(MannequinType type) {
    switch (type) {
      case MannequinType.male:
        return 'lib/Mannequin/Male Manequin Back.png';
      case MannequinType.female:
        return 'lib/Mannequin/Female Manequin Back.png';
      case MannequinType.boy:
        return 'lib/Mannequin/Boy Manequin Back.png';
      case MannequinType.girl:
        return 'lib/Mannequin/Girl Manequin Back.png';
      case MannequinType.none:
        return '';
    }
  }


  void _addTextNoteAt(Offset position) {
    final newNote = TextNote(
      text: '',
      position: position,
      color: _selectedColor,
    );
    _showTextNoteDialog(newNote, isNew: true);
  }

  void _showTextNoteDialog(TextNote note, {bool isNew = false}) {
    final controller = TextEditingController(text: note.text);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isNew ? 'Add Text Note' : 'Edit Text Note', style: const TextStyle(fontWeight: FontWeight.bold)),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Type your note here...',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          actions: [
            if (!isNew)
              TextButton(
                onPressed: () {
                  setState(() {
                    _textNotes.remove(note);
                  });
                  Navigator.pop(context);
                },
                child: const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final txt = controller.text.trim();
                if (txt.isNotEmpty) {
                  setState(() {
                    note.text = txt;
                    if (isNew) {
                      _textNotes.add(note);
                    }
                  });
                }
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
              child: Text(isNew ? 'Add' : 'Save', style: const TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveScribble() async {
    if (_strokes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Canvas is empty!')));
      return;
    }

    setState(() => _isSaving = true);
    try {
      final boundary = _boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw Exception('Unable to capture drawing boundary');

      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('Failed to encode image data');

      final exportBytes = byteData.buffer.asUint8List();

      await _service.uploadScribble(widget.customerId, exportBytes);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Digital Note saved!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _downloadAsPdf() async {
    setState(() => _isSaving = true);
    try {
      final boundary = _boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw Exception('Unable to capture drawing boundary');

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('Failed to encode image data');

      final exportBytes = byteData.buffer.asUint8List();

      final pdf = pw.Document();
      final pdfImage = pw.MemoryImage(exportBytes);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Image(pdfImage, fit: pw.BoxFit.contain),
            );
          },
        ),
      );

      final pdfBytes = await pdf.save();
      final filename = 'Digital_Note_${_customerName ?? widget.customerId}.pdf';

      if (kIsWeb) {
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdfBytes,
          name: filename,
        );
      } else {
        await Printing.sharePdf(
          bytes: pdfBytes,
          filename: filename,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error generating PDF: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Widget _buildColorDot(Color color, String label) {
    final isSelected = _selectedColor == color;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedColor = color;
        });
      },
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected 
              ? Border.all(color: AppTheme.primary, width: 2) 
              : Border.all(color: Colors.grey.shade300, width: 1),
          boxShadow: isSelected 
              ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 6, spreadRadius: 1)]
              : [],
        ),
      ),
    );
  }

  Widget _buildStrokePill(double width, String label) {
    final isSelected = _selectedStroke == width;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStroke = width;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withValues(alpha: 0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primary : Colors.transparent,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  IconData _getPaperIcon(PaperType type) {
    switch (type) {
      case PaperType.blank:
        return Icons.crop_din;
      case PaperType.dots:
        return Icons.blur_on;
      case PaperType.grid:
        return Icons.grid_3x3;
      case PaperType.lines:
        return Icons.notes;
    }
  }

  Widget _buildPaperTypeSelector() {
    if (!_showPaperSelector) {
      return GestureDetector(
        onTap: () {
          setState(() {
            _showPaperSelector = true;
            _showMannequinSelector = false; // Collapse the other to save space
          });
        },
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Icon(
            _getPaperIcon(_paperType),
            size: 20,
            color: AppTheme.primary,
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _showPaperSelector = false;
              });
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Icon(
                Icons.chevron_left,
                size: 18,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          ...PaperType.values.map((type) {
            final isSelected = _paperType == type;
            return GestureDetector(
              onTap: () => setState(() {
                _paperType = type;
                _showPaperSelector = false; // Auto-collapse
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isSelected
                      ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))]
                      : [],
                ),
                child: Icon(
                  _getPaperIcon(type),
                  size: 16,
                  color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildMannequinTypeSelector() {
    if (!_showMannequinSelector) {
      IconData mainIcon = Icons.accessibility_new;
      if (_mannequinType != MannequinType.none) {
        switch (_mannequinType) {
          case MannequinType.male:
            mainIcon = Icons.male;
            break;
          case MannequinType.female:
            mainIcon = Icons.female;
            break;
          case MannequinType.boy:
            mainIcon = Icons.boy;
            break;
          case MannequinType.girl:
            mainIcon = Icons.girl;
            break;
          default:
            break;
        }
      }
      return GestureDetector(
        onTap: () {
          setState(() {
            _showMannequinSelector = true;
            _showPaperSelector = false; // Collapse the other to save space
          });
        },
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Icon(
            mainIcon,
            size: 20,
            color: _mannequinType != MannequinType.none ? AppTheme.primary : AppTheme.textSecondary,
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _showMannequinSelector = false;
              });
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Icon(
                Icons.chevron_left,
                size: 18,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          ...MannequinType.values.map((type) {
            final isSelected = _mannequinType == type;
            IconData icon;
            switch (type) {
              case MannequinType.none:
                icon = Icons.close;
                break;
              case MannequinType.male:
                icon = Icons.male;
                break;
              case MannequinType.female:
                icon = Icons.female;
                break;
              case MannequinType.boy:
                icon = Icons.boy;
                break;
              case MannequinType.girl:
                icon = Icons.girl;
                break;
            }
            return GestureDetector(
              onTap: () => setState(() {
                _mannequinType = type;
                _showMannequinSelector = false; // Auto-collapse
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isSelected
                      ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))]
                      : [],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 16,
                      color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 4),
                      Text(
                        type == MannequinType.none ? 'Off' : type.name.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      final screenHeight = MediaQuery.of(context).size.height;
      _canvasHeight = screenHeight > 800 ? screenHeight : 800;
      _isInitialized = true;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Digital Note'),
        actions: [
          IconButton(
            onPressed: _downloadAsPdf,
            icon: const Icon(Icons.download_rounded, color: AppTheme.primary),
            tooltip: 'Download PDF',
          ),
          const SizedBox(width: 8),
          _isSaving
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2),
                    ),
                  ),
                )
              : TextButton.icon(
                  onPressed: _saveScribble,
                  icon: const Icon(Icons.check, color: AppTheme.primary),
                  label: const Text('Save Note', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // Canvas Layer (Pannable area)
          Positioned.fill(
            child: InteractiveViewer(
              panEnabled: _isScrollMode,
              scaleEnabled: _isScrollMode,
              minScale: 1.0,
              maxScale: 4.0,
              child: SingleChildScrollView(
                physics: _isScrollMode
                    ? const AlwaysScrollableScrollPhysics()
                    : const NeverScrollableScrollPhysics(),
                child: RepaintBoundary(
                  key: _boundaryKey,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    height: _canvasHeight,
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Spec-sheet Branded Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'SOUL COUTURE',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2.0,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                const Text(
                                  'DESIGN STUDIO SPEC SHEET',
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                border: Border.all(color: const Color(0xFF1E293B), width: 1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'PREMIUM WORKSPACE',
                                style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(height: 1.5, color: const Color(0xFFE2E8F0)),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'CLIENT: ${_customerName?.toUpperCase() ?? widget.customerId.substring(0, 8).toUpperCase()}',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                            ),
                            Text(
                              'DATE: ${_formatToday()}',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Inner Drawing Board Container
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Stack(
                              children: [
                                // Background Paper Pattern
                                Positioned.fill(
                                  child: CustomPaint(
                                    painter: _PaperBackgroundPainter(paperType: _paperType),
                                  ),
                                ),
                                // Faint Mannequin sketch template overlay
                                if (_mannequinType != MannequinType.none) ...[
                                  Positioned.fill(
                                    child: CustomPaint(
                                      painter: _MannequinTemplatePainter(type: _mannequinType),
                                    ),
                                  ),
                                  Positioned.fill(
                                    child: Center(
                                      child: SizedBox(
                                        width: 340.0,
                                        height: 460.0,
                                        child: Padding(
                                          padding: const EdgeInsets.only(top: 40.0),
                                          child: Opacity(
                                            opacity: 0.22,
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Image.asset(
                                                    _getMannequinFrontImagePath(_mannequinType),
                                                    fit: BoxFit.contain,
                                                  ),
                                                ),
                                                const SizedBox(width: 20.0), // Gap between front and back images
                                                Expanded(
                                                  child: Image.asset(
                                                    _getMannequinBackImagePath(_mannequinType),
                                                    fit: BoxFit.contain,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                                // Drawing Ink Layer
                                Positioned.fill(
                                  child: IgnorePointer(
                                    ignoring: _isScrollMode,
                                    child: GestureDetector(
                                      onPanStart: _onPanStart,
                                      onPanUpdate: _onPanUpdate,
                                      onPanEnd: _onPanEnd,
                                      onTapDown: (details) {
                                        if (_isTextMode) {
                                          _addTextNoteAt(details.localPosition);
                                        }
                                      },
                                      child: CustomPaint(
                                        painter: _DrawingPainter(
                                          strokes: _strokes,
                                          currentStroke: _currentStroke,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                // Text Notes Layer
                                Positioned.fill(
                                  child: IgnorePointer(
                                    ignoring: _isScrollMode,
                                    child: Stack(
                                      children: _textNotes.map((note) {
                                        return Positioned(
                                          left: note.position.dx,
                                          top: note.position.dy,
                                          child: GestureDetector(
                                            onPanUpdate: (details) {
                                              setState(() {
                                                note.position = Offset(
                                                  note.position.dx + details.delta.dx,
                                                  note.position.dy + details.delta.dy,
                                                );
                                              });
                                            },
                                            onTap: () {
                                              _showTextNoteDialog(note);
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(alpha: 0.9),
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(
                                                  color: AppTheme.primary.withValues(alpha: 0.3),
                                                  width: 1,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withValues(alpha: 0.05),
                                                    blurRadius: 4,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: Text(
                                                note.text,
                                                style: TextStyle(
                                                  color: note.color,
                                                  fontSize: note.fontSize,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Outer edge frame indicator in scroll mode
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _isScrollMode ? AppTheme.primary.withValues(alpha: 0.5) : Colors.transparent,
                    width: 4,
                  ),
                ),
              ),
            ),
          ),

          // Colors, Styles & Tools Floating Panel
          Positioned(
            bottom: 104, 
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width - 32),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 8))
                  ],
                  border: Border.all(color: const Color(0xFFE3E8EE)),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Color dots (5 default colors)
                      _buildColorDot(Colors.black, 'Onyx'),
                      const SizedBox(width: 8),
                      _buildColorDot(const Color(0xFF1E3A8A), 'Navy'), 
                      const SizedBox(width: 8),
                      _buildColorDot(const Color(0xFF10B981), 'Teal'), 
                      const SizedBox(width: 8),
                      _buildColorDot(const Color(0xFFEF4444), 'Red'), 
                      const SizedBox(width: 8),
                      _buildColorDot(const Color(0xFF8B5CF6), 'Violet'),
                      
                      const SizedBox(width: 16),
                      Container(width: 1, height: 20, color: const Color(0xFFE3E8EE)),
                      const SizedBox(width: 16),
                      
                      // Stroke width selection
                      _buildStrokePill(2.0, 'Fine'),
                      const SizedBox(width: 8),
                      _buildStrokePill(5.0, 'Med'),
                      const SizedBox(width: 8),
                      _buildStrokePill(9.0, 'Bold'),

                      const SizedBox(width: 16),
                      Container(width: 1, height: 20, color: const Color(0xFFE3E8EE)),
                      const SizedBox(width: 16),

                      // Paper style selector (premium inline control)
                      _buildPaperTypeSelector(),
                      const SizedBox(width: 16),
                      Container(width: 1, height: 20, color: const Color(0xFFE3E8EE)),
                      const SizedBox(width: 16),

                      // Mannequin template selector (premium inline control)
                      _buildMannequinTypeSelector(),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Primary mode Toolbar Panel
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width - 32),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 30, offset: const Offset(0, 10))
                  ],
                  border: Border.all(color: const Color(0xFFE3E8EE)),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Mode Toggle Draw/Text/Pan
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.background,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _ModeToggleButton(
                              icon: Icons.draw_outlined,
                              label: 'Draw',
                              isSelected: _isDrawMode,
                              onTap: () => setState(() => _notebookMode = NotebookMode.draw),
                            ),
                            _ModeToggleButton(
                              icon: Icons.keyboard_alt_outlined,
                              label: 'Text',
                              isSelected: _isTextMode,
                              onTap: () => setState(() => _notebookMode = NotebookMode.text),
                            ),
                            _ModeToggleButton(
                              icon: Icons.pan_tool_outlined,
                              label: 'Pan',
                              isSelected: _isScrollMode,
                              onTap: () => setState(() => _notebookMode = NotebookMode.pan),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(width: 1, height: 24, color: const Color(0xFFE3E8EE)),
                      const SizedBox(width: 12),

                      // Tool type Toggle Pen/Highlighter
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.background,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _ModeToggleButton(
                              icon: Icons.edit_rounded,
                              label: 'Pen',
                              isSelected: !_isHighlighter,
                              onTap: () {
                                setState(() {
                                  _isHighlighter = false;
                                  _selectedStroke = 3.0; // Fine/Med default
                                });
                              },
                            ),
                            _ModeToggleButton(
                              icon: Icons.border_color_rounded,
                              label: 'Highlighter',
                              isSelected: _isHighlighter,
                              onTap: () {
                                setState(() {
                                  _isHighlighter = true;
                                  _selectedStroke = 12.0; // Highlighting default
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),

                      // Actions
                      IconButton(
                        onPressed: _undo,
                        icon: const Icon(Icons.undo, color: AppTheme.textSecondary, size: 20),
                        tooltip: 'Undo',
                      ),
                      IconButton(
                        onPressed: _redo,
                        icon: const Icon(Icons.redo, color: AppTheme.textSecondary, size: 20),
                        tooltip: 'Redo',
                      ),
                      IconButton(
                        onPressed: _clear,
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                        tooltip: 'Clear All',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Background Grid/Ruled Notebook Painter
class _PaperBackgroundPainter extends CustomPainter {
  final PaperType paperType;

  _PaperBackgroundPainter({required this.paperType});

  @override
  void paint(Canvas canvas, Size size) {
    if (paperType == PaperType.blank) return;

    final paint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 0.8;

    final double spacing = 24.0;

    if (paperType == PaperType.dots) {
      final dotPaint = Paint()
        ..color = const Color(0xFFCBD5E1)
        ..style = PaintingStyle.fill;
      for (double x = spacing; x < size.width; x += spacing) {
        for (double y = spacing; y < size.height; y += spacing) {
          canvas.drawCircle(Offset(x, y), 1.0, dotPaint);
        }
      }
    } else if (paperType == PaperType.grid) {
      for (double x = spacing; x < size.width; x += spacing) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      }
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      }
    } else if (paperType == PaperType.lines) {
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      }
      final marginPaint = Paint()
        ..color = const Color(0xFFFCA5A5)
        ..strokeWidth = 1.2;
      canvas.drawLine(const Offset(40, 0), Offset(40, size.height), marginPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PaperBackgroundPainter oldDelegate) {
    return oldDelegate.paperType != paperType;
  }
}

// Legs silhouette mannequin drawing template
// Legs silhouette mannequin drawing template
class _MannequinTemplatePainter extends CustomPainter {
  final MannequinType type;

  _MannequinTemplatePainter({required this.type});

  @override
  void paint(Canvas canvas, Size size) {
    if (type == MannequinType.none) return;

    final w = size.width;

    // Use a unified centered box of size 340 x 460
    const double boxW = 340.0;
    const double gap = 20.0;
    const double imageW = (boxW - gap) / 2; // 160.0
    
    final double startX = (w - boxW) / 2;
    const double topY = 20.0;
    
    final double frontCenter = startX + imageW / 2; // startX + 80.0
    final double backCenter = startX + imageW + gap + imageW / 2; // startX + 260.0


    final linePaint = Paint()
      ..color = const Color(0xFF94A3B8).withValues(alpha: 0.15)
      ..strokeWidth = 0.8;

    // Draw Labels on top
    _drawLabel(canvas, 'FRONT VIEW', frontCenter, topY + 5);
    _drawLabel(canvas, 'BACK VIEW', backCenter, topY + 5);

    // Guidelines for body height reference (subtle spec sheet vibe)
    const double mannequinH = 390.0;
    const double startMannequinY = topY + 40.0;
    
    // Shoulders, Waist, Hips horizontal guides across both templates
    _drawDashedLine(canvas, Offset(frontCenter - 75, startMannequinY + mannequinH * 0.17), Offset(backCenter + 75, startMannequinY + mannequinH * 0.17), linePaint);
    _drawDashedLine(canvas, Offset(frontCenter - 75, startMannequinY + mannequinH * 0.35), Offset(backCenter + 75, startMannequinY + mannequinH * 0.35), linePaint);
    _drawDashedLine(canvas, Offset(frontCenter - 75, startMannequinY + mannequinH * 0.44), Offset(backCenter + 75, startMannequinY + mannequinH * 0.44), linePaint);

  }

  void _drawLabel(Canvas canvas, String text, double centerX, double y) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Color(0xFF64748B), // Slate 500
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 2.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(centerX - textPainter.width / 2, y),
    );
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const double dashWidth = 6;
    const double dashSpace = 4;
    final double distance = (p2 - p1).distance;
    final double dx = p2.dx - p1.dx;
    final double dy = p2.dy - p1.dy;
    
    double currentDistance = 0;
    while (currentDistance < distance) {
      final double startRatio = currentDistance / distance;
      final double endRatio = (currentDistance + dashWidth) / distance;
      final double clampedEndRatio = endRatio > 1.0 ? 1.0 : endRatio;
      
      canvas.drawLine(
        Offset(p1.dx + dx * startRatio, p1.dy + dy * startRatio),
        Offset(p1.dx + dx * clampedEndRatio, p1.dy + dy * clampedEndRatio),
        paint,
      );
      currentDistance += dashWidth + dashSpace;
    }
  }



  @override
  bool shouldRepaint(covariant _MannequinTemplatePainter oldDelegate) {
    return oldDelegate.type != type;
  }
}

// Stroke drawing canvas painter
class _DrawingPainter extends CustomPainter {
  final List<Stroke> strokes;
  final Stroke? currentStroke;

  _DrawingPainter({required this.strokes, this.currentStroke});

  @override
  void paint(Canvas canvas, Size size) {
    // Draw past strokes
    for (final stroke in strokes) {
      _drawStroke(canvas, stroke);
    }
    
    // Draw current stroke
    if (currentStroke != null) {
      _drawStroke(canvas, currentStroke!);
    }
  }

  void _drawStroke(Canvas canvas, Stroke stroke) {
    if (stroke.points.isEmpty) return;
    
    final paint = Paint()
      ..color = stroke.isHighlighter 
          ? stroke.color.withValues(alpha: 0.3) 
          : stroke.color
      ..strokeWidth = stroke.strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
      
    final path = Path();
    path.moveTo(stroke.points.first.dx, stroke.points.first.dy);
    
    for (int i = 1; i < stroke.points.length; i++) {
      path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
    }
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _DrawingPainter oldDelegate) => true;
}

// Internal Mode Toggle Button
class _ModeToggleButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeToggleButton({required this.icon, required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? AppTheme.primary : AppTheme.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}



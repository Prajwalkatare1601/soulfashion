import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';

import '../providers/customer_provider.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';

enum PaperType { blank, dots, grid, lines }

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
  
  bool _isScrollMode = false;
  double _canvasHeight = 800; // Dynamically updated
  bool _isInitialized = false;
  final GlobalKey _boundaryKey = GlobalKey();

  Color _selectedColor = Colors.black;
  double _selectedStroke = 3.0;
  bool _showMannequin = false;
  bool _isHighlighter = false;
  PaperType _paperType = PaperType.dots;

  List<Stroke> _strokes = [];
  List<Stroke> _redoStrokes = [];
  Stroke? _currentStroke;

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
    if (_isScrollMode) return;
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
    if (_isScrollMode || _currentStroke == null) return;
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
    if (_isScrollMode || _currentStroke == null) return;
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
    });
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

  void _cyclePaperType() {
    setState(() {
      final nextIndex = (_paperType.index + 1) % PaperType.values.length;
      _paperType = PaperType.values[nextIndex];
    });
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
                                  'SOUL FASHION',
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
                                // Faint Mannequin leg sketch template overlay
                                if (_showMannequin)
                                  Positioned.fill(
                                    child: CustomPaint(
                                      painter: _MannequinTemplatePainter(),
                                    ),
                                  ),
                                // Drawing Ink Layer
                                Positioned.fill(
                                  child: IgnorePointer(
                                    ignoring: _isScrollMode,
                                    child: GestureDetector(
                                      onPanStart: _onPanStart,
                                      onPanUpdate: _onPanUpdate,
                                      onPanEnd: _onPanEnd,
                                      child: CustomPaint(
                                        painter: _DrawingPainter(
                                          strokes: _strokes,
                                          currentStroke: _currentStroke,
                                        ),
                                      ),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 8))
                  ],
                  border: Border.all(color: const Color(0xFFE3E8EE)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Color dots
                    _buildColorDot(Colors.black, 'Onyx'),
                    const SizedBox(width: 8),
                    _buildColorDot(const Color(0xFF1E3A8A), 'Navy'), 
                    const SizedBox(width: 8),
                    _buildColorDot(const Color(0xFF10B981), 'Teal'), 
                    const SizedBox(width: 8),
                    _buildColorDot(const Color(0xFFEF4444), 'Red'), 
                    
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

                    // Paper style cycle
                    IconButton(
                      icon: Icon(_getPaperIcon(_paperType), color: AppTheme.textSecondary, size: 20),
                      onPressed: _cyclePaperType,
                      tooltip: 'Paper Style: ${_paperType.name}',
                    ),
                    const SizedBox(width: 8),

                    // Legs template toggle
                    IconButton(
                      icon: Icon(
                        _showMannequin ? Icons.accessibility_new_rounded : Icons.accessibility_new_outlined,
                        color: _showMannequin ? AppTheme.primary : AppTheme.textSecondary,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _showMannequin = !_showMannequin;
                        });
                      },
                      tooltip: 'Bottom Template Guide',
                    ),
                  ],
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 30, offset: const Offset(0, 10))
                  ],
                  border: Border.all(color: const Color(0xFFE3E8EE)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Mode Toggle Draw/Pan
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
                            isSelected: !_isScrollMode,
                            onTap: () => setState(() => _isScrollMode = false),
                          ),
                          _ModeToggleButton(
                            icon: Icons.pan_tool_outlined,
                            label: 'Pan',
                            isSelected: _isScrollMode,
                            onTap: () => setState(() => _isScrollMode = true),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(width: 1, height: 24, color: const Color(0xFFE3E8EE)),
                    const SizedBox(width: 12),

                    // Highlighter pen mode toggle
                    Container(
                      decoration: BoxDecoration(
                        color: _isHighlighter ? AppTheme.primary.withValues(alpha: 0.08) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: Icon(
                          _isHighlighter ? Icons.border_color_rounded : Icons.edit_rounded,
                          color: _isHighlighter ? AppTheme.primary : AppTheme.textSecondary,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _isHighlighter = !_isHighlighter;
                            // Set default sizes corresponding to the mode
                            _selectedStroke = _isHighlighter ? 12.0 : 4.0;
                          });
                        },
                        tooltip: _isHighlighter ? 'Highlighter Mode' : 'Pen Mode',
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
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: FloatingActionButton.extended(
          onPressed: _isSaving ? null : _saveScribble,
          icon: _isSaving 
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.check),
          label: Text(_isSaving ? 'Saving...' : 'Save Note', style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
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
class _MannequinTemplatePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final paintBase = Paint()
      ..color = const Color(0xFFE2E8F0).withValues(alpha: 0.8)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final bottomPath = Path()
      ..moveTo(w * 0.39, h * 0.15)
      ..lineTo(w * 0.61, h * 0.15) // waist top
      ..quadraticBezierTo(w * 0.67, h * 0.22, w * 0.67, h * 0.30) // right hip
      ..lineTo(w * 0.64, h * 0.85) // right outer leg
      ..lineTo(w * 0.56, h * 0.85) // right cuff
      ..lineTo(w * 0.5, h * 0.38) // right inner leg to crotch
      ..lineTo(w * 0.44, h * 0.85) // left inner leg from crotch
      ..lineTo(w * 0.36, h * 0.85) // left cuff
      ..lineTo(w * 0.33, h * 0.30) // left outer leg
      ..quadraticBezierTo(w * 0.33, h * 0.22, w * 0.39, h * 0.15) // left hip
      ..close();

    canvas.drawPath(bottomPath, paintBase);
  }

  @override
  bool shouldRepaint(covariant _MannequinTemplatePainter oldDelegate) => false;
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

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:signature/signature.dart';

import '../services/supabase_service.dart';
import '../theme/app_theme.dart';

class ScribbleScreen extends StatefulWidget {
  final String customerId;

  const ScribbleScreen({Key? key, required this.customerId}) : super(key: key);

  @override
  State<ScribbleScreen> createState() => _ScribbleScreenState();
}

class _ScribbleScreenState extends State<ScribbleScreen> {
  late SignatureController _controller;
  final SupabaseService _service = SupabaseService();
  bool _isSaving = false;
  
  bool _isScrollMode = false;
  double _canvasHeight = 800; // Dynamically updated
  bool _isInitialized = false;
  final GlobalKey _boundaryKey = GlobalKey();

  Color _selectedColor = Colors.black;
  double _selectedStroke = 3.0;
  bool _showMannequin = false;

  @override
  void initState() {
    super.initState();
    _controller = SignatureController(
      penStrokeWidth: _selectedStroke,
      penColor: _selectedColor,
      exportBackgroundColor: Colors.transparent,
    );
    _controller.addListener(_onCanvasActivity);
  }

  void _onCanvasActivity() {
    if (_controller.points.isNotEmpty) {
      try {
        final lastPoint = _controller.points.last;
        final dy = lastPoint.offset.dy;
        if (dy > _canvasHeight - 150) {
          setState(() {
            _canvasHeight += 600; 
          });
        }
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateController({Color? color, double? stroke}) {
    setState(() {
      if (color != null) _selectedColor = color;
      if (stroke != null) _selectedStroke = stroke;
      
      final oldPoints = List<Point>.from(_controller.points);
      
      _controller.removeListener(_onCanvasActivity);
      _controller.dispose();
      
      _controller = SignatureController(
        penColor: _selectedColor,
        penStrokeWidth: _selectedStroke,
        points: oldPoints,
        exportBackgroundColor: Colors.transparent,
      );
      
      _controller.addListener(_onCanvasActivity);
    });
  }

  Future<void> _saveScribble() async {
    if (_controller.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Canvas is empty!')));
      return;
    }

    setState(() => _isSaving = true);
    try {
      // Export grid + signature directly using RepaintBoundary
      final boundary = _boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw Exception('Unable to capture drawing boundary');

      final image = await boundary.toImage(pixelRatio: 2.0); // Hi-res export ensures sharp text
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
        _updateController(color: color);
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
              ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 6, spreadRadius: 1)]
              : [],
        ),
      ),
    );
  }

  Widget _buildStrokePill(double width, String label) {
    final isSelected = _selectedStroke == width;
    return GestureDetector(
      onTap: () {
        _updateController(stroke: width);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withOpacity(0.08) : Colors.transparent,
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
                    height: _canvasHeight,
                    color: Colors.white,
                    child: Stack(
                      children: [
                        // Dot Matrix Blueprint Background
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _DotGridPainter(),
                          ),
                        ),
                        // Mannequin sketch template overlay
                        if (_showMannequin)
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _MannequinTemplatePainter(),
                            ),
                          ),
                        // Ink Layer
                        Positioned.fill(
                          child: IgnorePointer(
                            ignoring: _isScrollMode,
                            child: Signature(
                              controller: _controller,
                              backgroundColor: Colors.transparent,
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
          
          // Outer edge frame indicator
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _isScrollMode ? AppTheme.primary.withOpacity(0.5) : Colors.transparent,
                    width: 4,
                  ),
                ),
              ),
            ),
          ),

          // Colors & Tools Floating Panel
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
                    BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 8))
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
                    _buildStrokePill(4.0, 'Med'),
                    const SizedBox(width: 8),
                    _buildStrokePill(7.0, 'Bold'),

                    const SizedBox(width: 16),
                    Container(width: 1, height: 20, color: const Color(0xFFE3E8EE)),
                    const SizedBox(width: 16),

                    // Mannequin Template Toggle Button
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
                      tooltip: 'Mannequin Template',
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Simplified Toolbar Layer
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
                    BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 30, offset: const Offset(0, 10))
                  ],
                  border: Border.all(color: const Color(0xFFE3E8EE)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Mode Toggle Pill
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
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _controller.undo(),
                      icon: const Icon(Icons.undo, color: AppTheme.textSecondary),
                      tooltip: 'Undo',
                    ),
                    IconButton(
                      onPressed: () => _controller.redo(),
                      icon: const Icon(Icons.redo, color: AppTheme.textSecondary),
                      tooltip: 'Redo',
                    ),
                    IconButton(
                      onPressed: () => _controller.clear(),
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
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

// Background Dot Matrix
class _DotGridPainter extends CustomPainter {
  final double spacing;
  final Color dotColor;

  _DotGridPainter({this.spacing = 30.0, this.dotColor = const Color(0xFFD1D5DB)});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;
      
    for (double x = spacing; x < size.width; x += spacing) {
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 0.8, paint); 
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Faint mannequin silhouette drawing template
class _MannequinTemplatePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    
    final paintBase = Paint()
      ..color = const Color(0xFFE5E7EB).withOpacity(0.6)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final double startY = 80.0;
    final double height = 500.0;
    
    final headCenter = Offset(w * 0.5, startY + height * 0.15);
    final headRadius = height * 0.055;
    canvas.drawCircle(headCenter, headRadius, paintBase);

    // Neck
    final neckPath = Path()
      ..moveTo(w * 0.47, startY + height * 0.20)
      ..lineTo(w * 0.47, startY + height * 0.24)
      ..lineTo(w * 0.53, startY + height * 0.24)
      ..lineTo(w * 0.53, startY + height * 0.20)
      ..close();
    canvas.drawPath(neckPath, paintBase);

    // Torso
    final torsoPath = Path()
      ..moveTo(w * 0.32, startY + height * 0.25)
      ..quadraticBezierTo(w * 0.5, startY + height * 0.27, w * 0.68, startY + height * 0.25)
      ..quadraticBezierTo(w * 0.68, startY + height * 0.32, w * 0.65, startY + height * 0.45)
      ..lineTo(w * 0.61, startY + height * 0.70)
      ..lineTo(w * 0.39, startY + height * 0.70)
      ..lineTo(w * 0.35, startY + height * 0.45)
      ..quadraticBezierTo(w * 0.32, startY + height * 0.32, w * 0.32, startY + height * 0.25)
      ..close();
    canvas.drawPath(torsoPath, paintBase);

    // Left arm stub
    final leftArmPath = Path()
      ..moveTo(w * 0.32, startY + height * 0.25)
      ..lineTo(w * 0.26, startY + height * 0.55)
      ..lineTo(w * 0.31, startY + height * 0.55)
      ..lineTo(w * 0.35, startY + height * 0.35)
      ..close();
    canvas.drawPath(leftArmPath, paintBase);

    // Right arm stub
    final rightArmPath = Path()
      ..moveTo(w * 0.68, startY + height * 0.25)
      ..lineTo(w * 0.74, startY + height * 0.55)
      ..lineTo(w * 0.69, startY + height * 0.55)
      ..lineTo(w * 0.65, startY + height * 0.35)
      ..close();
    canvas.drawPath(rightArmPath, paintBase);
  }

  @override
  bool shouldRepaint(covariant _MannequinTemplatePainter oldDelegate) => false;
}

// Internal Toolbar Widgets
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
              ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]
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

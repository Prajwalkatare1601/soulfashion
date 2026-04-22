import 'dart:typed_data';
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

  @override
  void initState() {
    super.initState();
    _controller = SignatureController(
      penStrokeWidth: 3.0,
      penColor: Colors.black,
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
        canvas.drawCircle(Offset(x, y), 0.8, paint); // crisp 1.6px dot
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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

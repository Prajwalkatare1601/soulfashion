import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/section_card.dart';

class MeasurementFormScreen extends StatefulWidget {
  final String customerId;
  final Measurement? existingMeasurement;

  const MeasurementFormScreen({
    Key? key,
    required this.customerId,
    this.existingMeasurement,
  }) : super(key: key);

  @override
  State<MeasurementFormScreen> createState() => _MeasurementFormScreenState();
}

class _MeasurementFormScreenState extends State<MeasurementFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _chestController = TextEditingController();
  final _waistController = TextEditingController();
  final _shoulderController = TextEditingController();
  final _sleeveController = TextEditingController();

  final _chestFocusNode = FocusNode();
  final _waistFocusNode = FocusNode();
  final _shoulderFocusNode = FocusNode();
  final _sleeveFocusNode = FocusNode();

  String? _activeField;
  final _service = SupabaseService();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingMeasurement != null) {
      _chestController.text = widget.existingMeasurement!.chest ?? '';
      _waistController.text = widget.existingMeasurement!.waist ?? '';
      _shoulderController.text = widget.existingMeasurement!.shoulder ?? '';
      _sleeveController.text = widget.existingMeasurement!.sleeve ?? '';
    }

    _chestFocusNode.addListener(() {
      if (_chestFocusNode.hasFocus) setState(() => _activeField = 'chest');
    });
    _waistFocusNode.addListener(() {
      if (_waistFocusNode.hasFocus) setState(() => _activeField = 'waist');
    });
    _shoulderFocusNode.addListener(() {
      if (_shoulderFocusNode.hasFocus) setState(() => _activeField = 'shoulder');
    });
    _sleeveFocusNode.addListener(() {
      if (_sleeveFocusNode.hasFocus) setState(() => _activeField = 'sleeve');
    });
  }

  @override
  void dispose() {
    _chestController.dispose();
    _waistController.dispose();
    _shoulderController.dispose();
    _sleeveController.dispose();

    _chestFocusNode.dispose();
    _waistFocusNode.dispose();
    _shoulderFocusNode.dispose();
    _sleeveFocusNode.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final data = {
        'chest': _chestController.text.trim(),
        'waist': _waistController.text.trim(),
        'shoulder': _shoulderController.text.trim(),
        'sleeve': _sleeveController.text.trim(),
      };
      
      await _service.upsertMeasurement(widget.customerId, data);
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Measurements saved successfully')));
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

  void _handleSilhouetteTap(Offset localPosition, Size size) {
    final x = localPosition.dx / size.width;
    final y = localPosition.dy / size.height;

    // Map canvas hot zones to focus node activations
    if (y >= 0.22 && y <= 0.36) {
      _shoulderFocusNode.requestFocus();
    } else if (y > 0.36 && y <= 0.52) {
      if (x < 0.33 || x > 0.67) {
        _sleeveFocusNode.requestFocus();
      } else {
        _chestFocusNode.requestFocus();
      }
    } else if (y > 0.52 && y <= 0.72) {
      if (x < 0.35 || x > 0.65) {
        _sleeveFocusNode.requestFocus();
      } else {
        _waistFocusNode.requestFocus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 700;

    Widget silhouetteWidget = LayoutBuilder(
      builder: (context, constraints) {
        final double canvasWidth = constraints.maxWidth;
        final double canvasHeight = constraints.maxHeight;
        
        return GestureDetector(
          onTapUp: (details) {
            _handleSilhouetteTap(details.localPosition, Size(canvasWidth, canvasHeight));
          },
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: CustomPaint(
              size: Size(canvasWidth, canvasHeight),
              painter: MannequinPainter(activeField: _activeField),
            ),
          ),
        );
      },
    );

    Widget formInputs = Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionCard(
            title: 'Upper Body Measurements',
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildField('Chest', _chestController, _chestFocusNode)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildField('Waist', _waistController, _waistFocusNode)),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildField('Shoulder', _shoulderController, _shoulderFocusNode)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildField('Sleeve', _sleeveController, _sleeveFocusNode)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          CustomButton(
            text: 'Save Measurements',
            isLoading: _isSaving,
            onPressed: _save,
          ),
          const SizedBox(height: 16),
          CustomButton(
            text: 'Cancel',
            isOutlined: true,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingMeasurement == null ? 'Add Measurements' : 'Edit Measurements'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 20, 
                  height: 20, 
                  child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary))
                ),
              ),
            )
        ],
      ),
      body: isWide
          ? Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 4,
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height - 150,
                      child: silhouetteWidget,
                    ),
                  ),
                  const SizedBox(width: 32),
                  Expanded(
                    flex: 5,
                    child: SingleChildScrollView(child: formInputs),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 280,
                    child: silhouetteWidget,
                  ),
                  const SizedBox(height: 24),
                  formInputs,
                ],
              ),
            ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, FocusNode focusNode) {
    return CustomTextField(
      label: label,
      controller: controller,
      focusNode: focusNode,
      suffixText: 'in',
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
    );
  }
}

class MannequinPainter extends CustomPainter {
  final String? activeField;

  MannequinPainter({this.activeField});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final paintBase = Paint()
      ..color = AppTheme.primary.withOpacity(0.04)
      ..style = PaintingStyle.fill;

    final paintBaseOutline = Paint()
      ..color = AppTheme.primary.withOpacity(0.12)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final paintActiveGuide = Paint()
      ..color = const Color(0xFF10B981) // Emerald Teal
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final paintInactiveGuide = Paint()
      ..color = AppTheme.primary.withOpacity(0.3)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final paintActiveDot = Paint()
      ..color = const Color(0xFF10B981) // Emerald Teal
      ..style = PaintingStyle.fill;

    final paintInactiveDot = Paint()
      ..color = AppTheme.primary.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    // Draw Mannequin
    // Head
    final headCenter = Offset(w * 0.5, h * 0.15);
    final headRadius = h * 0.055;
    canvas.drawCircle(headCenter, headRadius, paintBase);
    canvas.drawCircle(headCenter, headRadius, paintBaseOutline);

    // Neck
    final neckPath = Path()
      ..moveTo(w * 0.47, h * 0.20)
      ..lineTo(w * 0.47, h * 0.24)
      ..lineTo(w * 0.53, h * 0.24)
      ..lineTo(w * 0.53, h * 0.20)
      ..close();
    canvas.drawPath(neckPath, paintBase);
    canvas.drawPath(neckPath, paintBaseOutline);

    // Torso (shoulders, chest, waist)
    final torsoPath = Path()
      ..moveTo(w * 0.32, h * 0.25)
      ..quadraticBezierTo(w * 0.5, h * 0.27, w * 0.68, h * 0.25)
      ..quadraticBezierTo(w * 0.68, h * 0.32, w * 0.65, h * 0.45)
      ..lineTo(w * 0.61, h * 0.70)
      ..lineTo(w * 0.39, h * 0.70)
      ..lineTo(w * 0.35, h * 0.45)
      ..quadraticBezierTo(w * 0.32, h * 0.32, w * 0.32, h * 0.25)
      ..close();
    
    canvas.drawPath(torsoPath, paintBase);
    canvas.drawPath(torsoPath, paintBaseOutline);

    // Left arm stub
    final leftArmPath = Path()
      ..moveTo(w * 0.32, h * 0.25)
      ..lineTo(w * 0.26, h * 0.55)
      ..lineTo(w * 0.31, h * 0.55)
      ..lineTo(w * 0.35, h * 0.35)
      ..close();
    canvas.drawPath(leftArmPath, paintBase);
    canvas.drawPath(leftArmPath, paintBaseOutline);

    // Right arm stub
    final rightArmPath = Path()
      ..moveTo(w * 0.68, h * 0.25)
      ..lineTo(w * 0.74, h * 0.55)
      ..lineTo(w * 0.69, h * 0.55)
      ..lineTo(w * 0.65, h * 0.35)
      ..close();
    canvas.drawPath(rightArmPath, paintBase);
    canvas.drawPath(rightArmPath, paintBaseOutline);

    // Draw Guides
    // 1. Shoulder Guide
    final shoulderStart = Offset(w * 0.32, h * 0.25);
    final shoulderEnd = Offset(w * 0.68, h * 0.25);
    final isShoulderActive = activeField == 'shoulder';
    canvas.drawLine(shoulderStart, shoulderEnd, isShoulderActive ? paintActiveGuide : paintInactiveGuide);
    canvas.drawCircle(shoulderStart, isShoulderActive ? 5 : 3.5, isShoulderActive ? paintActiveDot : paintInactiveDot);
    canvas.drawCircle(shoulderEnd, isShoulderActive ? 5 : 3.5, isShoulderActive ? paintActiveDot : paintInactiveDot);

    // 2. Chest Guide
    final chestStart = Offset(w * 0.34, h * 0.43);
    final chestEnd = Offset(w * 0.66, h * 0.43);
    final isChestActive = activeField == 'chest';
    canvas.drawLine(chestStart, chestEnd, isChestActive ? paintActiveGuide : paintInactiveGuide);
    canvas.drawCircle(chestStart, isChestActive ? 5 : 3.5, isChestActive ? paintActiveDot : paintInactiveDot);
    canvas.drawCircle(chestEnd, isChestActive ? 5 : 3.5, isChestActive ? paintActiveDot : paintInactiveDot);

    // 3. Waist Guide
    final waistStart = Offset(w * 0.39, h * 0.70);
    final waistEnd = Offset(w * 0.61, h * 0.70);
    final isWaistActive = activeField == 'waist';
    canvas.drawLine(waistStart, waistEnd, isWaistActive ? paintActiveGuide : paintInactiveGuide);
    canvas.drawCircle(waistStart, isWaistActive ? 5 : 3.5, isWaistActive ? paintActiveDot : paintInactiveDot);
    canvas.drawCircle(waistEnd, isWaistActive ? 5 : 3.5, isWaistActive ? paintActiveDot : paintInactiveDot);

    // 4. Sleeve Guide
    final sleeveStart = Offset(w * 0.68, h * 0.25);
    final sleeveEnd = Offset(w * 0.74, h * 0.55);
    final isSleeveActive = activeField == 'sleeve';
    canvas.drawLine(sleeveStart, sleeveEnd, isSleeveActive ? paintActiveGuide : paintInactiveGuide);
    canvas.drawCircle(sleeveStart, isSleeveActive ? 5 : 3.5, isSleeveActive ? paintActiveDot : paintInactiveDot);
    canvas.drawCircle(sleeveEnd, isSleeveActive ? 5 : 3.5, isSleeveActive ? paintActiveDot : paintInactiveDot);
  }

  @override
  bool shouldRepaint(covariant MannequinPainter oldDelegate) {
    return oldDelegate.activeField != activeField;
  }
}

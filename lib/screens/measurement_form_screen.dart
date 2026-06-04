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
  
  // Upper body controllers & focus nodes
  final _chestController = TextEditingController();
  final _waistController = TextEditingController();
  final _shoulderController = TextEditingController();
  final _sleeveController = TextEditingController();

  final _chestFocusNode = FocusNode();
  final _waistFocusNode = FocusNode();
  final _shoulderFocusNode = FocusNode();
  final _sleeveFocusNode = FocusNode();

  // Bottom body controllers & focus nodes
  final _hipsController = TextEditingController();
  final _thighController = TextEditingController();
  final _inseamController = TextEditingController();
  final _lengthController = TextEditingController();

  final _hipsFocusNode = FocusNode();
  final _thighFocusNode = FocusNode();
  final _inseamFocusNode = FocusNode();
  final _lengthFocusNode = FocusNode();

  bool _isUpperBody = true;
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
      
      _hipsController.text = widget.existingMeasurement!.hips ?? '';
      _thighController.text = widget.existingMeasurement!.thigh ?? '';
      _inseamController.text = widget.existingMeasurement!.inseam ?? '';
      _lengthController.text = widget.existingMeasurement!.length ?? '';
    }

    // Upper body focus listeners
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

    // Bottom body focus listeners
    _hipsFocusNode.addListener(() {
      if (_hipsFocusNode.hasFocus) setState(() => _activeField = 'hips');
    });
    _thighFocusNode.addListener(() {
      if (_thighFocusNode.hasFocus) setState(() => _activeField = 'thigh');
    });
    _inseamFocusNode.addListener(() {
      if (_inseamFocusNode.hasFocus) setState(() => _activeField = 'inseam');
    });
    _lengthFocusNode.addListener(() {
      if (_lengthFocusNode.hasFocus) setState(() => _activeField = 'length');
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

    _hipsController.dispose();
    _thighController.dispose();
    _inseamController.dispose();
    _lengthController.dispose();

    _hipsFocusNode.dispose();
    _thighFocusNode.dispose();
    _inseamFocusNode.dispose();
    _lengthFocusNode.dispose();
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
        'hips': _hipsController.text.trim(),
        'thigh': _thighController.text.trim(),
        'inseam': _inseamController.text.trim(),
        'length': _lengthController.text.trim(),
      };
      
      await _service.upsertMeasurement(widget.customerId, data);
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Measurements saved successfully')));
      }
    } catch (e) {
      if (mounted) {
        final errorMsg = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(errorMsg),
          duration: const Duration(seconds: 8),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {
              if (mounted) Navigator.pop(context);
            },
          ),
        ));
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

    if (_isUpperBody) {
      // Map canvas upper zones to focus nodes
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
    } else {
      // Map canvas lower zones to focus nodes
      if (y >= 0.12 && y <= 0.32) {
        _hipsFocusNode.requestFocus();
      } else if (y > 0.32 && y <= 0.52) {
        _thighFocusNode.requestFocus();
      } else if (y > 0.52 && y <= 0.88) {
        if (x >= 0.55) {
          _lengthFocusNode.requestFocus();
        } else {
          _inseamFocusNode.requestFocus();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 700;

    Widget toggleBar = Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _isUpperBody = true;
                _activeField = null;
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _isUpperBody ? AppTheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'Upper Body',
                    style: TextStyle(
                      color: _isUpperBody ? Colors.white : AppTheme.textSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _isUpperBody = false;
                _activeField = null;
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: !_isUpperBody ? AppTheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'Bottom Body',
                    style: TextStyle(
                      color: !_isUpperBody ? Colors.white : AppTheme.textSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

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
              painter: MannequinPainter(
                activeField: _activeField, 
                isUpperBody: _isUpperBody,
              ),
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
            title: _isUpperBody ? 'Upper Body Details' : 'Bottom Body Details',
            child: _isUpperBody
                ? Column(
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
                  )
                : Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildField('Hips', _hipsController, _hipsFocusNode)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildField('Thigh', _thighController, _thighFocusNode)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildField('Inseam', _inseamController, _inseamFocusNode)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildField('Length', _lengthController, _lengthFocusNode)),
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
                    child: Column(
                      children: [
                        toggleBar,
                        const SizedBox(height: 16),
                        Expanded(
                          child: silhouetteWidget,
                        ),
                      ],
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
                  toggleBar,
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 300,
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
  final bool isUpperBody;

  MannequinPainter({this.activeField, this.isUpperBody = true});

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

    if (isUpperBody) {
      // Draw Upper Body Mannequin
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

      // Torso
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

      // Draw Upper Body Guides
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
    } else {
      // Draw Bottom Body Mannequin (Waist, Hips, Legs)
      final bottomPath = Path()
        ..moveTo(w * 0.39, h * 0.12)
        ..lineTo(w * 0.61, h * 0.12) // waist top
        ..quadraticBezierTo(w * 0.67, h * 0.18, w * 0.67, h * 0.28) // right hip
        ..lineTo(w * 0.64, h * 0.85) // right outer leg
        ..lineTo(w * 0.56, h * 0.85) // right cuff
        ..lineTo(w * 0.5, h * 0.35) // right inner leg to crotch
        ..lineTo(w * 0.44, h * 0.85) // left inner leg from crotch
        ..lineTo(w * 0.36, h * 0.85) // left cuff
        ..lineTo(w * 0.33, h * 0.28) // left outer leg
        ..quadraticBezierTo(w * 0.33, h * 0.18, w * 0.39, h * 0.12) // left hip
        ..close();
      canvas.drawPath(bottomPath, paintBase);
      canvas.drawPath(bottomPath, paintBaseOutline);

      // Draw Bottom Body Guides
      // 1. Hips Guide
      final hipsStart = Offset(w * 0.33, h * 0.28);
      final hipsEnd = Offset(w * 0.67, h * 0.28);
      final isHipsActive = activeField == 'hips';
      canvas.drawLine(hipsStart, hipsEnd, isHipsActive ? paintActiveGuide : paintInactiveGuide);
      canvas.drawCircle(hipsStart, isHipsActive ? 5 : 3.5, isHipsActive ? paintActiveDot : paintInactiveDot);
      canvas.drawCircle(hipsEnd, isHipsActive ? 5 : 3.5, isHipsActive ? paintActiveDot : paintInactiveDot);

      // 2. Thigh Guide
      final thighStart = Offset(w * 0.51, h * 0.45);
      final thighEnd = Offset(w * 0.66, h * 0.45);
      final isThighActive = activeField == 'thigh';
      canvas.drawLine(thighStart, thighEnd, isThighActive ? paintActiveGuide : paintInactiveGuide);
      canvas.drawCircle(thighStart, isThighActive ? 5 : 3.5, isThighActive ? paintActiveDot : paintInactiveDot);
      canvas.drawCircle(thighEnd, isThighActive ? 5 : 3.5, isThighActive ? paintActiveDot : paintInactiveDot);

      // 3. Inseam Guide
      final inseamStart = Offset(w * 0.50, h * 0.35);
      final inseamEnd = Offset(w * 0.56, h * 0.85);
      final isInseamActive = activeField == 'inseam';
      canvas.drawLine(inseamStart, inseamEnd, isInseamActive ? paintActiveGuide : paintInactiveGuide);
      canvas.drawCircle(inseamStart, isInseamActive ? 5 : 3.5, isInseamActive ? paintActiveDot : paintInactiveDot);
      canvas.drawCircle(inseamEnd, isInseamActive ? 5 : 3.5, isInseamActive ? paintActiveDot : paintInactiveDot);

      // 4. Length Guide
      final lengthStart = Offset(w * 0.61, h * 0.12);
      final lengthEnd = Offset(w * 0.64, h * 0.85);
      final isLengthActive = activeField == 'length';
      canvas.drawLine(lengthStart, lengthEnd, isLengthActive ? paintActiveGuide : paintInactiveGuide);
      canvas.drawCircle(lengthStart, isLengthActive ? 5 : 3.5, isLengthActive ? paintActiveDot : paintInactiveDot);
      canvas.drawCircle(lengthEnd, isLengthActive ? 5 : 3.5, isLengthActive ? paintActiveDot : paintInactiveDot);
    }
  }

  @override
  bool shouldRepaint(covariant MannequinPainter oldDelegate) {
    return oldDelegate.activeField != activeField || oldDelegate.isUpperBody != isUpperBody;
  }
}

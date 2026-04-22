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
  }

  @override
  void dispose() {
    _chestController.dispose();
    _waistController.dispose();
    _shoulderController.dispose();
    _sleeveController.dispose();
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

  @override
  Widget build(BuildContext context) {
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Form(
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
                        Expanded(child: _buildField('Chest', _chestController)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildField('Waist', _waistController)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildField('Shoulder', _shoulderController)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildField('Sleeve', _sleeveController)),
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
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller) {
    return CustomTextField(
      label: label,
      controller: controller,
      suffixText: 'in',
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
    );
  }
}

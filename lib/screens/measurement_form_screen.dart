import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/section_card.dart';

enum BodyTab { upper, bottom, full }

class CustomField {
  final String key;
  final String label;
  final String tab;

  CustomField({required this.key, required this.label, required this.tab});
}

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
  final _service = SupabaseService();
  bool _isSaving = false;
  BodyTab _activeTab = BodyTab.upper;

  // Upper body controllers
  final _upperLengthController = TextEditingController();
  final _chestController = TextEditingController();
  final _upperChestController = TextEditingController();
  final _pointController = TextEditingController();
  final _upperWaistController = TextEditingController();
  final _sleeveController = TextEditingController();
  final _shoulderController = TextEditingController();
  final _slitController = TextEditingController();
  final _upperHipController = TextEditingController();
  final _lowerHipController = TextEditingController();
  final _frontNeckController = TextEditingController();
  final _backNeckController = TextEditingController();
  final _backBoardController = TextEditingController();
  final _armController = TextEditingController();
  final _sideController = TextEditingController();

  final _upperLengthFocusNode = FocusNode();
  final _chestFocusNode = FocusNode();
  final _upperChestFocusNode = FocusNode();
  final _pointFocusNode = FocusNode();
  final _upperWaistFocusNode = FocusNode();
  final _sleeveFocusNode = FocusNode();
  final _shoulderFocusNode = FocusNode();
  final _slitFocusNode = FocusNode();
  final _upperHipFocusNode = FocusNode();
  final _lowerHipFocusNode = FocusNode();
  final _frontNeckFocusNode = FocusNode();
  final _backNeckFocusNode = FocusNode();
  final _backBoardFocusNode = FocusNode();
  final _armFocusNode = FocusNode();
  final _sideFocusNode = FocusNode();

  // Bottom body controllers
  final _lowerLengthController = TextEditingController();
  final _lowerWaistController = TextEditingController();
  final _bottomHipController = TextEditingController();
  final _thighController = TextEditingController();
  final _kneeController = TextEditingController();
  final _crotchController = TextEditingController();
  final _bottomController = TextEditingController();

  final _lowerLengthFocusNode = FocusNode();
  final _lowerWaistFocusNode = FocusNode();
  final _bottomHipFocusNode = FocusNode();
  final _thighFocusNode = FocusNode();
  final _kneeFocusNode = FocusNode();
  final _crotchFocusNode = FocusNode();
  final _bottomFocusNode = FocusNode();

  // Full body controllers
  final _fullLengthController = TextEditingController();
  final _yokeController = TextEditingController();

  final _fullLengthFocusNode = FocusNode();
  final _yokeFocusNode = FocusNode();

  final List<CustomField> _customFields = [];
  final Map<String, TextEditingController> _customControllers = {};
  final Map<String, FocusNode> _customFocusNodes = {};

  @override
  void initState() {
    super.initState();
    if (widget.existingMeasurement != null) {
      final m = widget.existingMeasurement!;
      // Upper body
      _upperLengthController.text = m.upperLength ?? '';
      _chestController.text = m.chest ?? '';
      _upperChestController.text = m.upperChest ?? '';
      _pointController.text = m.point ?? '';
      _upperWaistController.text = m.upperWaist ?? m.waist ?? '';
      _sleeveController.text = m.sleeve ?? '';
      _shoulderController.text = m.shoulder ?? '';
      _slitController.text = m.slit ?? '';
      _upperHipController.text = m.upperHip ?? '';
      _lowerHipController.text = m.lowerHip ?? '';
      _frontNeckController.text = m.frontNeck ?? '';
      _backNeckController.text = m.backNeck ?? '';
      _backBoardController.text = m.backBoard ?? '';
      _armController.text = m.arm ?? '';
      _sideController.text = m.side ?? '';

      // Bottom body
      _lowerLengthController.text = m.lowerLength ?? m.length ?? '';
      _lowerWaistController.text = m.lowerWaist ?? '';
      _bottomHipController.text = m.bottomHip ?? '';
      _thighController.text = m.thigh ?? '';
      _kneeController.text = m.knee ?? '';
      _crotchController.text = m.crotch ?? '';
      _bottomController.text = m.bottom ?? '';

      // Full body
      _fullLengthController.text = m.fullLength ?? '';
      _yokeController.text = m.yoke ?? '';

      // Custom values
      if (m.customValues.isNotEmpty) {
        m.customValues.forEach((key, value) {
          final parts = key.split('_');
          if (parts.length >= 2) {
            final tab = parts[0];
            final label = parts.sublist(1).join('_');

            final field = CustomField(key: key, label: label, tab: tab);
            _customFields.add(field);
            _customControllers[key] = TextEditingController(text: value.toString());
            _customFocusNodes[key] = FocusNode();
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _upperLengthController.dispose();
    _chestController.dispose();
    _upperChestController.dispose();
    _pointController.dispose();
    _upperWaistController.dispose();
    _sleeveController.dispose();
    _shoulderController.dispose();
    _slitController.dispose();
    _upperHipController.dispose();
    _lowerHipController.dispose();
    _frontNeckController.dispose();
    _backNeckController.dispose();
    _backBoardController.dispose();
    _armController.dispose();
    _sideController.dispose();

    _upperLengthFocusNode.dispose();
    _chestFocusNode.dispose();
    _upperChestFocusNode.dispose();
    _pointFocusNode.dispose();
    _upperWaistFocusNode.dispose();
    _sleeveFocusNode.dispose();
    _shoulderFocusNode.dispose();
    _slitFocusNode.dispose();
    _upperHipFocusNode.dispose();
    _lowerHipFocusNode.dispose();
    _frontNeckFocusNode.dispose();
    _backNeckFocusNode.dispose();
    _backBoardFocusNode.dispose();
    _armFocusNode.dispose();
    _sideFocusNode.dispose();

    _lowerLengthController.dispose();
    _lowerWaistController.dispose();
    _bottomHipController.dispose();
    _thighController.dispose();
    _kneeController.dispose();
    _crotchController.dispose();
    _bottomController.dispose();

    _lowerLengthFocusNode.dispose();
    _lowerWaistFocusNode.dispose();
    _bottomHipFocusNode.dispose();
    _thighFocusNode.dispose();
    _kneeFocusNode.dispose();
    _crotchFocusNode.dispose();
    _bottomFocusNode.dispose();

    _fullLengthController.dispose();
    _yokeController.dispose();

    _fullLengthFocusNode.dispose();
    _yokeFocusNode.dispose();

    _customControllers.forEach((_, c) => c.dispose());
    _customFocusNodes.forEach((_, f) => f.dispose());

    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final customValuesMap = <String, String>{};
      for (final field in _customFields) {
        final val = _customControllers[field.key]!.text.trim();
        if (val.isNotEmpty) {
          customValuesMap[field.key] = val;
        }
      }

      final data = {
        // Upper body
        'upper_length': _upperLengthController.text.trim(),
        'chest': _chestController.text.trim(),
        'upper_chest': _upperChestController.text.trim(),
        'point': _pointController.text.trim(),
        'upper_waist': _upperWaistController.text.trim(),
        'sleeve': _sleeveController.text.trim(),
        'shoulder': _shoulderController.text.trim(),
        'slit': _slitController.text.trim(),
        'upper_hip': _upperHipController.text.trim(),
        'lower_hip': _lowerHipController.text.trim(),
        'front_neck': _frontNeckController.text.trim(),
        'back_neck': _backNeckController.text.trim(),
        'back_board': _backBoardController.text.trim(),
        'arm': _armController.text.trim(),
        'side': _sideController.text.trim(),

        // Bottom body
        'lower_length': _lowerLengthController.text.trim(),
        'lower_waist': _lowerWaistController.text.trim(),
        'bottom_hip': _bottomHipController.text.trim(),
        'thigh': _thighController.text.trim(),
        'knee': _kneeController.text.trim(),
        'crotch': _crotchController.text.trim(),
        'bottom': _bottomController.text.trim(),

        // Full body
        'full_length': _fullLengthController.text.trim(),
        'yoke': _yokeController.text.trim(),

        // Legacy values for compatibility
        'waist': _upperWaistController.text.trim(),
        'length': _upperLengthController.text.trim().isNotEmpty
            ? _upperLengthController.text.trim()
            : _lowerLengthController.text.trim(),

        'custom_values': customValuesMap,
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
            onPressed: () {},
          ),
        ));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Widget _buildCustomFields(String tabStr) {
    final fields = _customFields.where((f) => f.tab == tabStr).toList();
    if (fields.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        const Divider(color: Color(0xFFF1F5F9), height: 24),
        ...fields.map((field) => _buildCustomFieldRow(field)),
      ],
    );
  }

  Widget _buildCustomFieldRow(CustomField field) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              field.label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 140,
                child: TextFormField(
                  controller: _customControllers[field.key]!,
                  focusNode: _customFocusNodes[field.key]!,
                  keyboardType: TextInputType.text,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    suffixText: 'in',
                    suffixStyle: const TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    fillColor: Colors.white,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                onPressed: () {
                  setState(() {
                    _customFields.remove(field);
                    _customControllers.remove(field.key)?.dispose();
                    _customFocusNodes.remove(field.key)?.dispose();
                  });
                },
                tooltip: 'Remove field',
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddCustomFieldDialog() {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Custom Measurement'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Measurement Name',
            hintText: 'e.g., Arm Hole, Wrist, Ankle',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                final tabStr = _activeTab.name;
                final key = '${tabStr}_$name';

                if (!_customControllers.containsKey(key)) {
                  setState(() {
                    final newField = CustomField(key: key, label: name, tab: tabStr);
                    _customFields.add(newField);
                    _customControllers[key] = TextEditingController();
                    _customFocusNodes[key] = FocusNode();
                  });
                }
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget toggleBar = Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _activeTab = BodyTab.upper;
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _activeTab == BodyTab.upper ? AppTheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'Upper Body',
                    style: TextStyle(
                      color: _activeTab == BodyTab.upper ? Colors.white : AppTheme.textSecondary,
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
                _activeTab = BodyTab.bottom;
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _activeTab == BodyTab.bottom ? AppTheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'Bottom Body',
                    style: TextStyle(
                      color: _activeTab == BodyTab.bottom ? Colors.white : AppTheme.textSecondary,
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
                _activeTab = BodyTab.full;
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _activeTab == BodyTab.full ? AppTheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    'Full Body',
                    style: TextStyle(
                      color: _activeTab == BodyTab.full ? Colors.white : AppTheme.textSecondary,
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

    Widget formInputs = Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionCard(
            title: _activeTab == BodyTab.upper
                ? 'Upper Body Details'
                : _activeTab == BodyTab.bottom
                    ? 'Bottom Body Details'
                    : 'Full Body Details',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_activeTab == BodyTab.upper) ...[
                  _buildField('Length', _upperLengthController, _upperLengthFocusNode),
                  _buildField('Chest', _chestController, _chestFocusNode),
                  _buildField('Upper chest', _upperChestController, _upperChestFocusNode),
                  _buildField('Point', _pointController, _pointFocusNode),
                  _buildField('Waist', _upperWaistController, _upperWaistFocusNode),
                  _buildField('Sleeve', _sleeveController, _sleeveFocusNode),
                  _buildField('Shoulder', _shoulderController, _shoulderFocusNode),
                  _buildField('Slit', _slitController, _slitFocusNode),
                  _buildField('Hip', _upperHipController, _upperHipFocusNode),
                  _buildField('Lower hip', _lowerHipController, _lowerHipFocusNode),
                  _buildField('Front neck', _frontNeckController, _frontNeckFocusNode),
                  _buildField('Back neck', _backNeckController, _backNeckFocusNode),
                  _buildField('Back board', _backBoardController, _backBoardFocusNode),
                  _buildField('Arm', _armController, _armFocusNode),
                  _buildField('Side', _sideController, _sideFocusNode),
                ] else if (_activeTab == BodyTab.bottom) ...[
                  _buildField('Length', _lowerLengthController, _lowerLengthFocusNode),
                  _buildField('Waist', _lowerWaistController, _lowerWaistFocusNode),
                  _buildField('Hip', _bottomHipController, _bottomHipFocusNode),
                  _buildField('Tigh', _thighController, _thighFocusNode),
                  _buildField('Knee', _kneeController, _kneeFocusNode),
                  _buildField('Crotch', _crotchController, _crotchFocusNode),
                  _buildField('Buttom', _bottomController, _bottomFocusNode),
                ] else if (_activeTab == BodyTab.full) ...[
                  _buildField('Length', _fullLengthController, _fullLengthFocusNode),
                  _buildField('Yoke', _yokeController, _yokeFocusNode),
                ],

                _buildCustomFields(_activeTab.name),

                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _showAddCustomFieldDialog,
                  icon: const Icon(Icons.add, size: 18, color: AppTheme.primary),
                  label: const Text('Add Custom Field', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Align(
          alignment: Alignment.topCenter,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                toggleBar,
                const SizedBox(height: 24),
                formInputs,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, FocusNode focusNode) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 140,
            child: TextFormField(
              controller: controller,
              focusNode: focusNode,
              keyboardType: TextInputType.text,
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                suffixText: 'in',
                suffixStyle: const TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                fillColor: Colors.white,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

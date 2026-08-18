import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/section_card.dart';
import 'measurement_form_screen.dart';

class MeasurementsViewScreen extends StatefulWidget {
  final String customerId;
  final String customerName;

  const MeasurementsViewScreen({
    Key? key,
    required this.customerId,
    required this.customerName,
  }) : super(key: key);

  @override
  State<MeasurementsViewScreen> createState() => _MeasurementsViewScreenState();
}

class _MeasurementsViewScreenState extends State<MeasurementsViewScreen> {
  final SupabaseService _service = SupabaseService();
  bool _isLoading = true;
  Measurement? _measurement;

  @override
  void initState() {
    super.initState();
    _fetchMeasurements();
  }

  Future<void> _fetchMeasurements() async {
    setState(() => _isLoading = true);
    try {
      final m = await _service.getMeasurement(widget.customerId);
      if (mounted) {
        setState(() {
          _measurement = m;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToEdit() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MeasurementFormScreen(
          customerId: widget.customerId,
          existingMeasurement: _measurement,
        ),
      ),
    );
    _fetchMeasurements(); // Refresh when returning
  }

  @override
  Widget build(BuildContext context) {
    Widget body;

    if (_isLoading) {
      body = const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
        ),
      );
    } else if (_measurement == null) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.straighten_rounded,
                  size: 64,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'No Measurements Recorded',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add measurements to construct a fit profile for ${widget.customerName}.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
              CustomButton(
                text: 'Add Measurements Now',
                onPressed: _navigateToEdit,
              ),
            ],
          ),
        ),
      );
    } else {
      final m = _measurement!;
      body = SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Align(
          alignment: Alignment.topCenter,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Info Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.account_circle_outlined, color: AppTheme.primary, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Fit Profile: ${widget.customerName}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Upper Body Section
                SectionCard(
                  title: 'Upper Body Spec Sheet',
                  child: Column(
                    children: [
                      _buildRow('Length', m.upperLength),
                      _buildRow('Chest', m.chest),
                      _buildRow('Upper chest', m.upperChest),
                      _buildRow('Point', m.point),
                      _buildRow('Waist', m.upperWaist ?? m.waist),
                      _buildRow('Sleeve', m.sleeve),
                      _buildRow('Shoulder', m.shoulder),
                      _buildRow('Slit', m.slit),
                      _buildRow('Hip', m.upperHip),
                      _buildRow('Lower hip', m.lowerHip),
                      _buildRow('Front neck', m.frontNeck),
                      _buildRow('Back neck', m.backNeck),
                      _buildRow('Back board', m.backBoard),
                      _buildRow('Arm', m.arm),
                      _buildRow('Side', m.side),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Bottom Body Section
                SectionCard(
                  title: 'Bottom Body Spec Sheet',
                  child: Column(
                    children: [
                      _buildRow('Length', m.lowerLength ?? m.length),
                      _buildRow('Waist', m.lowerWaist),
                      _buildRow('Hip', m.bottomHip),
                      _buildRow('Tigh', m.thigh),
                      _buildRow('Knee', m.knee),
                      _buildRow('Crotch', m.crotch),
                      _buildRow('Buttom', m.bottom),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Full Body Section
                SectionCard(
                  title: 'Full Body Spec Sheet',
                  child: Column(
                    children: [
                      _buildRow('Length', m.fullLength),
                      _buildRow('Yoke', m.yoke),
                    ],
                  ),
                ),

                // Custom values section (only if populated)
                if (m.customValues.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  SectionCard(
                    title: 'Additional Custom Specs',
                    child: Column(
                      children: m.customValues.entries.map((entry) {
                        final parts = entry.key.split('_');
                        final label = parts.length >= 2 ? parts.sublist(1).join('_') : entry.key;
                        return _buildRow(label, entry.value?.toString());
                      }).toList(),
                    ),
                  ),
                ],
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spec Profile'),
        actions: [
          if (_measurement != null && !_isLoading)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: _navigateToEdit,
              tooltip: 'Edit Measurements',
            ),
        ],
      ),
      body: body,
    );
  }

  Widget _buildRow(String label, String? value) {
    final hasValue = value != null && value.trim().isNotEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: hasValue ? AppTheme.textPrimary : AppTheme.textSecondary.withValues(alpha: 0.6),
            ),
          ),
          Text(
            hasValue ? '$value in' : '—',
            style: TextStyle(
              fontSize: 14,
              fontWeight: hasValue ? FontWeight.bold : FontWeight.normal,
              color: hasValue ? AppTheme.primary : AppTheme.textSecondary.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}

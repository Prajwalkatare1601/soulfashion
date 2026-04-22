import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/section_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/custom_button.dart';
import 'measurement_form_screen.dart';
import 'scribble_screen.dart';
import 'fullscreen_image_screen.dart';

class CustomerDetailScreen extends StatefulWidget {
  final Customer customer;

  const CustomerDetailScreen({Key? key, required this.customer}) : super(key: key);

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  final SupabaseService _service = SupabaseService();
  Measurement? _measurement;
  List<Scribble> _scribbles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final m = await _service.getMeasurement(widget.customer.id);
      final s = await _service.getScribbles(widget.customer.id);
      setState(() {
        _measurement = m;
        _scribbles = s;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.customer.name),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileSection(context),
                  const SizedBox(height: 32),
                  _buildMeasurementSection(context),
                  const SizedBox(height: 32),
                  _buildScribblesSection(context),
                  const SizedBox(height: 60), // padding at bottom
                ],
              ),
            ),
    );
  }

  Widget _buildProfileSection(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(24), // Large squircle
            image: widget.customer.photoUrl != null
                ? DecorationImage(
                    image: NetworkImage(widget.customer.photoUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          alignment: Alignment.center,
          child: widget.customer.photoUrl == null
              ? Text(
                  widget.customer.name.characters.first.toUpperCase(),
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.customer.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.phone_outlined, size: 18, color: AppTheme.textSecondary),
                  const SizedBox(width: 8),
                  Text(
                    widget.customer.phone ?? 'No phone number provided',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 16),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMeasurementSection(BuildContext context) {
    return SectionCard(
      title: 'Measurements',
      trailing: IconButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MeasurementFormScreen(
                customerId: widget.customer.id,
                existingMeasurement: _measurement,
              ),
            ),
          );
          _fetchData(); // Reload after edit
        },
        icon: Icon(_measurement == null ? Icons.add_circle_outline : Icons.edit_outlined),
        color: AppTheme.primary,
        tooltip: _measurement == null ? 'Add Measurements' : 'Edit Measurements',
      ),
      child: _measurement == null
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  const Icon(Icons.straighten, size: 48, color: Color(0xFFE3E8EE)),
                  const SizedBox(height: 16),
                  const Text('No measurements recorded yet.', style: TextStyle(color: AppTheme.textSecondary)),
                  const SizedBox(height: 16),
                  CustomButton(
                    text: 'Add Measurements',
                    isOutlined: true,
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MeasurementFormScreen(
                            customerId: widget.customer.id,
                            existingMeasurement: _measurement,
                          ),
                        ),
                      );
                      _fetchData(); // Reload after edit
                    },
                  ),
                ],
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _MeasurementValue(label: 'Chest', value: _measurement!.chest),
                _MeasurementValue(label: 'Waist', value: _measurement!.waist),
                _MeasurementValue(label: 'Shoulder', value: _measurement!.shoulder),
                _MeasurementValue(label: 'Sleeve', value: _measurement!.sleeve),
              ],
            ),
    );
  }

  Widget _buildScribblesSection(BuildContext context) {
    return SectionCard(
      title: 'Digital Notes',
      trailing: IconButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ScribbleScreen(customerId: widget.customer.id),
            ),
          );
          _fetchData(); // Reload after new scribble
        },
        icon: const Icon(Icons.draw_outlined),
        color: AppTheme.primary,
        tooltip: 'Add Digital Note',
      ),
      child: _scribbles.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No digital notes saved yet.',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ),
            )
          : Wrap(
              spacing: 16,
              runSpacing: 16,
              children: _scribbles.map((scribble) {
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FullscreenImageScreen(imageUrl: scribble.imageUrl),
                      ),
                    );
                  },
                  child: SizedBox(
                    width: 130,
                    height: 160,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE3E8EE)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: Container(
                                color: Colors.white,
                                padding: const EdgeInsets.all(8),
                                child: Stack(
                                  children: [
                                    Center(
                                      child: Image.network(
                                        scribble.imageUrl,
                                        fit: BoxFit.contain,
                                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.grey),
                                      ),
                                    ),
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primary.withOpacity(0.08),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.open_in_full, size: 14, color: AppTheme.primary),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Container(
                              color: const Color(0xFFF1F3F5),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Digital Note',
                                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppTheme.textPrimary),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${scribble.createdAt.day}/${scribble.createdAt.month}/${scribble.createdAt.year}',
                                    style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }
}

class _MeasurementValue extends StatelessWidget {
  final String label;
  final String? value;

  const _MeasurementValue({required this.label, this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value?.isNotEmpty == true ? value! : '-',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}

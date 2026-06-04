import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../models/models.dart';
import '../providers/customer_provider.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/section_card.dart';
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
  List<ReferencePhoto> _referencePhotos = [];
  bool _isLoading = true;
  late OrderStatus _currentStatus;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.customer.orderStatus;
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final m = await _service.getMeasurement(widget.customer.id);
      final s = await _service.getScribbles(widget.customer.id);
      final r = await _service.getReferencePhotos(widget.customer.id);
      setState(() {
        _measurement = m;
        _scribbles = s;
        _referencePhotos = r;
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
                  const SizedBox(height: 32),
                  _buildReferencePhotosSection(context),
                  const SizedBox(height: 32),
                  _buildOrderStatusSection(context),
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
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 16, color: AppTheme.textSecondary),
                  const SizedBox(width: 8),
                  Text(
                    'Member since ${_formatDate(widget.customer.createdAt)}',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]}, ${date.year}';
  }

  // --- Order Status Colors & Icons (matching home screen) ---
  Color _statusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.ordered:
        return const Color(0xFFF59E0B);
      case OrderStatus.completed:
        return const Color(0xFF3B82F6);
      case OrderStatus.delivered:
        return const Color(0xFF10B981);
    }
  }

  IconData _statusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.ordered:
        return Icons.receipt_long_outlined;
      case OrderStatus.completed:
        return Icons.check_circle_outline;
      case OrderStatus.delivered:
        return Icons.local_shipping_outlined;
    }
  }

  Future<void> _updateStatus(OrderStatus newStatus) async {
    final oldStatus = _currentStatus;
    setState(() => _currentStatus = newStatus);
    try {
      final provider = Provider.of<CustomerProvider>(context, listen: false);
      await provider.updateOrderStatus(widget.customer.id, newStatus);
    } catch (e) {
      // Revert on failure
      setState(() => _currentStatus = oldStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e')),
        );
      }
    }
  }

  Widget _buildOrderStatusSection(BuildContext context) {
    final stages = OrderStatus.values;
    final currentIndex = stages.indexOf(_currentStatus);

    return SectionCard(
      title: 'Order Pipeline',
      trailing: const SizedBox.shrink(),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: List.generate(stages.length * 2 - 1, (i) {
            // Even indices = stage nodes, odd indices = connector lines
            if (i.isOdd) {
              final leftStageIndex = i ~/ 2;
              final isPast = leftStageIndex < currentIndex;
              return Expanded(
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: isPast
                        ? _statusColor(stages[leftStageIndex + 1])
                        : const Color(0xFFE3E8EE),
                  ),
                ),
              );
            }

            final stageIndex = i ~/ 2;
            final stage = stages[stageIndex];
            final isActive = stageIndex == currentIndex;
            final isPast = stageIndex < currentIndex;
            final color = _statusColor(stage);

            return GestureDetector(
              onTap: () => _updateStatus(stage),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Circle icon
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: isActive ? 52 : 42,
                      height: isActive ? 52 : 42,
                      decoration: BoxDecoration(
                        color: (isActive || isPast)
                            ? color.withOpacity(isActive ? 0.15 : 0.08)
                            : const Color(0xFFF1F3F5),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: (isActive || isPast) ? color : const Color(0xFFE3E8EE),
                          width: isActive ? 2.5 : 1.5,
                        ),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: color.withOpacity(0.25),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : [],
                      ),
                      child: Icon(
                        isPast ? Icons.check_rounded : _statusIcon(stage),
                        size: isActive ? 24 : 20,
                        color: (isActive || isPast) ? color : const Color(0xFFBCC3CE),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Label
                    Text(
                      stage.label,
                      style: TextStyle(
                        fontSize: isActive ? 13 : 11,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                        color: isActive ? color : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
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

  Widget _buildReferencePhotosSection(BuildContext context) {
    return SectionCard(
      title: 'Reference Photos',
      trailing: IconButton(
        onPressed: _uploadReferencePhoto,
        icon: const Icon(Icons.add_a_photo_outlined),
        color: AppTheme.primary,
        tooltip: 'Add Reference Photo',
      ),
      child: _referencePhotos.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No reference photos added yet.',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ),
            )
          : Wrap(
              spacing: 16,
              runSpacing: 16,
              children: _referencePhotos.map((photo) {
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FullscreenImageScreen(imageUrl: photo.imageUrl),
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
                                child: Stack(
                                  children: [
                                    Center(
                                      child: Image.network(
                                        photo.imageUrl,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.grey),
                                      ),
                                    ),
                                    Positioned(
                                      right: 8,
                                      top: 8,
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.3),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.open_in_full, size: 14, color: Colors.white),
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
                                    'Reference',
                                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppTheme.textPrimary),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${photo.createdAt.day}/${photo.createdAt.month}/${photo.createdAt.year}',
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

  Future<void> _uploadReferencePhoto() async {
    final ImagePicker picker = ImagePicker();
    
    // Show selection dialog
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Add Reference Photo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: AppTheme.primary),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppTheme.primary),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == null) return;

    final XFile? image = await picker.pickImage(source: source, imageQuality: 70);
    
    if (image == null) return;

    setState(() => _isLoading = true);
    try {
      final bytes = await image.readAsBytes();
      await _service.uploadReferencePhoto(widget.customer.id, bytes);
      await _fetchData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reference photo uploaded successfully!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error uploading photo: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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

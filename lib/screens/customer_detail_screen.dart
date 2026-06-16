import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:url_launcher/url_launcher.dart';

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
  bool _isMeasurementExpanded = false;

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

  void _shareDetails() {
    final customer = context.read<CustomerProvider>().customers.firstWhere(
      (c) => c.id == widget.customer.id,
      orElse: () => widget.customer,
    );
    final buffer = StringBuffer();
    buffer.writeln('👗 *SOUL COUTURE BOUTIQUE* 👗');
    buffer.writeln('----------------------------------');
    buffer.writeln('👤 *Customer:* ${customer.name}');
    if (customer.phone != null && customer.phone!.isNotEmpty) {
      buffer.writeln('📞 *Phone:* ${customer.phone}');
    }
    buffer.writeln('📦 *Status:* ${customer.orderStatus.label}');
    if (customer.dueDate != null) {
      buffer.writeln('📅 *Delivery Due:* ${_formatDate(customer.dueDate!)}');
    }
    
    if (_measurement != null) {
      buffer.writeln('[Upper Body]');
      buffer.writeln('• *Chest:* ${_measurement!.chest?.isNotEmpty == true ? "${_measurement!.chest} in" : "-"}');
      buffer.writeln('• *Waist:* ${_measurement!.waist?.isNotEmpty == true ? "${_measurement!.waist} in" : "-"}');
      buffer.writeln('• *Shoulder:* ${_measurement!.shoulder?.isNotEmpty == true ? "${_measurement!.shoulder} in" : "-"}');
      buffer.writeln('• *Sleeve:* ${_measurement!.sleeve?.isNotEmpty == true ? "${_measurement!.sleeve} in" : "-"}');
      if (_measurement!.thigh?.isNotEmpty == true || 
          _measurement!.inseam?.isNotEmpty == true || 
          _measurement!.length?.isNotEmpty == true) {
        buffer.writeln('\n[Bottom Body]');
        buffer.writeln('• *Thigh:* ${_measurement!.thigh?.isNotEmpty == true ? "${_measurement!.thigh} in" : "-"}');
        buffer.writeln('• *Inseam:* ${_measurement!.inseam?.isNotEmpty == true ? "${_measurement!.inseam} in" : "-"}');
        buffer.writeln('• *Length:* ${_measurement!.length?.isNotEmpty == true ? "${_measurement!.length} in" : "-"}');
      }
    } else {
      buffer.writeln('No measurements recorded yet.');
    }
    buffer.writeln('----------------------------------');
    buffer.write('Thank you for choosing Soul Couture!');

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Customer details copied to clipboard!'),
        backgroundColor: AppTheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customer = context.watch<CustomerProvider>().customers.firstWhere(
      (c) => c.id == widget.customer.id,
      orElse: () => widget.customer,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(customer.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: _shareDetails,
            tooltip: 'Share Details',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileSection(context, customer),
                  const SizedBox(height: 32),
                  _buildDeliverySection(context, customer),
                  const SizedBox(height: 32),
                  _buildScribblesSection(context, customer),
                  const SizedBox(height: 32),
                  _buildReferencePhotosSection(context, customer),
                  const SizedBox(height: 32),
                  _buildMeasurementSection(context, customer),
                  const SizedBox(height: 32),
                  _buildOrderStatusSection(context, customer),
                  const SizedBox(height: 60), // padding at bottom
                ],
              ),
            ),
    );
  }

  LinearGradient _getGradientForName(String name) {
    final int hash = name.hashCode;
    final List<List<Color>> palettes = [
      [const Color(0xFF64748B), const Color(0xFF475569)],
      [const Color(0xFF475569), const Color(0xFF334155)],
      [const Color(0xFF334155), const Color(0xFF1E293B)],
      [const Color(0xFF1E293B), const Color(0xFF0F172A)],
      [const Color(0xFF0F172A), const Color(0xFF0A2540)],
    ];
    final selected = palettes[hash.abs() % palettes.length];
    return LinearGradient(
      colors: selected,
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  Widget _buildProfileSection(BuildContext context, Customer customer) {
    Color typeColor;
    switch (customer.orderType) {
      case OrderType.stitching:
        typeColor = const Color(0xFF475569);
        break;
      case OrderType.handEmbroidery:
        typeColor = const Color(0xFF64748B);
        break;
      case OrderType.both:
        typeColor = const Color(0xFF1E293B);
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: customer.photoUrl == null
                      ? _getGradientForName(customer.name)
                      : null,
                  image: customer.photoUrl != null
                      ? DecorationImage(
                          image: NetworkImage(customer.photoUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: customer.photoUrl == null
                    ? Text(
                        customer.name.characters.first.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    PopupMenuButton<OrderType>(
                      initialValue: customer.orderType,
                      onSelected: (OrderType type) async {
                        try {
                          final provider = Provider.of<CustomerProvider>(context, listen: false);
                          await provider.updateOrderType(customer.id, type);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Order type updated to ${type.label}')),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to update order type: $e')),
                            );
                          }
                        }
                      },
                      itemBuilder: (BuildContext context) => OrderType.values.map((type) {
                        Color tColor;
                        switch (type) {
                          case OrderType.stitching:
                            tColor = const Color(0xFF475569);
                            break;
                          case OrderType.handEmbroidery:
                            tColor = const Color(0xFF64748B);
                            break;
                          case OrderType.both:
                            tColor = const Color(0xFF1E293B);
                            break;
                        }
                        return PopupMenuItem<OrderType>(
                          value: type,
                          child: Row(
                            children: [
                              Icon(
                                type == OrderType.stitching
                                    ? Icons.content_cut_outlined
                                    : type == OrderType.handEmbroidery
                                        ? Icons.brush_outlined
                                        : Icons.all_inclusive_outlined,
                                size: 16,
                                color: tColor,
                              ),
                              const SizedBox(width: 8),
                              Text(type.label, style: TextStyle(color: tColor, fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                        );
                      }).toList(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: typeColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: typeColor.withValues(alpha: 0.2), width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              customer.orderType == OrderType.stitching
                                  ? Icons.content_cut_outlined
                                  : customer.orderType == OrderType.handEmbroidery
                                      ? Icons.brush_outlined
                                      : Icons.all_inclusive_outlined,
                              size: 11,
                              color: typeColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              customer.orderType.label,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: typeColor,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(Icons.arrow_drop_down_rounded, size: 14, color: typeColor),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: Color(0xFFF1F5F9), height: 1),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.phone_outlined, size: 14, color: AppTheme.textSecondary),
                        const SizedBox(width: 6),
                        Text(
                          customer.phone ?? 'No phone number',
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 14, color: AppTheme.textSecondary),
                        const SizedBox(width: 6),
                        Text(
                          'Member since ${_formatDate(customer.createdAt)}',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (customer.phone != null && customer.phone!.isNotEmpty)
                IconButton(
                  onPressed: () async {
                    String cleanPhone = customer.phone!.replaceAll(RegExp(r'\D'), '');
                    if (cleanPhone.length == 10) {
                      cleanPhone = '91$cleanPhone';
                    }
                    final url = "https://wa.me/$cleanPhone";
                    final uri = Uri.parse(url);
                    try {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to open WhatsApp: $e')),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF25D366)),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366).withValues(alpha: 0.1),
                    padding: const EdgeInsets.all(10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  tooltip: 'Chat on WhatsApp',
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]}, ${date.year}';
  }

  String _getDueDaysString(DateTime dueDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final difference = due.difference(today).inDays;

    if (difference == 0) {
      return 'today';
    } else if (difference == 1) {
      return 'tomorrow';
    } else if (difference < 0) {
      return '${difference.abs()} days ago (Overdue)';
    } else {
      return '$difference days';
    }
  }

  Future<void> _editDueDate(Customer customer) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: customer.dueDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primary,
              onPrimary: Colors.white,
              surface: AppTheme.surface,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      try {
        final provider = Provider.of<CustomerProvider>(context, listen: false);
        await provider.updateCustomerDueDate(customer.id, picked);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Delivery date updated successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update delivery date: $e')),
          );
        }
      }
    }
  }

  Widget _buildDeliverySection(BuildContext context, Customer customer) {
    Widget? statusBadge;
    if (customer.dueDate != null && customer.orderStatus != OrderStatus.delivered) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final difference = customer.dueDate!.difference(today).inDays;
      
      String text;
      Color badgeBg;
      Color badgeText = Colors.white;
      
      if (difference < 0) {
        text = 'Overdue';
        badgeBg = const Color(0xFFEF4444);
      } else if (difference == 0) {
        text = 'Due Today';
        badgeBg = const Color(0xFFF59E0B);
      } else if (difference == 1) {
        text = 'Due Tomorrow';
        badgeBg = const Color(0xFF3B82F6);
      } else {
        text = '$difference Days Left';
        badgeBg = AppTheme.primary.withValues(alpha: 0.12);
        badgeText = AppTheme.primary;
      }
      
      statusBadge = Container(
        margin: const EdgeInsets.only(top: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: badgeBg,
          borderRadius: BorderRadius.circular(8),
          border: badgeText == AppTheme.primary 
              ? Border.all(color: AppTheme.primary.withValues(alpha: 0.2), width: 1)
              : null,
        ),
        child: Text(
          text,
          style: TextStyle(
            color: badgeText,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return SectionCard(
      title: 'Expected Delivery',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (customer.dueDate != null)
            IconButton(
              icon: const Icon(Icons.clear_rounded, size: 20),
              color: AppTheme.textSecondary,
              onPressed: () async {
                try {
                  final provider = Provider.of<CustomerProvider>(context, listen: false);
                  await provider.updateCustomerDueDate(customer.id, null);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Delivery date cleared')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error clearing delivery date: $e')),
                    );
                  }
                }
              },
              tooltip: 'Clear Date',
            ),
          IconButton(
            onPressed: () => _editDueDate(customer),
            icon: Icon(customer.dueDate == null ? Icons.add_circle_outline_rounded : Icons.edit_outlined),
            color: AppTheme.primary,
            tooltip: customer.dueDate == null ? 'Set Delivery Date' : 'Edit Delivery Date',
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.calendar_today_rounded, color: AppTheme.primary, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.dueDate != null
                        ? _formatDate(customer.dueDate!)
                        : 'No delivery scheduled',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: customer.dueDate != null ? AppTheme.textPrimary : AppTheme.textSecondary,
                    ),
                  ),
                  if (statusBadge != null) ...[
                    Row(
                      children: [
                        statusBadge,
                      ],
                    ),
                  ] else ...[
                    const SizedBox(height: 4),
                    const Text(
                      'Tap the edit icon to schedule',
                      style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Order Status Colors & Icons (matching home screen) ---
  Color _statusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.ordered:
        return const Color(0xFF64748B); // Slate Gray (neutral, professional)
      case OrderStatus.completed:
        return const Color(0xFF475569); // Dark Slate (neutral, professional)
      case OrderStatus.delivered:
        return const Color(0xFF0F172A); // Midnight Slate (neutral, professional)
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

  Future<void> _showWhatsAppPrompt(BuildContext context, Customer customer) async {
    if (customer.phone == null || customer.phone!.trim().isEmpty) return;

    final confirmSend = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: AppTheme.surface,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFF25D366).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chat_bubble_outline,
                  color: Color(0xFF25D366),
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Notify Customer?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Would you like to send a WhatsApp notification to ${customer.name} informing them that their order is ready for pick-up?',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textSecondary,
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send, size: 16, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Send', style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmSend == true) {
      String cleanPhone = customer.phone!.replaceAll(RegExp(r'\D'), '');
      if (cleanPhone.length == 10) {
        cleanPhone = '91$cleanPhone';
      }
      final message = Uri.encodeComponent("Greetings from Soul Couture! Hi ${customer.name}, your order is ready for pick-up! 😊");
      final url = "https://wa.me/$cleanPhone?text=$message";
      final uri = Uri.parse(url);
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to open WhatsApp: $e')),
          );
        }
      }
    }
  }

  Future<void> _updateStatus(Customer customer, OrderStatus newStatus) async {
    if (newStatus == customer.orderStatus) return;
    
    final targetColor = _statusColor(newStatus);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: AppTheme.surface,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: targetColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _statusIcon(newStatus),
                  color: targetColor,
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Update Status?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.4),
                  children: [
                    const TextSpan(text: 'Are you sure you want to transition this order to '),
                    TextSpan(
                      text: newStatus.label,
                      style: TextStyle(fontWeight: FontWeight.bold, color: targetColor),
                    ),
                    const TextSpan(text: '?'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textSecondary,
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: targetColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Update', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    
    if (confirm != true) return;

    try {
      final provider = Provider.of<CustomerProvider>(context, listen: false);
      await provider.updateOrderStatus(customer.id, newStatus);
      if (newStatus == OrderStatus.completed && mounted) {
        _showWhatsAppPrompt(context, customer);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e')),
        );
      }
    }
  }

  Widget _buildOrderStatusSection(BuildContext context, Customer customer) {
    final stages = OrderStatus.values;
    final currentIndex = stages.indexOf(customer.orderStatus);

    return SectionCard(
      title: 'Order Pipeline',
      trailing: const SizedBox.shrink(),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: List.generate(stages.length * 2 - 1, (i) {
            // Even indices = stage nodes, odd indices = connector lines
            if (i.isOdd) {
              final leftStageIndex = i ~/ 2;
              final isPast = leftStageIndex < currentIndex;
              return Expanded(
                child: Container(
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(1),
                    color: isPast
                        ? _statusColor(stages[leftStageIndex + 1])
                        : const Color(0xFFE2E8F0),
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
              onTap: () => _updateStatus(customer, stage),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Circle icon
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: isActive ? 48 : 40,
                        height: isActive ? 48 : 40,
                        decoration: BoxDecoration(
                          color: (isActive || isPast)
                              ? color.withValues(alpha: isActive ? 0.12 : 0.06)
                              : const Color(0xFFF8FAFC),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: (isActive || isPast) ? color : const Color(0xFFE2E8F0),
                            width: isActive ? 2 : 1.5,
                          ),
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.2),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : [],
                        ),
                        child: Icon(
                          isPast ? Icons.check_rounded : _statusIcon(stage),
                          size: isActive ? 22 : 18,
                          color: (isActive || isPast) ? color : const Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Label
                      Text(
                        stage.label,
                        style: TextStyle(
                          fontSize: isActive ? 12 : 11,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                          color: isActive ? color : AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildMeasurementSection(BuildContext context, Customer customer) {
    return SectionCard(
      title: 'Measurements',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isMeasurementExpanded)
            IconButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MeasurementFormScreen(
                      customerId: customer.id,
                      existingMeasurement: _measurement,
                    ),
                  ),
                );
                _fetchData(); // Reload after edit
              },
              icon: Icon(_measurement == null ? Icons.add_circle_outline_rounded : Icons.edit_outlined),
              color: AppTheme.primary,
              tooltip: _measurement == null ? 'Add Measurements' : 'Edit Measurements',
            ),
          IconButton(
            onPressed: () => setState(() => _isMeasurementExpanded = !_isMeasurementExpanded),
            icon: Icon(_isMeasurementExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded),
            color: AppTheme.textSecondary,
            tooltip: _isMeasurementExpanded ? 'Collapse' : 'Expand',
          ),
        ],
      ),
      child: !_isMeasurementExpanded
          ? InkWell(
              onTap: () => setState(() => _isMeasurementExpanded = true),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (_measurement == null ? AppTheme.textSecondary : AppTheme.primary).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.straighten_rounded, 
                        size: 18, 
                        color: _measurement == null ? AppTheme.textSecondary : AppTheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _measurement == null
                          ? const Text(
                              'No measurements recorded yet.',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                              ),
                            )
                          : SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  if (_measurement!.chest?.isNotEmpty == true)
                                    _buildMiniChip('Chest', _measurement!.chest!),
                                  if (_measurement!.waist?.isNotEmpty == true)
                                    _buildMiniChip('Waist', _measurement!.waist!),
                                  if (_measurement!.shoulder?.isNotEmpty == true)
                                    _buildMiniChip('Shoulder', _measurement!.shoulder!),
                                  if (_measurement!.sleeve?.isNotEmpty == true)
                                    _buildMiniChip('Sleeve', _measurement!.sleeve!),
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            )
          : _measurement == null
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    children: [
                      const Icon(Icons.straighten_rounded, size: 48, color: Color(0xFFE2E8F0)),
                      const SizedBox(height: 12),
                      const Text(
                        'No measurements recorded yet.', 
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: const Text('Add Measurements'),
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MeasurementFormScreen(
                                customerId: customer.id,
                                existingMeasurement: _measurement,
                              ),
                            ),
                          );
                          _fetchData(); // Reload after edit
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Upper Body',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: AppTheme.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 2.2,
                      children: [
                        _MeasurementCard(label: 'Chest', value: _measurement!.chest),
                        _MeasurementCard(label: 'Waist', value: _measurement!.waist),
                        _MeasurementCard(label: 'Shoulder', value: _measurement!.shoulder),
                        _MeasurementCard(label: 'Sleeve', value: _measurement!.sleeve),
                      ],
                    ),
                    if (_measurement!.thigh?.isNotEmpty == true ||
                        _measurement!.inseam?.isNotEmpty == true ||
                        _measurement!.length?.isNotEmpty == true) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Divider(color: Color(0xFFE2E8F0), height: 1),
                      ),
                      const Text(
                        'Bottom Body',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: AppTheme.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 2.2,
                        children: [
                          _MeasurementCard(label: 'Thigh', value: _measurement!.thigh),
                          _MeasurementCard(label: 'Inseam', value: _measurement!.inseam),
                          _MeasurementCard(label: 'Length', value: _measurement!.length),
                        ],
                      ),
                    ],
                  ],
                ),
    );
  }

  Widget _buildMiniChip(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 11, color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildScribblesSection(BuildContext context, Customer customer) {
    return SectionCard(
      title: 'Digital Notes',
      trailing: IconButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ScribbleScreen(customerId: customer.id),
            ),
          );
          _fetchData(); // Reload after new scribble
        },
        icon: const Icon(Icons.draw_rounded),
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
              spacing: 14,
              runSpacing: 14,
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
                  child: Container(
                    width: 140,
                    height: 170,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
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
                                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image_rounded, color: Colors.grey),
                                    ),
                                  ),
                                  Positioned(
                                    right: 2,
                                    top: 2,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primary.withValues(alpha: 0.08),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.open_in_full_rounded, size: 12, color: AppTheme.primary),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Container(
                            color: const Color(0xFFF8FAFC),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Digital Note',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textPrimary),
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
                );
              }).toList(),
            ),
    );
  }

  bool _isImageLink(String url) {
    final cleanUrl = url.toLowerCase().trim();
    if (cleanUrl.contains('reference_photos')) return true;
    if (cleanUrl.endsWith('.jpg') ||
        cleanUrl.endsWith('.jpeg') ||
        cleanUrl.endsWith('.png') ||
        cleanUrl.endsWith('.webp') ||
        cleanUrl.endsWith('.gif')) {
      return true;
    }
    return false;
  }

  String _getDomainName(String url) {
    try {
      final uri = Uri.parse(url);
      final host = uri.host;
      if (host.startsWith('www.')) {
        return host.substring(4);
      }
      return host.isNotEmpty ? host : 'Web Link';
    } catch (_) {
      return 'Web Link';
    }
  }

  Future<void> _launchReferenceUrl(String url) async {
    String formattedUrl = url.trim();
    if (!formattedUrl.startsWith('http://') && !formattedUrl.startsWith('https://')) {
      formattedUrl = 'https://$formattedUrl';
    }
    final Uri uri = Uri.parse(formattedUrl);
    try {
      // First try platformDefault (default browser / in-app view)
      final bool launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
      if (!launched) {
        // Fallback to external application
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      // Catch error and try external application fallback
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (ex) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error opening link: $ex')),
          );
        }
      }
    }
  }

  Widget _buildReferencePhotosSection(BuildContext context, Customer customer) {
    return SectionCard(
      title: 'Reference Photos & Links',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () => _showAddLinkDialog(customer.id),
            icon: const Icon(Icons.link_rounded),
            color: AppTheme.primary,
            tooltip: 'Add Web Link',
          ),
          IconButton(
            onPressed: () => _uploadReferencePhoto(customer.id),
            icon: const Icon(Icons.add_a_photo_outlined),
            color: AppTheme.primary,
            tooltip: 'Add Reference Photo',
          ),
        ],
      ),
      child: _referencePhotos.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No reference photos or links added yet.',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ),
            )
          : Wrap(
              spacing: 14,
              runSpacing: 14,
              children: _referencePhotos.map((photo) {
                final isPhoto = _isImageLink(photo.imageUrl);
                return GestureDetector(
                  onTap: () {
                    if (isPhoto) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FullscreenImageScreen(imageUrl: photo.imageUrl),
                        ),
                      );
                    } else {
                      _launchReferenceUrl(photo.imageUrl);
                    }
                  },
                  child: Container(
                    width: 140,
                    height: 170,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
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
                              color: const Color(0xFFF8FAFC),
                              child: Stack(
                                children: [
                                  if (isPhoto)
                                    Center(
                                      child: Image.network(
                                        photo.imageUrl,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image_rounded, color: Colors.grey),
                                      ),
                                    )
                                  else
                                    Center(
                                      child: Icon(
                                        photo.imageUrl.toLowerCase().contains('instagram.com')
                                            ? Icons.camera_alt_rounded
                                            : Icons.link_rounded,
                                        size: 32,
                                        color: photo.imageUrl.toLowerCase().contains('instagram.com')
                                            ? const Color(0xFFE1306C)
                                            : AppTheme.primary,
                                      ),
                                    ),
                                  Positioned(
                                    right: 6,
                                    top: 6,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.3),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isPhoto ? Icons.open_in_full_rounded : Icons.open_in_new_rounded,
                                        size: 11,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Container(
                            color: const Color(0xFFF8FAFC),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isPhoto
                                      ? 'Reference'
                                      : (photo.imageUrl.toLowerCase().contains('instagram.com')
                                          ? 'Instagram'
                                          : _getDomainName(photo.imageUrl)),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textPrimary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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
                );
              }).toList(),
            ),
    );
  }

  Future<void> _showAddLinkDialog(String customerId) async {
    final TextEditingController linkController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.link_rounded, color: AppTheme.primary),
              SizedBox(width: 8),
              Text('Add Reference Link'),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Paste an Instagram or web link shared by the customer as reference.',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: linkController,
                  decoration: InputDecoration(
                    labelText: 'Reference Link / URL',
                    hintText: 'https://instagram.com/...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.primary, width: 2),
                    ),
                    prefixIcon: const Icon(Icons.language, color: AppTheme.textSecondary),
                  ),
                  keyboardType: TextInputType.url,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a URL';
                    }
                    final uri = Uri.tryParse(value.trim());
                    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
                      return 'Please enter a valid URL';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState?.validate() == true) {
                  final url = linkController.text.trim();
                  Navigator.pop(context);
                  
                  setState(() => _isLoading = true);
                  try {
                    await _service.addReferenceLink(customerId, url);
                    await _fetchData();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Reference link added successfully!')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error adding link: $e')),
                      );
                    }
                  } finally {
                    if (mounted) setState(() => _isLoading = false);
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _uploadReferencePhoto(String customerId) async {
    final ImagePicker picker = ImagePicker();
    
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
      await _service.uploadReferencePhoto(customerId, bytes);
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

class _MeasurementCard extends StatelessWidget {
  final String label;
  final String? value;

  const _MeasurementCard({required this.label, this.value});

  @override
  Widget build(BuildContext context) {
    final hasVal = value?.isNotEmpty == true;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            hasVal ? '$value"' : '-',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: hasVal ? AppTheme.primary : AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

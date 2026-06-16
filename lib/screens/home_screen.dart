import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/customer_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/empty_state.dart';
import 'customer_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  OrderStatus? _selectedFilter; // null means "All"
  OrderType? _selectedOrderTypeFilter; // null means "All"
  DateTimeRange? _selectedDateRange;
  String? _selectedDateFilter; // null, 'pending', 'today', 'thisWeek', 'custom'
  String? _quickFilter; // null, 'active', 'dueToday', 'overdue'
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _sortByUrgency = false;
  
  // Gallery zoom state
  double _crossAxisCount = 3;
  double _baseScale = 3;
  bool _isScaleInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isScaleInitialized) {
      final width = MediaQuery.of(context).size.width;
      if (width < 600) {
        _crossAxisCount = 2.0;
      } else if (width < 900) {
        _crossAxisCount = 3.0;
      } else {
        _crossAxisCount = 4.0;
      }
      _isScaleInitialized = true;
    }
  }

  double _getAspectRatio() {
    final cols = _crossAxisCount.round();
    if (cols <= 2) return 0.82;
    if (cols == 3) return 0.75;
    if (cols == 4) return 0.70;
    if (cols == 5) return 0.65;
    return 0.60;
  }

  bool _hasActiveFilters() {
    return _selectedFilter != null || _selectedOrderTypeFilter != null || _selectedDateFilter != null || _quickFilter != null;
  }

  int _activeFilterCount() {
    int count = 0;
    if (_selectedFilter != null) count++;
    if (_selectedOrderTypeFilter != null) count++;
    if (_selectedDateFilter != null) count++;
    if (_quickFilter != null) count++;
    return count;
  }

  void _openFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Consumer<CustomerProvider>(
        builder: (context, provider, _) => _FilterBottomSheet(
          initialStatus: _selectedFilter,
          initialOrderType: _selectedOrderTypeFilter,
          initialDateFilter: _selectedDateFilter,
          initialDateRange: _selectedDateRange,
          customers: provider.customers,
          onApply: (status, type, dateFilter, dateRange) {
            setState(() {
              _selectedFilter = status;
              _selectedOrderTypeFilter = type;
              _selectedDateFilter = dateFilter;
              _selectedDateRange = dateRange;
            });
          },
        ),
      ),
    );
  }

  Widget _buildActiveFiltersBanner() {
    if (!_hasActiveFilters()) return const SizedBox.shrink();

    final stitchingColor = const Color(0xFF475569);
    final embroideryColor = const Color(0xFF64748B);
    final bothColor = const Color(0xFF1E293B);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      color: AppTheme.background,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            if (_selectedFilter != null) ...[
              Chip(
                label: Text('Status: ${_selectedFilter!.label}'),
                onDeleted: () => setState(() => _selectedFilter = null),
                deleteIconColor: AppTheme.textSecondary,
                backgroundColor: _statusColor(_selectedFilter!).withOpacity(0.08),
                labelStyle: TextStyle(color: _statusColor(_selectedFilter!), fontSize: 12, fontWeight: FontWeight.bold),
                side: BorderSide.none,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              const SizedBox(width: 8),
            ],
            if (_selectedOrderTypeFilter != null) ...[
              Chip(
                label: Text('Type: ${_selectedOrderTypeFilter!.label}'),
                onDeleted: () => setState(() => _selectedOrderTypeFilter = null),
                deleteIconColor: AppTheme.textSecondary,
                backgroundColor: (
                  _selectedOrderTypeFilter == OrderType.stitching
                      ? stitchingColor
                      : _selectedOrderTypeFilter == OrderType.handEmbroidery
                          ? embroideryColor
                          : bothColor
                ).withOpacity(0.08),
                labelStyle: TextStyle(
                  color: _selectedOrderTypeFilter == OrderType.stitching
                      ? stitchingColor
                      : _selectedOrderTypeFilter == OrderType.handEmbroidery
                          ? embroideryColor
                          : bothColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                side: BorderSide.none,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              const SizedBox(width: 8),
            ],
            if (_selectedDateFilter != null) ...[
              Chip(
                label: Text(
                  _selectedDateFilter == 'pending'
                      ? 'Due: Pending'
                      : _selectedDateFilter == 'today'
                          ? 'Due: Today'
                          : _selectedDateFilter == 'thisWeek'
                              ? 'Due: This Week'
                              : 'Due: ${_selectedDateRange!.start.day}/${_selectedDateRange!.start.month} - ${_selectedDateRange!.end.day}/${_selectedDateRange!.end.month}',
                ),
                onDeleted: () => setState(() {
                  _selectedDateFilter = null;
                  _selectedDateRange = null;
                }),
                deleteIconColor: AppTheme.textSecondary,
                backgroundColor: AppTheme.primary.withOpacity(0.08),
                labelStyle: const TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.bold),
                side: BorderSide.none,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              const SizedBox(width: 8),
            ],
            if (_quickFilter != null) ...[
              Chip(
                label: Text('Filter: ${_quickFilter == 'active' ? 'Active Orders' : _quickFilter == 'dueToday' ? 'Due Today' : 'Overdue Orders'}'),
                onDeleted: () => setState(() => _quickFilter = null),
                deleteIconColor: AppTheme.textSecondary,
                backgroundColor: (_quickFilter == 'active'
                        ? const Color(0xFF6366F1)
                        : _quickFilter == 'dueToday'
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444))
                    .withOpacity(0.08),
                labelStyle: TextStyle(
                  color: _quickFilter == 'active'
                      ? const Color(0xFF6366F1)
                      : _quickFilter == 'dueToday'
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                side: BorderSide.none,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              const SizedBox(width: 8),
            ],
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _selectedFilter = null;
                  _selectedOrderTypeFilter = null;
                  _selectedDateFilter = null;
                  _selectedDateRange = null;
                  _quickFilter = null;
                });
              },
              icon: const Icon(Icons.restart_alt_rounded, size: 14, color: Colors.redAccent),
              label: const Text('Reset All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.redAccent)),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, List<Customer>> _groupCustomersByDate(List<Customer> customers) {
    final Map<String, List<Customer>> groups = {};
    final now = DateTime.now();

    for (var customer in customers) {
      final date = customer.createdAt;
      String groupTitle;

      if (date.year == now.year && date.month == now.month && date.day == now.day) {
        groupTitle = 'Today';
      } else if (date.year == now.year && date.month == now.month && date.day == now.day - 1) {
        groupTitle = 'Yesterday';
      } else if (now.difference(date).inDays < 7) {
        groupTitle = 'This Week';
      } else if (now.difference(date).inDays < 30) {
        groupTitle = 'This Month';
      } else if (date.year == now.year) {
        groupTitle = 'Earlier this Year';
      } else {
        groupTitle = '${date.year}';
      }

      if (!groups.containsKey(groupTitle)) {
        groups[groupTitle] = [];
      }
      groups[groupTitle]!.add(customer);
    }
    return groups;
  }

  Map<String, List<Customer>> _groupCustomersByUrgency(List<Customer> customers) {
    final Map<String, List<Customer>> groups = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (var customer in customers) {
      String groupTitle;
      if (customer.orderStatus == OrderStatus.delivered) {
        groupTitle = 'Completed & Delivered';
      } else if (customer.dueDate == null) {
        groupTitle = 'No Deadline';
      } else {
        final diff = customer.dueDate!.difference(today).inDays;
        if (diff < 0) {
          groupTitle = 'Overdue';
        } else if (diff == 0) {
          groupTitle = 'Due Today';
        } else if (diff == 1) {
          groupTitle = 'Due Tomorrow';
        } else if (diff <= 7) {
          groupTitle = 'Due This Week';
        } else {
          groupTitle = 'Due Later';
        }
      }

      if (!groups.containsKey(groupTitle)) {
        groups[groupTitle] = [];
      }
      groups[groupTitle]!.add(customer);
    }

    final Map<String, List<Customer>> sortedGroups = {};
    final orderedKeys = ['Overdue', 'Due Today', 'Due Tomorrow', 'Due This Week', 'Due Later', 'No Deadline', 'Completed & Delivered'];
    for (var key in orderedKeys) {
      if (groups.containsKey(key)) {
        sortedGroups[key] = groups[key]!;
      }
    }
    groups.forEach((key, value) {
      if (!sortedGroups.containsKey(key)) {
        sortedGroups[key] = value;
      }
    });

    return sortedGroups;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Colors for each status stage
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

  void _showAddCustomerDialog(BuildContext context) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    Uint8List? selectedImageBytes;
    DateTime? selectedDueDate;
    OrderType selectedOrderType = OrderType.stitching;
    String? errorMessage;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> pickImage() async {
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
                        child: Text('Customer Photo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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

              if (source != null) {
                final XFile? image = await picker.pickImage(source: source, imageQuality: 60);
                if (image != null) {
                  final bytes = await image.readAsBytes();
                  setDialogState(() => selectedImageBytes = bytes);
                }
              }
            }

            return AlertDialog(
              backgroundColor: AppTheme.surface,
              surfaceTintColor: AppTheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: const Text('New Customer', style: TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                errorMessage!,
                                style: const TextStyle(color: Colors.red, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    // Photo Picker
                    Center(
                      child: GestureDetector(
                        onTap: pickImage,
                        child: Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
                            image: selectedImageBytes != null
                                ? DecorationImage(image: MemoryImage(selectedImageBytes!), fit: BoxFit.cover)
                                : null,
                          ),
                          child: selectedImageBytes == null
                              ? const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_a_photo_outlined, color: AppTheme.primary, size: 28),
                                    SizedBox(height: 4),
                                    Text('Photo', style: TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                                  ],
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    CustomTextField(
                      label: 'Full Name',
                      controller: nameController,
                      prefixIcon: Icons.person_outline,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      label: 'Phone Number',
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      prefixIcon: Icons.phone_outlined,
                    ),
                    const SizedBox(height: 16),
                    // Due Date Picker Field
                    InkWell(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDueDate ?? DateTime.now().add(const Duration(days: 7)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
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
                          setDialogState(() => selectedDueDate = picked);
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE3E8EE), width: 1),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, color: AppTheme.textSecondary, size: 18),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Delivery Due Date', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                                  const SizedBox(height: 2),
                                  Text(
                                    selectedDueDate != null
                                        ? '${selectedDueDate!.day}/${selectedDueDate!.month}/${selectedDueDate!.year}'
                                        : 'Select due date (Optional)',
                                    style: TextStyle(
                                      color: selectedDueDate != null ? AppTheme.textPrimary : AppTheme.textSecondary,
                                      fontWeight: selectedDueDate != null ? FontWeight.bold : FontWeight.normal,
                                      fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (selectedDueDate != null)
                                GestureDetector(
                                  onTap: () {
                                    setDialogState(() => selectedDueDate = null);
                                  },
                                  child: const Icon(Icons.clear, color: AppTheme.textSecondary, size: 18),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Order Type Segmented Control
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Order Type', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                          const SizedBox(height: 6),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            padding: const EdgeInsets.all(2),
                            child: Row(
                              children: OrderType.values.map((type) {
                                final isSelected = selectedOrderType == type;
                                Color typeColor;
                                switch (type) {
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
                                return Expanded(
                                  child: GestureDetector(
                                    onTap: () => setDialogState(() => selectedOrderType = type),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      alignment: Alignment.center,
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isSelected ? Colors.white : Colors.transparent,
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: isSelected
                                            ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]
                                            : [],
                                      ),
                                      child: Text(
                                        type.label,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          color: isSelected ? typeColor : AppTheme.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                actionsPadding: const EdgeInsets.only(right: 24, bottom: 24, left: 24),
                actions: [
                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          text: 'Cancel',
                          isOutlined: true,
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomButton(
                          text: 'Save',
                          onPressed: () async {
                            if (nameController.text.trim().isEmpty) return;
                            
                            try {
                              setDialogState(() => errorMessage = null);
                              final provider = Provider.of<CustomerProvider>(context, listen: false);
                              await provider.addCustomer(
                                nameController.text.trim(),
                                phoneController.text.trim(),
                                selectedImageBytes,
                                dueDate: selectedDueDate,
                                orderType: selectedOrderType,
                              );
                              if (context.mounted) Navigator.pop(context);
                          } catch (e) {
                            String errorMsg = e.toString();
                            if (errorMsg.contains('23505') || errorMsg.contains('unique_customer_name_phone')) {
                              errorMsg = 'A customer with this name and phone number already exists.';
                            } else {
                              errorMsg = errorMsg.replaceAll('Exception: ', '');
                            }
                            setDialogState(() => errorMessage = errorMsg);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
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

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.2),
            width: isSelected ? 2.0 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.01),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? Colors.white : color,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white.withOpacity(0.9) : color.withOpacity(0.8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(int active, int dueToday, int overdue) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      color: AppTheme.background,
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              title: 'Active',
              value: '$active',
              icon: Icons.assignment_outlined,
              color: const Color(0xFF6366F1),
              isSelected: _quickFilter == 'active',
              onTap: () {
                setState(() {
                  if (_quickFilter == 'active') {
                    _quickFilter = null;
                  } else {
                    _quickFilter = 'active';
                  }
                });
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              title: 'Due Today',
              value: '$dueToday',
              icon: Icons.alarm_rounded,
              color: const Color(0xFF10B981),
              isSelected: _quickFilter == 'dueToday',
              onTap: () {
                setState(() {
                  if (_quickFilter == 'dueToday') {
                    _quickFilter = null;
                  } else {
                    _quickFilter = 'dueToday';
                  }
                });
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              title: 'Overdue',
              value: '$overdue',
              icon: Icons.warning_amber_rounded,
              color: const Color(0xFFEF4444),
              isSelected: _quickFilter == 'overdue',
              onTap: () {
                setState(() {
                  if (_quickFilter == 'overdue') {
                    _quickFilter = null;
                  } else {
                    _quickFilter = 'overdue';
                  }
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
        actions: [
          IconButton(
            icon: Icon(
              _sortByUrgency ? Icons.alarm_on_rounded : Icons.sort_rounded,
              color: _sortByUrgency ? AppTheme.primary : null,
            ),
            onPressed: () {
              setState(() {
                _sortByUrgency = !_sortByUrgency;
              });
            },
            tooltip: _sortByUrgency ? 'Sorted by Urgency' : 'Sort by Urgency',
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => context.read<AuthProvider>().signOut(),
            tooltip: 'Sign Out',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<CustomerProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (provider.error != null) {
            return EmptyState(
              icon: Icons.error_outline,
              title: 'Something went wrong',
              message: provider.error!,
            );
          }

          if (provider.customers.isEmpty) {
            return EmptyState(
              icon: Icons.people_outline,
              title: 'No Customers Yet',
              message: 'Add your first customer to start tracking measurements and notes.',
              action: CustomButton(
                text: 'Add Customer',
                icon: Icons.add,
                onPressed: () => _showAddCustomerDialog(context),
              ),
            );
          }

          final activeOrders = provider.customers.where((c) => c.orderStatus != OrderStatus.delivered).length;
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final dueToday = provider.customers.where((c) => c.orderStatus != OrderStatus.delivered && c.dueDate != null && DateUtils.isSameDay(c.dueDate!, today)).length;
          final overdue = provider.customers.where((c) => c.orderStatus != OrderStatus.delivered && c.dueDate != null && c.dueDate!.isBefore(today)).length;

          var filteredCustomers = provider.customers.where((c) {
            // 1. Search Query
            final query = _searchQuery.toLowerCase();
            final nameMatches = c.name.toLowerCase().contains(query);
            final phoneMatches = c.phone != null && c.phone!.toLowerCase().contains(query);
            
            // 2. Status Filter
            final statusMatches = _selectedFilter == null || c.orderStatus == _selectedFilter;

            // 3. Order Type Filter
            final typeMatches = _selectedOrderTypeFilter == null || c.orderType == _selectedOrderTypeFilter;
            
            // 4. Due Date Filter
            bool dateMatches = true;
            if (_selectedDateFilter != null) {
              if (c.dueDate == null) {
                dateMatches = false;
              } else {
                final due = DateTime(c.dueDate!.year, c.dueDate!.month, c.dueDate!.day);
                
                if (_selectedDateFilter == 'pending') {
                  dateMatches = due.isBefore(today);
                } else if (_selectedDateFilter == 'today') {
                  dateMatches = due.isAtSameMomentAs(today);
                } else if (_selectedDateFilter == 'thisWeek') {
                  final monday = today.subtract(Duration(days: today.weekday - 1));
                  final sunday = monday.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
                  dateMatches = (due.isAtSameMomentAs(monday) || due.isAfter(monday)) &&
                                (due.isBefore(sunday) || due.isAtSameMomentAs(sunday));
                } else if (_selectedDateFilter == 'custom' && _selectedDateRange != null) {
                  final start = DateTime(_selectedDateRange!.start.year, _selectedDateRange!.start.month, _selectedDateRange!.start.day);
                  final end = DateTime(_selectedDateRange!.end.year, _selectedDateRange!.end.month, _selectedDateRange!.end.day, 23, 59, 59);
                  dateMatches = (due.isAtSameMomentAs(start) || due.isAfter(start)) &&
                                (due.isBefore(end) || due.isAtSameMomentAs(end));
                }
              }
            }

            // 5. Quick Filter
            bool quickMatches = true;
            if (_quickFilter != null) {
              if (_quickFilter == 'active') {
                quickMatches = c.orderStatus != OrderStatus.delivered;
              } else if (_quickFilter == 'dueToday') {
                quickMatches = c.orderStatus != OrderStatus.delivered && c.dueDate != null && DateUtils.isSameDay(c.dueDate!, today);
              } else if (_quickFilter == 'overdue') {
                quickMatches = c.orderStatus != OrderStatus.delivered && c.dueDate != null && c.dueDate!.isBefore(today);
              }
            }

            return (nameMatches || phoneMatches) && statusMatches && typeMatches && dateMatches && quickMatches;
          }).toList();

          if (_sortByUrgency) {
            filteredCustomers.sort((a, b) {
              if (a.orderStatus == OrderStatus.delivered && b.orderStatus != OrderStatus.delivered) return 1;
              if (b.orderStatus == OrderStatus.delivered && a.orderStatus != OrderStatus.delivered) return -1;
              
              if (a.dueDate == null && b.dueDate != null) return 1;
              if (b.dueDate == null && a.dueDate != null) return -1;
              if (a.dueDate == null && b.dueDate == null) {
                return b.createdAt.compareTo(a.createdAt);
              }
              return a.dueDate!.compareTo(b.dueDate!);
            });
          }

          final groupedCustomers = _sortByUrgency
              ? _groupCustomersByUrgency(filteredCustomers)
              : _groupCustomersByDate(filteredCustomers);
          final keys = groupedCustomers.keys.toList();

          return Column(
            children: [
              _buildStatsRow(activeOrders, dueToday, overdue),
              // Search bar
              Container(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                color: AppTheme.background,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search customers...',
                          prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, color: AppTheme.textSecondary),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = '';
                                    });
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: AppTheme.surface,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: AppTheme.primary, width: 2),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: _hasActiveFilters() ? AppTheme.primary : AppTheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _hasActiveFilters() ? AppTheme.primary : const Color(0xFFE2E8F0),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.filter_list_rounded,
                              color: _hasActiveFilters() ? Colors.white : AppTheme.textPrimary,
                            ),
                            onPressed: _openFilterBottomSheet,
                            tooltip: 'Filters',
                            style: IconButton.styleFrom(
                              padding: const EdgeInsets.all(12),
                            ),
                          ),
                        ),
                        if (_hasActiveFilters())
                          Positioned(
                            right: -4,
                            top: -4,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Colors.redAccent,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${_activeFilterCount()}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              _buildActiveFiltersBanner(),
              // Customer list
              Expanded(
                child: GestureDetector(
                  onScaleStart: (details) {
                    _baseScale = _crossAxisCount;
                  },
                  onScaleUpdate: (details) {
                    setState(() {
                      final isMobile = MediaQuery.of(context).size.width < 600;
                      final maxColumns = isMobile ? 4.0 : 6.0;
                      _crossAxisCount = (_baseScale / details.scale).clamp(2.0, maxColumns);
                    });
                  },
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      ...keys.expand((group) {
                        final customersInGroup = groupedCustomers[group]!;
                        return [
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                              child: Text(
                                group,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            sliver: SliverGrid(
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: _crossAxisCount.round(),
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                childAspectRatio: _getAspectRatio(),
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final customer = customersInGroup[index];
                                  return _buildCustomerGridItem(context, customer, provider);
                                },
                                childCount: customersInGroup.length,
                              ),
                            ),
                          ),
                        ];
                      }).toList(),
                      const SliverToBoxAdapter(child: SizedBox(height: 100)),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'addCustomerBtn',
        onPressed: () => _showAddCustomerDialog(context),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCustomerGridItem(BuildContext context, Customer customer, CustomerProvider provider) {
    final statusColor = _statusColor(customer.orderStatus);
    final orderTypeColor = customer.orderType == OrderType.stitching
        ? const Color(0xFF475569)
        : customer.orderType == OrderType.handEmbroidery
            ? const Color(0xFF64748B)
            : const Color(0xFF1E293B);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        
        // Dynamic scaling constants based on actual layout width
        final double iconSize = width > 120 ? 14 : (width > 80 ? 12 : 10);
        final double iconPadding = width > 120 ? 6 : 4;
        final double positionedOffset = width > 120 ? 8 : 4;
        final double fontSizeMonogram = width > 120 ? 28 : (width > 80 ? 20 : 14);
        final double fontSizeName = width > 120 ? 13 : (width > 80 ? 11 : 9);
        final double fontSizeBadge = width > 120 ? 9 : (width > 80 ? 8 : 7);
        final bool showExtraBadges = width > 70; // Hide the badges completely if too narrow
        
        Widget? dueDateBadge;
        if (customer.dueDate != null && customer.orderStatus != OrderStatus.delivered && showExtraBadges) {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final difference = customer.dueDate!.difference(today).inDays;
          
          String text;
          Color badgeBg;
          Color badgeText = Colors.white;
          
          if (difference < 0) {
            text = 'Overdue';
            badgeBg = const Color(0xFF991B1B); // Muted dark crimson
          } else if (difference == 0) {
            text = 'Today';
            badgeBg = const Color(0xFF9A3412); // Muted rust/amber
          } else if (difference == 1) {
            text = 'Tomorrow';
            badgeBg = const Color(0xFF1E3A8A); // Muted deep navy
          } else {
            text = '$difference d';
            badgeBg = AppTheme.primary.withOpacity(0.85);
          }
          dueDateBadge = Positioned(
            bottom: positionedOffset,
            left: positionedOffset,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: width > 120 ? 8 : 4,
                vertical: width > 120 ? 4 : 2,
              ),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(width > 120 ? 8 : 6),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 4),
                ],
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: badgeText,
                  fontSize: fontSizeBadge,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CustomerDetailScreen(customer: customer),
              ),
            );
          },
          borderRadius: BorderRadius.circular(24),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: customer.photoUrl == null
                          ? _getGradientForName(customer.name)
                          : null,
                      image: customer.photoUrl != null
                          ? DecorationImage(
                              image: NetworkImage(customer.photoUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Stack(
                      children: [
                        if (customer.photoUrl == null)
                          Center(
                            child: Text(
                              customer.name.characters.first.toUpperCase(),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: fontSizeMonogram,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        Positioned(
                          top: positionedOffset,
                          right: positionedOffset,
                          child: Container(
                            padding: EdgeInsets.all(iconPadding),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4),
                              ],
                            ),
                            child: Icon(
                              _statusIcon(customer.orderStatus),
                              size: iconSize,
                              color: statusColor,
                            ),
                          ),
                        ),
                        if (dueDateBadge != null) dueDateBadge,
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  customer.name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: fontSizeName,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                if (showExtraBadges) ...[
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: orderTypeColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          customer.orderType == OrderType.handEmbroidery
                              ? 'Embroidery'
                              : customer.orderType.label,
                          style: TextStyle(
                            fontSize: fontSizeBadge,
                            color: orderTypeColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (customer.dueDate != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${customer.dueDate!.day.toString().padLeft(2, '0')}/${customer.dueDate!.month.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              fontSize: fontSizeBadge,
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }




}

class _FilterBottomSheet extends StatefulWidget {
  final OrderStatus? initialStatus;
  final OrderType? initialOrderType;
  final String? initialDateFilter;
  final DateTimeRange? initialDateRange;
  final List<Customer> customers;
  final Function(OrderStatus?, OrderType?, String?, DateTimeRange?) onApply;

  const _FilterBottomSheet({
    Key? key,
    required this.initialStatus,
    required this.initialOrderType,
    required this.initialDateFilter,
    required this.initialDateRange,
    required this.customers,
    required this.onApply,
  }) : super(key: key);

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  OrderStatus? _selectedStatus;
  OrderType? _selectedOrderType;
  String? _selectedDateFilter;
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.initialStatus;
    _selectedOrderType = widget.initialOrderType;
    _selectedDateFilter = widget.initialDateFilter;
    _selectedDateRange = widget.initialDateRange;
  }

  int _getFilteredCount() {
    return widget.customers.where((c) {
      final statusMatches = _selectedStatus == null || c.orderStatus == _selectedStatus;
      final typeMatches = _selectedOrderType == null || c.orderType == _selectedOrderType;
      
      bool dateMatches = true;
      if (_selectedDateFilter != null) {
        if (c.dueDate == null) {
          dateMatches = false;
        } else {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final due = DateTime(c.dueDate!.year, c.dueDate!.month, c.dueDate!.day);
          
          if (_selectedDateFilter == 'pending') {
            dateMatches = due.isBefore(today);
          } else if (_selectedDateFilter == 'today') {
            dateMatches = due.isAtSameMomentAs(today);
          } else if (_selectedDateFilter == 'thisWeek') {
            final monday = today.subtract(Duration(days: today.weekday - 1));
            final sunday = monday.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
            dateMatches = (due.isAtSameMomentAs(monday) || due.isAfter(monday)) &&
                          (due.isBefore(sunday) || due.isAtSameMomentAs(sunday));
          } else if (_selectedDateFilter == 'custom' && _selectedDateRange != null) {
            final start = DateTime(_selectedDateRange!.start.year, _selectedDateRange!.start.month, _selectedDateRange!.start.day);
            final end = DateTime(_selectedDateRange!.end.year, _selectedDateRange!.end.month, _selectedDateRange!.end.day, 23, 59, 59);
            dateMatches = (due.isAtSameMomentAs(start) || due.isAfter(start)) &&
                          (due.isBefore(end) || due.isAtSameMomentAs(end));
          }
        }
      }
      return statusMatches && typeMatches && dateMatches;
    }).length;
  }

  void _selectCustomDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
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
      setState(() {
        _selectedDateRange = picked;
        _selectedDateFilter = 'custom';
      });
    }
  }

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
  }  Widget _buildOptionRow({
    required bool isSelected,
    required VoidCallback onTap,
    required String label,
    required IconData icon,
    required Color color,
    required int count,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.06) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.12) : Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: isSelected ? color : AppTheme.textSecondary, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? color : AppTheme.textPrimary,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.12) : Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? color : AppTheme.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusTab() {
    final ordered = widget.customers.where((c) => c.orderStatus == OrderStatus.ordered).length;
    final completed = widget.customers.where((c) => c.orderStatus == OrderStatus.completed).length;
    final delivered = widget.customers.where((c) => c.orderStatus == OrderStatus.delivered).length;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _buildOptionRow(
            isSelected: _selectedStatus == OrderStatus.ordered,
            onTap: () => setState(() => _selectedStatus = OrderStatus.ordered),
            label: 'Ordered',
            icon: _statusIcon(OrderStatus.ordered),
            color: _statusColor(OrderStatus.ordered),
            count: ordered,
          ),
          _buildOptionRow(
            isSelected: _selectedStatus == OrderStatus.completed,
            onTap: () => setState(() => _selectedStatus = OrderStatus.completed),
            label: 'Completed',
            icon: _statusIcon(OrderStatus.completed),
            color: _statusColor(OrderStatus.completed),
            count: completed,
          ),
          _buildOptionRow(
            isSelected: _selectedStatus == OrderStatus.delivered,
            onTap: () => setState(() => _selectedStatus = OrderStatus.delivered),
            label: 'Delivered',
            icon: _statusIcon(OrderStatus.delivered),
            color: _statusColor(OrderStatus.delivered),
            count: delivered,
          ),
          const Divider(height: 16, thickness: 1, color: Color(0xFFF1F5F9)),
          _buildOptionRow(
            isSelected: _selectedStatus == null,
            onTap: () => setState(() => _selectedStatus = null),
            label: 'All Statuses',
            icon: Icons.people_outline,
            color: AppTheme.primary,
            count: widget.customers.length,
          ),
        ],
      ),
    );
  }

  Widget _buildTypeTab() {
    final stitching = widget.customers.where((c) => c.orderType == OrderType.stitching).length;
    final embroidery = widget.customers.where((c) => c.orderType == OrderType.handEmbroidery).length;
    final both = widget.customers.where((c) => c.orderType == OrderType.both).length;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          _buildOptionRow(
            isSelected: _selectedOrderType == OrderType.stitching,
            onTap: () => setState(() => _selectedOrderType = OrderType.stitching),
            label: 'Stitching',
            icon: Icons.content_cut_outlined,
            color: const Color(0xFF8B5CF6),
            count: stitching,
          ),
          _buildOptionRow(
            isSelected: _selectedOrderType == OrderType.handEmbroidery,
            onTap: () => setState(() => _selectedOrderType = OrderType.handEmbroidery),
            label: 'Embroidery',
            icon: Icons.brush_outlined,
            color: const Color(0xFFEC4899),
            count: embroidery,
          ),
          _buildOptionRow(
            isSelected: _selectedOrderType == OrderType.both,
            onTap: () => setState(() => _selectedOrderType = OrderType.both),
            label: 'Both',
            icon: Icons.all_inclusive_outlined,
            color: const Color(0xFFF59E0B),
            count: both,
          ),
          const Divider(height: 16, thickness: 1, color: Color(0xFFF1F5F9)),
          _buildOptionRow(
            isSelected: _selectedOrderType == null,
            onTap: () => setState(() => _selectedOrderType = null),
            label: 'All Types',
            icon: Icons.layers_outlined,
            color: AppTheme.primary,
            count: widget.customers.length,
          ),
        ],
      ),
    );
  }

  Widget _buildDateTab() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final pendingCount = widget.customers.where((c) => c.dueDate != null && c.dueDate!.isBefore(today)).length;
    final todayCount = widget.customers.where((c) => c.dueDate != null && DateUtils.isSameDay(c.dueDate!, today)).length;
    
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final sunday = monday.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
    final thisWeekCount = widget.customers.where((c) {
      if (c.dueDate == null) return false;
      final due = DateTime(c.dueDate!.year, c.dueDate!.month, c.dueDate!.day);
      return (due.isAtSameMomentAs(monday) || due.isAfter(monday)) &&
             (due.isBefore(sunday) || due.isAtSameMomentAs(sunday));
    }).length;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildOptionRow(
            isSelected: _selectedDateFilter == 'pending',
            onTap: () => setState(() {
              _selectedDateFilter = 'pending';
              _selectedDateRange = null;
            }),
            label: 'Pending',
            icon: Icons.error_outline_rounded,
            color: Colors.redAccent,
            count: pendingCount,
          ),
          _buildOptionRow(
            isSelected: _selectedDateFilter == 'today',
            onTap: () => setState(() {
              _selectedDateFilter = 'today';
              _selectedDateRange = null;
            }),
            label: 'Today',
            icon: Icons.today_outlined,
            color: const Color(0xFF10B981),
            count: todayCount,
          ),
          _buildOptionRow(
            isSelected: _selectedDateFilter == 'thisWeek',
            onTap: () => setState(() {
              _selectedDateFilter = 'thisWeek';
              _selectedDateRange = null;
            }),
            label: 'This Week',
            icon: Icons.date_range_outlined,
            color: const Color(0xFF3B82F6),
            count: thisWeekCount,
          ),
          const SizedBox(height: 8),
          const Text(
            'Custom Date Range',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _selectCustomDateRange,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: _selectedDateFilter == 'custom'
                    ? AppTheme.primary.withOpacity(0.06)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedDateFilter == 'custom'
                      ? AppTheme.primary
                      : const Color(0xFFE2E8F0),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_month_outlined,
                    color: _selectedDateFilter == 'custom' ? AppTheme.primary : AppTheme.textSecondary,
                    size: 18,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedDateFilter == 'custom' && _selectedDateRange != null
                          ? '${_selectedDateRange!.start.day}/${_selectedDateRange!.start.month}/${_selectedDateRange!.start.year} - ${_selectedDateRange!.end.day}/${_selectedDateRange!.end.month}/${_selectedDateRange!.end.year}'
                          : 'Select range...',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: _selectedDateFilter == 'custom' ? FontWeight.bold : FontWeight.normal,
                        color: _selectedDateFilter == 'custom' ? AppTheme.textPrimary : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: _selectedDateFilter == 'custom' ? AppTheme.primary : AppTheme.textSecondary,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 16, thickness: 1, color: Color(0xFFF1F5F9)),
          _buildOptionRow(
            isSelected: _selectedDateFilter == null,
            onTap: () => setState(() {
              _selectedDateFilter = null;
              _selectedDateRange = null;
            }),
            label: 'All Dates',
            icon: Icons.calendar_today_outlined,
            color: AppTheme.primary,
            count: widget.customers.length,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).padding.bottom + 16,
          top: 10,
        ),
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filters',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.textSecondary, size: 20),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(2),
              child: TabBar(
                indicator: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                labelColor: AppTheme.textPrimary,
                unselectedLabelColor: AppTheme.textSecondary,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                tabs: const [
                  Tab(text: 'Status'),
                  Tab(text: 'Order Type'),
                  Tab(text: 'Due Date'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 240,
              child: TabBarView(
                children: [
                  _buildStatusTab(),
                  _buildTypeTab(),
                  _buildDateTab(),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _selectedStatus = null;
                        _selectedOrderType = null;
                        _selectedDateFilter = null;
                        _selectedDateRange = null;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Reset All', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onApply(_selectedStatus, _selectedOrderType, _selectedDateFilter, _selectedDateRange);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text(
                      'View ${_getFilteredCount()} Results',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ); }
}

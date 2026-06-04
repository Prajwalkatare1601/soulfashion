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
  DateTimeRange? _selectedDateRange;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _sortByUrgency = false;
  
  // Gallery zoom state
  double _crossAxisCount = 3;
  double _baseScale = 3;

  void _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
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
      setState(() => _selectedDateRange = picked);
    }
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
        return const Color(0xFFF59E0B); // Amber
      case OrderStatus.completed:
        return const Color(0xFF3B82F6); // Blue
      case OrderStatus.delivered:
        return const Color(0xFF10B981); // Emerald
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
                          
                          final provider = Provider.of<CustomerProvider>(context, listen: false);
                          await provider.addCustomer(
                            nameController.text.trim(),
                            phoneController.text.trim(),
                            selectedImageBytes,
                            dueDate: selectedDueDate,
                          );
                          
                          if (context.mounted) Navigator.pop(context);
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
            icon: Icon(
              Icons.calendar_month_outlined,
              color: _selectedDateRange != null ? AppTheme.primary : null,
            ),
            onPressed: _selectDateRange,
            tooltip: 'Filter by Date',
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => context.read<AuthProvider>().signOut(),
            tooltip: 'Sign Out',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            color: AppTheme.background,
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
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
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
          // Date Presets
          Container(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            color: AppTheme.background,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildPresetChip('Today', DateTime.now(), DateTime.now()),
                  const SizedBox(width: 8),
                  _buildPresetChip('Yesterday', DateTime.now().subtract(const Duration(days: 1)), DateTime.now().subtract(const Duration(days: 1))),
                  const SizedBox(width: 8),
                  _buildPresetChip('7 Days', DateTime.now().subtract(const Duration(days: 7)), DateTime.now()),
                  const SizedBox(width: 8),
                  _buildPresetChip('30 Days', DateTime.now().subtract(const Duration(days: 30)), DateTime.now()),
                ],
              ),
            ),
          ),
          // Pipeline filter chips
          Consumer<CustomerProvider>(
            builder: (context, provider, _) {
              final customers = provider.customers;
              final orderedCount = customers.where((c) => c.orderStatus == OrderStatus.ordered).length;
              final completedCount = customers.where((c) => c.orderStatus == OrderStatus.completed).length;
              final deliveredCount = customers.where((c) => c.orderStatus == OrderStatus.delivered).length;

              return Container(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                color: AppTheme.background,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(
                        label: 'All',
                        count: customers.length,
                        isSelected: _selectedFilter == null,
                        color: AppTheme.primary,
                        icon: Icons.people_outline,
                        onTap: () => setState(() => _selectedFilter = null),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: 'Ordered',
                        count: orderedCount,
                        isSelected: _selectedFilter == OrderStatus.ordered,
                        color: _statusColor(OrderStatus.ordered),
                        icon: _statusIcon(OrderStatus.ordered),
                        onTap: () => setState(() => _selectedFilter = OrderStatus.ordered),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: 'Completed',
                        count: completedCount,
                        isSelected: _selectedFilter == OrderStatus.completed,
                        color: _statusColor(OrderStatus.completed),
                        icon: _statusIcon(OrderStatus.completed),
                        onTap: () => setState(() => _selectedFilter = OrderStatus.completed),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: 'Delivered',
                        count: deliveredCount,
                        isSelected: _selectedFilter == OrderStatus.delivered,
                        color: _statusColor(OrderStatus.delivered),
                        icon: _statusIcon(OrderStatus.delivered),
                        onTap: () => setState(() => _selectedFilter = OrderStatus.delivered),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          // Customer list
          Expanded(
            child: Consumer<CustomerProvider>(
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
            
                var filteredCustomers = provider.customers.where((c) {
                  // 1. Search Query
                  final query = _searchQuery.toLowerCase();
                  final nameMatches = c.name.toLowerCase().contains(query);
                  final phoneMatches = c.phone != null && c.phone!.toLowerCase().contains(query);
                  
                  // 2. Status Filter
                  final statusMatches = _selectedFilter == null || c.orderStatus == _selectedFilter;
                  
                  // 3. Date Range Filter
                  bool dateMatches = true;
                  if (_selectedDateRange != null) {
                    final date = c.createdAt;
                    final start = DateTime(_selectedDateRange!.start.year, _selectedDateRange!.start.month, _selectedDateRange!.start.day);
                    final end = DateTime(_selectedDateRange!.end.year, _selectedDateRange!.end.month, _selectedDateRange!.end.day, 23, 59, 59);
                    dateMatches = date.isAfter(start) && date.isBefore(end);
                  }

                  return (nameMatches || phoneMatches) && statusMatches && dateMatches;
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
                
                // Show date filter active indicator
                Widget? dateFilterIndicator;
                if (_selectedDateRange != null) {
                  dateFilterIndicator = Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.date_range, size: 16, color: AppTheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Filtered by Date',
                            style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => setState(() => _selectedDateRange = null),
                            child: const Icon(Icons.cancel, size: 16, color: AppTheme.primary),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final groupedCustomers = _sortByUrgency
                    ? _groupCustomersByUrgency(filteredCustomers)
                    : _groupCustomersByDate(filteredCustomers);
                final keys = groupedCustomers.keys.toList();
            
                return GestureDetector(
                  onScaleStart: (details) {
                    _baseScale = _crossAxisCount;
                  },
                  onScaleUpdate: (details) {
                    setState(() {
                      // Clamp between 2 and 6 columns
                      _crossAxisCount = (_baseScale / details.scale).clamp(2, 6);
                    });
                  },
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      if (dateFilterIndicator != null) 
                        SliverToBoxAdapter(child: dateFilterIndicator),
                      
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
                                childAspectRatio: 0.85,
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
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCustomerDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Customer', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildCustomerGridItem(BuildContext context, Customer customer, CustomerProvider provider) {
    final statusColor = _statusColor(customer.orderStatus);

    Widget? dueDateBadge;
    if (customer.dueDate != null && customer.orderStatus != OrderStatus.delivered) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final difference = customer.dueDate!.difference(today).inDays;
      
      String text;
      Color badgeBg;
      Color badgeText = Colors.white;
      
      if (difference < 0) {
        text = 'Overdue';
        badgeBg = const Color(0xFFEF4444); // Red
      } else if (difference == 0) {
        text = 'Today';
        badgeBg = const Color(0xFFF59E0B); // Amber
      } else if (difference == 1) {
        text = 'Tomorrow';
        badgeBg = const Color(0xFF3B82F6); // Blue
      } else {
        text = '$difference d';
        badgeBg = AppTheme.primary.withOpacity(0.85);
      }
      
      dueDateBadge = Positioned(
        bottom: 8,
        left: 8,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: badgeBg,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 4),
            ],
          ),
          child: Text(
            text,
            style: TextStyle(
              color: badgeText,
              fontSize: _crossAxisCount > 4 ? 8 : 10,
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
      borderRadius: BorderRadius.circular(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                image: customer.photoUrl != null
                    ? DecorationImage(
                        image: NetworkImage(customer.photoUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Stack(
                children: [
                  if (customer.photoUrl == null)
                    Center(
                      child: Text(
                        customer.name.characters.first.toUpperCase(),
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontSize: _crossAxisCount > 4 ? 16 : 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  // Status Badge Overlay
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4),
                        ],
                      ),
                      child: Icon(
                        _statusIcon(customer.orderStatus),
                        size: _crossAxisCount > 4 ? 10 : 14,
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
              fontSize: _crossAxisCount > 4 ? 11 : 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetChip(String label, DateTime start, DateTime end) {
    // Normalize for comparison
    final range = DateTimeRange(
      start: DateTime(start.year, start.month, start.day),
      end: DateTime(end.year, end.month, end.day),
    );
    
    final isSelected = _selectedDateRange != null &&
        _selectedDateRange!.start.year == range.start.year &&
        _selectedDateRange!.start.month == range.start.month &&
        _selectedDateRange!.start.day == range.start.day &&
        _selectedDateRange!.end.year == range.end.year &&
        _selectedDateRange!.end.month == range.end.month &&
        _selectedDateRange!.end.day == range.end.day;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedDateRange = selected ? range : null;
        });
      },
      selectedColor: AppTheme.primary.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        fontSize: 12,
      ),
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isSelected ? AppTheme.primary.withOpacity(0.5) : const Color(0xFFE3E8EE),
        ),
      ),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required int count,
    required bool isSelected,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? color : AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? color : const Color(0xFFE3E8EE),
                width: 1.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : [],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isSelected ? Colors.white : color,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 6),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withOpacity(0.25)
                        : color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: isSelected ? Colors.white : color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerCard(BuildContext context, Customer customer, CustomerProvider provider) {

    return Card(
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CustomerDetailScreen(customer: customer),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Squircle Avatar
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  image: customer.photoUrl != null
                      ? DecorationImage(
                          image: NetworkImage(customer.photoUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                alignment: Alignment.center,
                child: customer.photoUrl == null
                    ? Text(
                        customer.name.characters.first.toUpperCase(),
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontSize: 16,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      customer.phone != null && customer.phone!.isNotEmpty 
                          ? customer.phone! 
                          : 'No phone added',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    // Status badge with dropdown
                    _buildStatusDropdown(customer, provider),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppTheme.textSecondary.withOpacity(0.5)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusDropdown(Customer customer, CustomerProvider provider) {
    final statusColor = _statusColor(customer.orderStatus);

    return PopupMenuButton<OrderStatus>(
      onSelected: (newStatus) {
        provider.updateOrderStatus(customer.id, newStatus);
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: AppTheme.surface,
      elevation: 6,
      position: PopupMenuPosition.under,
      itemBuilder: (context) => OrderStatus.values.map((status) {
        final isActive = status == customer.orderStatus;
        return PopupMenuItem<OrderStatus>(
          value: status,
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: _statusColor(status).withOpacity(isActive ? 0.15 : 0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Icon(
                  _statusIcon(status),
                  size: 16,
                  color: _statusColor(status),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                status.label,
                style: TextStyle(
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  color: isActive ? _statusColor(status) : AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              if (isActive)
                Icon(Icons.check_circle, size: 18, color: _statusColor(status)),
            ],
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: statusColor.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_statusIcon(customer.orderStatus), size: 14, color: statusColor),
            const SizedBox(width: 5),
            Text(
              customer.orderStatus.label,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, size: 16, color: statusColor),
          ],
        ),
      ),
    );
  }
}

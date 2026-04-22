import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddCustomerDialog(BuildContext context) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          surfaceTintColor: AppTheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('New Customer', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
            ],
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
                        null,
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
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
            
                final filteredCustomers = provider.customers.where((c) {
                  final query = _searchQuery.toLowerCase();
                  final nameMatches = c.name.toLowerCase().contains(query);
                  final phoneMatches = c.phone != null && c.phone!.toLowerCase().contains(query);
                  return nameMatches || phoneMatches;
                }).toList();
            
                if (filteredCustomers.isEmpty) {
                  return const EmptyState(
                    icon: Icons.search_off,
                    title: 'No Results Found',
                    message: 'Try adjusting your search query.',
                  );
                }
            
                return ListView.separated(
                  itemCount: filteredCustomers.length,
                  padding: const EdgeInsets.only(bottom: 100, left: 20, right: 20, top: 4),
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final customer = filteredCustomers[index];
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
                                  borderRadius: BorderRadius.circular(16), // Squircle effect
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
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right, color: AppTheme.textSecondary.withOpacity(0.5)),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
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
}

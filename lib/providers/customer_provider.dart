import 'dart:io';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/supabase_service.dart';

class CustomerProvider extends ChangeNotifier {
  final SupabaseService _service = SupabaseService();
  
  List<Customer> _customers = [];
  bool _isLoading = false;
  String? _error;

  List<Customer> get customers => _customers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  CustomerProvider() {
    fetchCustomers();
  }

  Future<void> fetchCustomers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _customers = await _service.getCustomers();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addCustomer(String name, String? phone, File? photoFile) async {
    try {
      final newCustomer = await _service.addCustomer(name, phone, photoFile);
      _customers.insert(0, newCustomer);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteCustomer(String id) async {
    try {
      await _service.deleteCustomer(id);
      _customers.removeWhere((c) => c.id == id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}

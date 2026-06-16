import 'dart:typed_data';
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

  Future<void> addCustomer(
    String name, 
    String? phone, 
    Uint8List? photoBytes, {
    DateTime? dueDate, 
    OrderType orderType = OrderType.stitching,
  }) async {
    try {
      final newCustomer = await _service.addCustomer(name, phone, photoBytes, dueDate: dueDate, orderType: orderType);
      _customers.insert(0, newCustomer);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteCustomer(String id) async {
    try {
      await _service.deleteCustomer(id);
      _customers.removeWhere((c) => c.id == id);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateOrderStatus(String customerId, OrderStatus status) async {
    try {
      await _service.updateOrderStatus(customerId, status);
      final index = _customers.indexWhere((c) => c.id == customerId);
      if (index != -1) {
        final old = _customers[index];
        _customers[index] = Customer(
          id: old.id,
          name: old.name,
          phone: old.phone,
          photoUrl: old.photoUrl,
          orderStatus: status,
          orderType: old.orderType,
          createdAt: old.createdAt,
          dueDate: old.dueDate,
        );
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateOrderType(String customerId, OrderType type) async {
    try {
      await _service.updateOrderType(customerId, type);
      final index = _customers.indexWhere((c) => c.id == customerId);
      if (index != -1) {
        final old = _customers[index];
        _customers[index] = Customer(
          id: old.id,
          name: old.name,
          phone: old.phone,
          photoUrl: old.photoUrl,
          orderStatus: old.orderStatus,
          orderType: type,
          createdAt: old.createdAt,
          dueDate: old.dueDate,
        );
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateCustomerDueDate(String customerId, DateTime? dueDate) async {
    try {
      await _service.updateCustomerDueDate(customerId, dueDate);
      final index = _customers.indexWhere((c) => c.id == customerId);
      if (index != -1) {
        final old = _customers[index];
        _customers[index] = Customer(
          id: old.id,
          name: old.name,
          phone: old.phone,
          photoUrl: old.photoUrl,
          orderStatus: old.orderStatus,
          orderType: old.orderType,
          createdAt: old.createdAt,
          dueDate: dueDate,
        );
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    }
  }
}

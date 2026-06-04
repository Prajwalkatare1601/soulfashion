import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/models.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // Authentication
  User? get currentUser => _client.auth.currentUser;
  Session? get currentSession => _client.auth.currentSession;
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<AuthResponse> signInWithEmail(String email, String password) async {
    return await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUpWithEmail(String email, String password) async {
    return await _client.auth.signUp(email: email, password: password);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // Customers
  Future<List<Customer>> getCustomers() async {
    final response = await _client.from('customers').select().order('created_at', ascending: false);
    return (response as List).map((e) => Customer.fromJson(e)).toList();
  }

  Future<Customer> addCustomer(String name, String? phone, Uint8List? photoBytes) async {
    String? photoUrl;
    if (photoBytes != null) {
      final fileName = '${const Uuid().v4()}.jpg';
      await _client.storage.from('customer_photos').uploadBinary(
        fileName, 
        photoBytes,
        fileOptions: const FileOptions(contentType: 'image/jpeg'),
      );
      photoUrl = _client.storage.from('customer_photos').getPublicUrl(fileName);
    }

    final response = await _client.from('customers').insert({
      'name': name,
      'phone': phone,
      if (photoUrl != null) 'photo_url': photoUrl,
      'order_status': OrderStatus.ordered.name,
    }).select().single();
    
    return Customer.fromJson(response);
  }

  Future<void> deleteCustomer(String id) async {
    await _client.from('customers').delete().eq('id', id);
  }

  Future<void> updateOrderStatus(String customerId, OrderStatus status) async {
    await _client.from('customers').update({
      'order_status': status.name,
    }).eq('id', customerId);
  }

  // Measurements
  Future<Measurement?> getMeasurement(String customerId) async {
    final response = await _client.from('measurements').select().eq('customer_id', customerId).maybeSingle();
    if (response == null) return null;
    return Measurement.fromJson(response);
  }

  Future<Measurement> upsertMeasurement(String customerId, Map<String, dynamic> data) async {
    data['customer_id'] = customerId;
    data['updated_at'] = DateTime.now().toUtc().toIso8601String();
    
    // Check if measurement exists
    final existing = await getMeasurement(customerId);
    if (existing != null) {
      final response = await _client.from('measurements').update(data).eq('id', existing.id).select().single();
      return Measurement.fromJson(response);
    } else {
      final response = await _client.from('measurements').insert(data).select().single();
      return Measurement.fromJson(response);
    }
  }

  // Scribbles
  Future<List<Scribble>> getScribbles(String customerId) async {
    final response = await _client.from('scribbles').select().eq('customer_id', customerId).order('created_at', ascending: false);
    return (response as List).map((e) => Scribble.fromJson(e)).toList();
  }

  Future<Scribble> uploadScribble(String customerId, Uint8List scribbleBytes) async {
    final fileName = '${const Uuid().v4()}.png';
    await _client.storage.from('scribbles').uploadBinary(
      fileName, 
      scribbleBytes,
      fileOptions: const FileOptions(contentType: 'image/png'),
    );
    final imageUrl = _client.storage.from('scribbles').getPublicUrl(fileName);

    final response = await _client.from('scribbles').insert({
      'customer_id': customerId,
      'image_url': imageUrl,
    }).select().single();

    return Scribble.fromJson(response);
  }

  // Reference Photos
  Future<List<ReferencePhoto>> getReferencePhotos(String customerId) async {
    final response = await _client.from('reference_photos').select().eq('customer_id', customerId).order('created_at', ascending: false);
    return (response as List).map((e) => ReferencePhoto.fromJson(e)).toList();
  }

  Future<ReferencePhoto> uploadReferencePhoto(String customerId, Uint8List photoBytes) async {
    final fileName = '${const Uuid().v4()}.jpg';
    await _client.storage.from('reference_photos').uploadBinary(
      fileName, 
      photoBytes,
      fileOptions: const FileOptions(contentType: 'image/jpeg'),
    );
    final imageUrl = _client.storage.from('reference_photos').getPublicUrl(fileName);

    final response = await _client.from('reference_photos').insert({
      'customer_id': customerId,
      'image_url': imageUrl,
    }).select().single();

    return ReferencePhoto.fromJson(response);
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';

class AdminService {
  static const String adminEmail = 'blisscoffeedev@gmail.com';
  final _supabase = Supabase.instance.client;

  /// Returns true ONLY if the logged-in user matches the admin email.
  bool isCurrentUserAdmin() {
    final user = _supabase.auth.currentUser;
    return user?.email == adminEmail;
  }

  /// Adds a new product or updates an existing one in the 'products' table.
  /// Works for both regular and bulk items.
  Future<void> upsertProduct({
    String? id, // If null, it's a new product
    required String name,
    required double price,
    required bool isBulk,
    required String category,
    String? imageUrl,
  }) async {
    final payload = {
      'name': name,
      'price': price,
      'is_bulk': isBulk,
      'category': category,
      'image_url': imageUrl,
    };

    if (id == null) {
      // Insert new product
      await _supabase.from('products').insert(payload);
    } else {
      // Update existing product
      await _supabase.from('products').update(payload).eq('id', id);
    }
  }

  /// Deletes a product from the database.
  Future<void> deleteProduct(String productId) async {
    await _supabase.from('products').delete().eq('id', productId);
  }

  /// Fetches the live stream of products so the Admin UI updates instantly.
  Stream<List<Map<String, dynamic>>> getProductsStream() {
    return _supabase.from('products').stream(primaryKey: ['id']).order('name');
  }
}
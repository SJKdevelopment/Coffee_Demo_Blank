import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  final SupabaseClient _client = Supabase.instance.client;
  SupabaseClient get client => _client;

  static Future<void> initialize() async {}

  bool get isOwner => _client.auth.currentUser?.userMetadata?['role'] == 'owner';
  bool get isBusiness => _client.auth.currentUser?.userMetadata?['role'] == 'business';

  // ==========================================
  // MENU & PRODUCT METHODS
  // ==========================================

  Future<List<Map<String, dynamic>>> fetchProducts() async {
    try {
      final response = await _client
          .from('products')
          .select()
          .order('name', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint("Error fetching products: $e");
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchCoffeeBeans() async {
    try {
      final response = await _client
          .from('coffee_beans')
          .select()
          .order('name', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint("Error fetching coffee beans: $e");
      return [];
    }
  }

  // ==========================================
  // PROMOTIONS METHODS
  // ==========================================

  Future<List<Map<String, dynamic>>> fetchActivePromotions() async {
    try {
      final response = await _client
          .from('promotions')
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint("Error fetching promotions: $e");
      return [];
    }
  }

  // ==========================================
  // AUTH & LOYALTY METHODS
  // ==========================================

  Future<void> incrementUserStamp(String userId) async {
    try {
      final data = await _client
          .from('profiles')
          .select('stamps_count')
          .eq('id', userId)
          .single();

      int currentStamps = data['stamps_count'] ?? 0;

      if (currentStamps < 10) {
        await _client
            .from('profiles')
            .update({'stamps_count': currentStamps + 1})
            .eq('id', userId);
      }
    } catch (e) {
      debugPrint("Error incrementing stamp: $e");
      rethrow;
    }
  }

  Future<String?> getUserIdByReferralCode(String code) async {
    try {
      final data = await _client
          .from('profiles')
          .select('id')
          .eq('referral_code', code.trim().toUpperCase())
          .maybeSingle();
      return data != null ? data['id'] as String : null;
    } catch (e) {
      debugPrint("Error fetching user by code: $e");
      return null;
    }
  }

  Future<bool> registerNewUser({
    required String email,
    required String password,
    required String myReferralCode,
    String? referredBy,
    String? name,
  }) async {
    try {
      final AuthResponse res = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'role': 'customer'},
      );

      if (res.user != null) {
        await _client.from('profiles').upsert({
          'id': res.user!.id,
          'referral_code': myReferralCode,
          'referred_by': referredBy,
          'name': name,
          'has_purchased': false,
          'wallet_balance': 0.0,
          'stamps_count': 0,
          'referral_count': 0,
        });
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Signup Error: $e");
      return false;
    }
  }

  Future<void> updateReferralLink({required String newUserId, required String referrerId}) async {
    try {
      await _client
          .from('profiles')
          .update({'referred_by': referrerId})
          .eq('id', newUserId);
    } catch (e) {
      debugPrint("Error updating referral link: $e");
    }
  }

  Future<void> markReferralAsCompleted(String userId) async {
    try {
      await _client
          .from('profiles')
          .update({'has_purchased': true})
          .eq('id', userId);
    } catch (e) {
      debugPrint("Error marking referral complete: $e");
    }
  }

  Future<Map<String, dynamic>> fetchUserReferralProfile(String userId) async {
    try {
      final profile = await _client
          .from('profiles')
          .select('referral_code, stamps_count, loyalty_redemption_code, is_redeemed, referral_count')
          .eq('id', userId)
          .single();

      // Use referral_count from profiles table instead of counting referrals
      final int referralCount = profile['referral_count'] ?? 0;

      return {
        ...profile,
        'referral_count': referralCount,
      };
    } catch (e) {
      debugPrint("Error fetching referral profile: $e");
      return {};
    }
  }

  // ==========================================
  // LOYALTY REDEMPTION METHODS
  // ==========================================

  Future<String> generateRedemptionCode(String userId) async {
    try {
      // Check if user already has an unclaimed redemption code
      final existingCode = await getCurrentRedemptionCode(userId);

      if (existingCode != null) {
        // User already has an unclaimed code, return it
        return existingCode;
      }

      // Generate new unique 6-digit code only if no existing code
      final String code = _generateUniqueCode();
      
      // Update user profile with redemption code (don't reset stamps - barista app will handle)
      await _client
          .from('profiles')
          .update({
            'loyalty_redemption_code': code,
            'is_redeemed': false, // Explicitly set to false
          })
          .eq('id', userId);

      return code;
    } catch (e) {
      debugPrint("Error generating redemption code: $e");
      rethrow;
    }
  }

  String _generateUniqueCode() {
    final random = DateTime.now().millisecondsSinceEpoch;
    return 'COFFEE${(random % 1000000).toString().padLeft(6, '0')}';
  }

  Future<bool> verifyRedemptionCode(String code) async {
    try {
      final result = await _client
          .from('profiles')
          .select()
          .eq('loyalty_redemption_code', code.toUpperCase())
          .eq('is_redeemed', false)
          .maybeSingle();

      if (result != null) {
        // Mark code as used and reset stamps (barista verifies redemption)
        await _client
            .from('profiles')
            .update({
              'is_redeemed': true,
              'loyalty_redemption_code': null, // Clear the code after use
              'stamps_count': 0, // Reset stamps after redemption
            })
            .eq('id', result['id']);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error verifying redemption code: $e");
      return false;
    }
  }

  Future<String?> getCurrentRedemptionCode(String userId) async {
    try {
      final result = await _client
          .from('profiles')
          .select('loyalty_redemption_code, is_redeemed')
          .eq('id', userId)
          .not('loyalty_redemption_code', 'is', null)
          .maybeSingle();

      // Return code only if it exists and is not redeemed
      if (result != null && 
          result['loyalty_redemption_code'] != null && 
          (result['is_redeemed'] == false || result['is_redeemed'] == null)) {
        return result['loyalty_redemption_code'];
      }
      return null;
    } catch (e) {
      debugPrint("Error getting current redemption code: $e");
      return null;
    }
  }
}
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class ReferralService {
  final SupabaseService _supabaseService = SupabaseService();

  String generateRandomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rnd = Random();
    return String.fromCharCodes(Iterable.generate(6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
  }

  // ==========================================
  // COFFEE LOYALTY LOGIC
  // ==========================================

  Future<void> incrementStampCount() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final profile = await Supabase.instance.client
          .from('profiles')
          .select('stamps_count')
          .eq('id', user.id)
          .single();

      int currentStamps = profile['stamps_count'] ?? 0;
      if (currentStamps >= 10) return;

      await Supabase.instance.client
          .from('profiles')
          .update({'stamps_count': currentStamps + 1})
          .eq('id', user.id);
    } catch (e) {
      debugPrint("Error incrementing stamps: $e");
    }
  }

  Future<int> getCoffeeStampCount() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return 0;
      final data = await Supabase.instance.client.from('profiles').select('stamps_count').eq('id', user.id).single();
      return data['stamps_count'] ?? 0;
    } catch (e) { return 0; }
  }

  /// Saves specifically to 'loyalty_redemption_code'
  Future<String?> generateLoyaltyCode() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return null;

      final String code = "LOYALTY-${generateRandomCode()}";
      await Supabase.instance.client.from('profiles').update({
        'loyalty_redemption_code': code,
        'is_redeemed': false, // Note: You might eventually want 'is_loyalty_redeemed' too
      }).eq('id', user.id);

      return code;
    } catch (e) { return null; }
  }

  // ==========================================
  // REFERRAL LOGIC
  // ==========================================

  /// Saves specifically to 'redemption_code'
  Future<String?> generateReferralRewardCode() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return null;

      final String code = "REF-${generateRandomCode()}";
      await Supabase.instance.client.from('profiles').update({
        'redemption_code': code,
        'referral_reward_claimed': true,
      }).eq('id', user.id);

      return code;
    } catch (e) { return null; }
  }

  // ==========================================
  // CORE SYNC LOGIC
  // ==========================================

  /// Returns a Map of active codes so the UI can show both if they exist
  Future<Map<String, String?>> getAllActiveRewards() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return {};

      final profile = await Supabase.instance.client
          .from('profiles')
          .select('redemption_code, loyalty_redemption_code, is_redeemed, stamps_count')
          .eq('id', user.id)
          .maybeSingle();

      if (profile == null) return {};

      // Handle automatic stamp reset if loyalty code was marked redeemed
      if (profile['is_redeemed'] == true && profile['loyalty_redemption_code'] != null) {
        await Supabase.instance.client.from('profiles').update({
          'stamps_count': 0,
          'loyalty_redemption_code': null,
          'is_redeemed': false,
        }).eq('id', user.id);
        return {'referral': profile['redemption_code'], 'loyalty': null};
      }

      return {
        'referral': profile['redemption_code'],
        'loyalty': profile['loyalty_redemption_code'],
      };
    } catch (e) {
      return {};
    }
  }

  Future<void> linkReferralOnSignUp({required String userId, required String? friendReferralCode}) async {
    if (friendReferralCode == null || friendReferralCode.trim().isEmpty) return;
    try {
      final referrerId = await _supabaseService.getUserIdByReferralCode(friendReferralCode.trim().toUpperCase());
      if (referrerId != null) {
        await _supabaseService.updateReferralLink(newUserId: userId, referrerId: referrerId);
      }
    } catch (e) { debugPrint("Error linking referral: $e"); }
  }

  Future<void> recordFirstPurchase() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) await _supabaseService.markReferralAsCompleted(user.id);
  }

  Future<int> getReferralCount() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return 0;
      final response = await Supabase.instance.client.rpc('get_referral_count', params: {'user_id': user.id});
      return response as int;
    } catch (e) { return 0; }
  }
}
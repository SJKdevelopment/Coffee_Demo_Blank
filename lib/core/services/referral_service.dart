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
  Future<String?> generateReferralRewardCodeForUser(String userId) async {
    try {
      final String code = "REF-${generateRandomCode()}";
      await Supabase.instance.client.from('profiles').update({
        'redemption_code': code,
        'referral_reward_claimed': true,
      }).eq('id', userId);

      return code;
    } catch (e) { 
      debugPrint("Error generating referral reward code: $e");
      return null; 
    }
  }

  /// Saves specifically to 'redemption_code' for current user
  Future<String?> generateReferralRewardCode() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return null;
    return await generateReferralRewardCodeForUser(user.id);
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
        // Update the new user's profile with referrer
        await Supabase.instance.client
            .from('profiles')
            .update({'referred_by': referrerId})
            .eq('id', userId);
        
        // Create referral record
        await Supabase.instance.client
            .from('referrals')
            .insert({
              'referrer_id': referrerId,
              'referee_id': userId,
              'has_purchased': false,
            });
      }
    } catch (e) { 
      debugPrint("Error linking referral: $e"); 
    }
  }

  Future<void> recordFirstPurchase() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    
    try {
      // Mark user as having purchased
      await Supabase.instance.client
          .from('profiles')
          .update({'has_purchased': true})
          .eq('id', user.id);
      
      // Update referral record if user was referred
      await Supabase.instance.client
          .from('referrals')
          .update({'has_purchased': true})
          .eq('referee_id', user.id);
      
      // Check if user was referred and increment referrer's count
      final referralData = await Supabase.instance.client
          .from('profiles')
          .select('referred_by')
          .eq('id', user.id)
          .single();
      
      if (referralData['referred_by'] != null) {
        final referrerId = referralData['referred_by'];
        
        // Increment referrer's referral count (same as stamps)
        await incrementReferralCount(referrerId);
        
        // Check if referrer should get reward (10 referrals)
        final referrerProfile = await Supabase.instance.client
            .from('profiles')
            .select('referral_count')
            .eq('id', referrerId)
            .single();
        
        final int referralCount = referrerProfile['referral_count'] ?? 0;
        
        // If this is the 10th referral, generate reward code
        if (referralCount >= 10) {
          await generateReferralRewardCodeForUser(referrerId);
        }
      }
    } catch (e) {
      debugPrint("Error recording first purchase: $e");
    }
  }

  Future<void> incrementReferralCount(String userId) async {
    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select('referral_count')
          .eq('id', userId)
          .single();

      int currentCount = data['referral_count'] ?? 0;
      
      if (currentCount < 10) {
        await Supabase.instance.client
            .from('profiles')
            .update({'referral_count': currentCount + 1})
            .eq('id', userId);
      }
    } catch (e) {
      debugPrint("Error incrementing referral count: $e");
    }
  }

  Future<int> getReferralCount() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return 0;
      
      // Use referral_count from profiles table (same as stamps)
      final data = await Supabase.instance.client
          .from('profiles')
          .select('referral_count')
          .eq('id', user.id)
          .single();
      
      return data['referral_count'] ?? 0;
    } catch (e) { 
      debugPrint("Error getting referral count: $e");
      return 0; 
    }
  }
}
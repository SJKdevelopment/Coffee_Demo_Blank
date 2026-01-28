import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/referral_service.dart';

class ReferralStatusCard extends StatefulWidget {
  const ReferralStatusCard({super.key});
  @override
  State<ReferralStatusCard> createState() => _ReferralStatusCardState();
}

class _ReferralStatusCardState extends State<ReferralStatusCard> {
  final ReferralService _referralService = ReferralService();

  int _referralCount = 0;
  int _coffeeCount = 0;
  String _myReferralCode = "";
  String? _activeLoyaltyCode;
  String? _activeReferralCode;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllLoyaltyData();
  }

  Future<void> _loadAllLoyaltyData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final rewards = await _referralService.getAllActiveRewards();
      final refCount = await _referralService.getReferralCount();
      final coffeeCount = await _referralService.getCoffeeStampCount();

      final response = await Supabase.instance.client
          .from('profiles')
          .select('referral_code')
          .eq('id', user.id)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _referralCount = refCount;
          _coffeeCount = coffeeCount;
          _activeReferralCode = rewards['referral'];
          _activeLoyaltyCode = rewards['loyalty'];
          _myReferralCode = response?['referral_code'] ?? "";
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Column(
      children: [
        if (_activeLoyaltyCode != null) _buildRewardBlock(theme, _activeLoyaltyCode!, true),
        if (_activeReferralCode != null) _buildRewardBlock(theme, _activeReferralCode!, false),
        const SizedBox(height: 16),
        _buildCoffeeLoyaltyCard(theme),
        const SizedBox(height: 16),
        _buildReferralCard(theme),
      ],
    );
  }

  Widget _buildRewardBlock(ThemeData theme, String code, bool isLoyalty) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      color: isLoyalty ? Colors.brown.withOpacity(0.1) : Colors.green.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isLoyalty ? Colors.brown : Colors.green),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(Icons.confirmation_number, color: isLoyalty ? Colors.brown : Colors.green),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isLoyalty ? "LOYALTY REWARD" : "REFERRAL REWARD", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  Text(code, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoffeeLoyaltyCard(ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Coffee Loyalty Card", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            _buildStampGrid(),
            const SizedBox(height: 15),
            LinearProgressIndicator(value: (_coffeeCount / 10).clamp(0.0, 1.0), minHeight: 8),
            const SizedBox(height: 8),
            Text("$_coffeeCount / 10 coffees purchased"),
            if (_coffeeCount >= 10 && _activeLoyaltyCode == null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      setState(() => _isLoading = true);
                      await _referralService.generateLoyaltyCode();
                      await _loadAllLoyaltyData();
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.brown, foregroundColor: Colors.white),
                    child: const Text("GENERATE LOYALTY CODE"),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStampGrid() {
    return Column(
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: List.generate(5, (index) => Icon(Icons.local_cafe, size: 35, color: index < _coffeeCount ? Colors.brown : Colors.grey.withOpacity(0.3)))),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: List.generate(5, (index) => Icon(Icons.local_cafe, size: 35, color: (index + 5) < _coffeeCount ? Colors.brown : Colors.grey.withOpacity(0.3)))),
      ],
    );
  }

  Widget _buildReferralCard(ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Referral Rewards", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: (_referralCount / 10).clamp(0.0, 1.0), minHeight: 8, color: Colors.green),
            const SizedBox(height: 8),
            Text("$_referralCount / 10 friends joined"),
            if (_referralCount >= 10 && _activeReferralCode == null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      setState(() => _isLoading = true);
                      await _referralService.generateReferralRewardCode();
                      await _loadAllLoyaltyData();
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                    child: const Text("GENERATE REFERRAL CODE"),
                  ),
                ),
              ),
            const Divider(height: 32),
            Row(
              children: [
                Expanded(child: Text(_myReferralCode, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 2))),
                IconButton(icon: const Icon(Icons.copy), onPressed: () => Clipboard.setData(ClipboardData(text: _myReferralCode))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
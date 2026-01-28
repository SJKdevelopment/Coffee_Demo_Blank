import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_yoco/flutter_yoco.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  final _supabase = Supabase.instance.client;
  double _balance = 0.00;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBalance();
  }

  // 1. Get current money
  Future<void> _fetchBalance() async {
    final userId = _supabase.auth.currentUser!.id;
    final data = await _supabase
        .from('profiles')
        .select('wallet_balance')
        .eq('id', userId)
        .single();

    if (mounted) {
      setState(() {
        _balance = (data['wallet_balance'] ?? 0).toDouble();
        _isLoading = false;
      });
    }
  }

  // 2. Add Money (Top Up) - Shared Logic for both Quick & Custom
  Future<void> _topUpWallet(double amount) async {
    // 1. Open Yoco for the Top Up Amount
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FlutterYoco(
          amount: amount,
          transactionId:
              "topup_${DateTime.now().millisecondsSinceEpoch}", // Unique ID
          secretKey: 'sk_test_960bfde0VBrLlpK098e4ffeb53e1', // Your Test Key
          successUrl: 'https://bliss.coffee/success/',
          cancelUrl: 'https://bliss.coffee/cancel/',
          failureUrl: 'https://bliss.coffee/failure/',
          onComplete: (transaction) async {
            if (transaction.status.toString().contains('success')) {
              // 2. Yoco Success -> Add to Database
              try {
                final userId = _supabase.auth.currentUser!.id;
                final newBalance = _balance + amount;

                await _supabase
                    .from('profiles')
                    .update({'wallet_balance': newBalance})
                    .eq('id', userId);

                // 3. Refresh Screen
                await _fetchBalance();

                if (mounted) {
                  Navigator.pop(context); // Close Yoco
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Success! Added R$amount to wallet."),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                print("Database Error: $e");
              }
            } else {
              if (mounted) {
                Navigator.pop(context); // Close Yoco on failure too
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Payment Cancelled or Failed"),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
        ),
      ),
    );
  }

  // 3. NEW: Show Dialog for Custom Amount
  void _showCustomAmountDialog() {
    final TextEditingController customAmountController =
        TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: const Text("Enter Amount"),
        content: TextField(
          controller: customAmountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            prefixText: "R ",
            hintText: "e.g. 150",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              // Logic to clean input (swap commas for dots) and parse
              final String text = customAmountController.text.replaceAll(
                ',',
                '.',
              );
              final double? amount = double.tryParse(text);

              if (amount != null && amount > 0) {
                Navigator.pop(context); // Close dialog
                _topUpWallet(amount); // Start payment with custom amount
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please enter a valid amount")),
                );
              }
            },
            child: const Text("Pay Now"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("My Wallet")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              // Changed to ScrollView to prevent overflow on small screens
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    // --- BALANCE CARD ---
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.secondary,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 10,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Text(
                            "Current Balance",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "R ${_balance.toStringAsFixed(2)}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Quick Top Up",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),

                    // --- QUICK TOP UP BUTTONS ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildTopUpBtn(50),
                        _buildTopUpBtn(100),
                        _buildTopUpBtn(200),
                      ],
                    ),

                    const SizedBox(height: 25),

                    // --- NEW CUSTOM AMOUNT BUTTON ---
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: OutlinedButton.icon(
                        onPressed: _showCustomAmountDialog,
                        icon: const Icon(Icons.edit),
                        label: const Text(
                          "Enter Custom Amount",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.primary,
                          side: BorderSide(
                            color: theme.colorScheme.primary,
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                    const Text(
                      "Secured by Yoco Payments",
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTopUpBtn(double amount) {
    return ElevatedButton(
      onPressed: () => _topUpWallet(amount),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      child: Text(
        "+ R${amount.toInt()}",
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}

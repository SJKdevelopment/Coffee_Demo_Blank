import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrderHistoryPage extends StatelessWidget {
  const OrderHistoryPage({super.key});

  // Helper to format date safely
  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return "${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Order History"),
        backgroundColor: theme.appBarTheme.backgroundColor,
        iconTheme: theme.iconTheme,
      ),
      body: userId == null
          ? const Center(child: Text("Please log in to see orders"))
          : FutureBuilder<List<Map<String, dynamic>>>(
              future: Supabase.instance.client
                  .from('orders')
                  .select()
                  .eq('user_id', userId)
                  .eq('status', 'paid') // <--- FIXED: Changed 'is_paid' to 'status'
                  .order('created_at', ascending: false),
              builder: (context, snapshot) {
                // 1. Loading State
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // 2. Error State (This will catch database errors nicely)
                if (snapshot.hasError) {
                  // If the table is empty or column is missing, show a clean message
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        "No orders found yet.\n(Or check your internet)", 
                        textAlign: TextAlign.center,
                        style: TextStyle(color: theme.colorScheme.onSurface),
                      ),
                    ),
                  );
                }

                final orders = snapshot.data ?? [];

                // 3. Empty State (Logic for 0 orders)
                if (orders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long, size: 60, color: Colors.grey),
                        SizedBox(height: 10),
                        Text(
                          "No past orders found.",
                          style: TextStyle(color: theme.colorScheme.onSurface),
                        ),
                      ],
                    ),
                  );
                }

                // 4. List of Orders
                return ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    final dateString = _formatDate(order['created_at']);
                    
                    // Uses 'total_amount' to match your main.dart logic
                    final amount = order['total_amount'] ?? 0;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      color: theme.cardColor,
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.green,
                          child: Icon(Icons.check, color: Colors.white),
                        ),
                        title: Text(
                          "Order #${order['id'].toString().substring(0, 4)}...",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        subtitle: Text(
                          dateString,
                          style: const TextStyle(color: Colors.grey),
                        ),
                        trailing: Text(
                          "R${amount.toString()}",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
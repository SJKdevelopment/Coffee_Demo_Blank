import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';

class AdminProductManagerPage extends StatefulWidget {
  const AdminProductManagerPage({super.key});

  @override
  State<AdminProductManagerPage> createState() => _AdminProductManagerPageState();
}

class _AdminProductManagerPageState extends State<AdminProductManagerPage> {
  final _supabase = Supabase.instance.client;
  bool _showBeansTable = false; // Toggle state
  final _codeController = TextEditingController();

  // ==========================================
  // DATABASE ACTIONS
  // ==========================================

  Future<void> _deleteItem(String id, String table) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: Text("Are you sure you want to remove this item from $table? This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _supabase.from(table).delete().eq('id', id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Item deleted successfully")));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
        }
      }
    }
  }

  // ==========================================
  // REDEMPTION CODE VERIFICATION
  // ==========================================

  Future<void> _verifyRedemptionCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      _showMessage("Please enter a redemption code", Colors.orange);
      return;
    }

    try {
      final isValid = await SupabaseService().verifyRedemptionCode(code);
      
      if (isValid) {
        _showMessage("✅ Redemption code verified! Free coffee redeemed.", Colors.green);
        _codeController.clear();
      } else {
        _showMessage("❌ Invalid or already used redemption code", Colors.red);
      }
    } catch (e) {
      _showMessage("Error verifying code: $e", Colors.red);
    }
  }

  void _showMessage(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showRedemptionVerification() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("🎫 Verify Redemption Code"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Enter the redemption code provided by the customer:"),
            const SizedBox(height: 16),
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: "Redemption Code",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.confirmation_number),
              ),
              textCapitalization: TextCapitalization.characters,
              onSubmitted: (_) => _verifyRedemptionCode(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _codeController.clear();
              Navigator.pop(context);
            },
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _verifyRedemptionCode();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text("Verify"),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // EDITOR UI (ADD/EDIT)
  // ==========================================

  void _openEditor({Map<String, dynamic>? item}) {
    final String table = _showBeansTable ? 'coffee_beans' : 'products';

    // Controllers initialized with existing data if editing
    final nameController = TextEditingController(text: item?['name'] ?? '');
    final priceController = TextEditingController(text: item?['price']?.toString() ?? '');
    final descController = TextEditingController(text: item?['description'] ?? '');
    final urlController = TextEditingController(text: item?['image_url'] ?? '');
    final categoryController = TextEditingController(text: item?['category'] ?? 'Coffee');
    final weightController = TextEditingController(text: item?['weight'] ?? '1kg');
    bool isBulk = item?['is_bulk'] ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24, right: 24, top: 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
                const SizedBox(height: 20),
                Text(item == null ? "Add New $table" : "Edit $table Item",
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),

                TextField(controller: nameController, decoration: const InputDecoration(labelText: "Product Name", prefixIcon: Icon(Icons.title))),
                TextField(controller: priceController, decoration: const InputDecoration(labelText: "Price (R)", prefixIcon: Icon(Icons.payments)), keyboardType: TextInputType.number),
                TextField(controller: descController, decoration: const InputDecoration(labelText: "Description", prefixIcon: Icon(Icons.description))),
                TextField(controller: urlController, decoration: const InputDecoration(labelText: "Image URL (Direct Link)", prefixIcon: Icon(Icons.image))),

                if (!_showBeansTable) ...[
                  TextField(controller: categoryController, decoration: const InputDecoration(labelText: "Category", prefixIcon: Icon(Icons.category))),
                  SwitchListTile(
                    title: const Text("Is this a Bulk Item?"),
                    subtitle: const Text("Visible in the Bulk section"),
                    value: isBulk,
                    onChanged: (val) => setModalState(() => isBulk = val),
                  ),
                ],

                if (_showBeansTable)
                  TextField(controller: weightController, decoration: const InputDecoration(labelText: "Weight (e.g. 250g, 1kg)", prefixIcon: Icon(Icons.scale))),

                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.brown,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                    ),
                    onPressed: () async {
                      final payload = {
                        'name': nameController.text,
                        'price': double.tryParse(priceController.text) ?? 0.0,
                        'description': descController.text,
                        'image_url': urlController.text,
                      };

                      if (_showBeansTable) {
                        payload['weight'] = weightController.text;
                      } else {
                        payload['is_bulk'] = isBulk;
                        payload['category'] = categoryController.text;
                      }

                      if (item == null) {
                        await _supabase.from(table).insert(payload);
                      } else {
                        await _supabase.from(table).update(payload).eq('id', item['id']);
                      }

                      if (mounted) Navigator.pop(context);
                    },
                    child: const Text("SAVE CHANGES", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // MAIN BUILDER
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Inventory Admin"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.verified, size: 28),
            onPressed: _showRedemptionVerification,
            tooltip: "Verify Redemption Code",
          ),
          IconButton(
            icon: const Icon(Icons.add_box_rounded, size: 28),
            onPressed: () => _openEditor(),
          )
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          // Segmented Switcher
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text("Menu Items"), icon: Icon(Icons.local_cafe)),
                  ButtonSegment(value: true, label: Text("Coffee Beans"), icon: Icon(Icons.shopping_bag)),
                ],
                selected: {_showBeansTable},
                onSelectionChanged: (val) => setState(() => _showBeansTable = val.first),
              ),
            ),
          ),
          const SizedBox(height: 10),

          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _supabase.from(_showBeansTable ? 'coffee_beans' : 'products').stream(primaryKey: ['id']).order('name'),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final items = snapshot.data!;
                if (items.isEmpty) return const Center(child: Text("No items found. Click + to add one."));

                return ListView.builder(
                  itemCount: items.length,
                  padding: const EdgeInsets.only(bottom: 80),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: ListTile(
                        leading: Container(
                          width: 50, height: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: NetworkImage(item['image_url'] ?? 'https://via.placeholder.com/150'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        title: Text(item['name'] ?? 'Untitled', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("R${item['price']} — ${_showBeansTable ? (item['weight'] ?? '1kg') : (item['is_bulk'] == true ? 'BULK' : 'REGULAR')}"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _openEditor(item: item)),
                            IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteItem(item['id'].toString(), _showBeansTable ? 'coffee_beans' : 'products')),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/pibd_theme.dart';

class StockPage extends StatefulWidget {
  final Map<String, dynamic>? user;
  const StockPage({super.key, this.user});

  @override
  State<StockPage> createState() => _StockPageState();
}

class _StockPageState extends State<StockPage> {
  final apiService = ApiService();
  bool loading = true;
  String? error;
  List<dynamic> items = [];
  bool get isAdmin {
    final roles =
        (widget.user?['roles'] as List?)?.map((e) => e.toString()).toSet() ??
        {};
    return roles.contains('admin') || roles.contains('superadmin');
  }

  @override
  void initState() {
    super.initState();
    loadStock();
  }

  Future<void> loadStock() async {
    try {
      final data = await apiService.getStock();
      if (!mounted) return;
      setState(() {
        items = _extractList(data, const ['items', 'stock_items', 'data']);
        loading = false;
        error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  List<dynamic> _extractList(Map<String, dynamic> response, List<String> keys) {
    for (final key in keys) {
      final value = response[key];
      if (value is List) return value;
      if (value is Map) {
        final nested = Map<String, dynamic>.from(value);
        for (final nestedKey in const ['items', 'stock_items', 'data']) {
          if (nested[nestedKey] is List)
            return nested[nestedKey] as List<dynamic>;
        }
      }
    }
    return <dynamic>[];
  }

  Future<void> openItemForm({Map<String, dynamic>? item}) async {
    final code = TextEditingController(text: item?['item_code']?.toString());
    final name = TextEditingController(
      text: item?['name']?.toString() ?? item?['item_name']?.toString(),
    );
    final unit = TextEditingController(
      text: item?['unit']?.toString() ?? 'piece',
    );
    final minimum = TextEditingController(
      text: item?['minimum_stock']?.toString() ?? '0',
    );
    final formKey = GlobalKey<FormState>();
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item == null ? 'Add Stock Item' : 'Edit Stock Item'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: code,
                  decoration: const InputDecoration(labelText: 'Item code'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Item name'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: unit,
                  decoration: const InputDecoration(labelText: 'Unit'),
                ),
                TextFormField(
                  controller: minimum,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Minimum stock'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final data = {
                'item_code': code.text.trim(),
                'name': name.text.trim(),
                'unit': unit.text.trim(),
                'minimum_stock': int.tryParse(minimum.text) ?? 0,
              };
              try {
                if (item == null) {
                  await apiService.createStockItem(data);
                } else {
                  await apiService.updateStockItem(item['id'] as int, data);
                }
                if (context.mounted) Navigator.pop(context, true);
              } catch (e) {
                if (context.mounted)
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(e.toString())));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    code.dispose();
    name.dispose();
    unit.dispose();
    minimum.dispose();
    if (saved == true) loadStock();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PibdTheme.page,
      appBar: AppBar(title: const Text('Stock Management')),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => openItemForm(),
              icon: const Icon(Icons.add),
              label: const Text('Add Stock'),
            )
          : null,
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(error!, textAlign: TextAlign.center),
              ),
            )
          : RefreshIndicator(
              onRefresh: loadStock,
              child: items.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 180),
                        Center(child: Text('No stock items available.')),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (_, index) {
                        final item = Map<String, dynamic>.from(
                          items[index] as Map,
                        );
                        return Card(
                          child: ListTile(
                            leading: const Icon(
                              Icons.inventory_2_outlined,
                              color: PibdTheme.blue,
                            ),
                            title: Text(
                              item['item_name']?.toString() ??
                                  item['name']?.toString() ??
                                  'Stock item',
                            ),
                            subtitle: Text(
                              'Category: ${item['category'] ?? '-'}\nQuantity: ${item['current_stock'] ?? item['quantity'] ?? '-'} ${item['unit'] ?? ''}',
                            ),
                            trailing: isAdmin
                                ? IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () => openItemForm(item: item),
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/pantry_item.dart';
import '../providers/pantry_provider.dart';
import '../widgets/pantry_item_form.dart';

/// Screen to edit an existing pantry item.
class ItemDetailScreen extends StatelessWidget {
  final PantryItem item;
  const ItemDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Item',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF002244),
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFF002244),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: PantryItemForm(
          initial: item,
          submitLabel: 'Save Changes',
          onSubmit: (name, quantity, unit, category, expirationDate) {
            final provider = Provider.of<PantryProvider>(context, listen: false);
            provider.updateItem(
              item.id,
              PantryItem(
                id: item.id,
                name: name,
                quantity: quantity,
                unit: unit,
                expirationDate: expirationDate,
                category: category,
              ),
            );
            Navigator.of(context).pop();
          },
          secondaryAction: Tooltip(
            message: 'Delete this item from your pantry',
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () async {
                final provider = Provider.of<PantryProvider>(context, listen: false);
                await provider.removeItem(item.id);
                if (!context.mounted) return;
                Navigator.of(context).pop();
              },
              child: const Text('Delete'),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/pantry_item.dart';
import '../providers/pantry_provider.dart';
import '../widgets/pantry_item_form.dart';

/// Screen to add a new pantry item.
class AddItemScreen extends StatelessWidget {
  const AddItemScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Item',
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
          submitLabel: 'Add Item',
          showScanButton: true,
          onSubmit: (name, quantity, unit, category, expirationDate) {
            final provider = Provider.of<PantryProvider>(context, listen: false);
            provider.addItem(
              PantryItem(
                id: '',
                name: name,
                quantity: quantity,
                unit: unit,
                expirationDate: expirationDate,
                category: category,
              ),
            );
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }
}

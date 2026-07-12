import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/pantry_item.dart';
import '../providers/pantry_provider.dart';
import 'recipe_suggestions_screen.dart';

/// Lets the user hand-pick a handful of pantry items to build a recipe
/// around, instead of relying on what's expiring soonest.
class IngredientPickerScreen extends StatefulWidget {
  const IngredientPickerScreen({super.key});

  @override
  State<IngredientPickerScreen> createState() => _IngredientPickerScreenState();
}

class _IngredientPickerScreenState extends State<IngredientPickerScreen> {
  final Set<String> _selectedIds = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Ingredients'),
        backgroundColor: const Color(0xFF002244),
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFF002244),
      body: Consumer<PantryProvider>(
        builder: (context, provider, child) {
          return StreamBuilder<List<PantryItem>>(
            stream: provider.itemsStream,
            builder: (context, snapshot) {
              final items = snapshot.data ?? [];
              if (items.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Text(
                      'Add some items to your pantry first.',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              final Map<String, List<PantryItem>> categoryMap = {};
              for (var item in items) {
                categoryMap.putIfAbsent(item.category, () => []).add(item);
              }
              return ListView(
                padding: const EdgeInsets.only(bottom: 96),
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Text(
                      'Select a few ingredients and get a recipe built around them.',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ),
                  for (var entry in categoryMap.entries)
                    Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        title: Text(
                          entry.key,
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontFamily: 'Arial'),
                        ),
                        iconColor: Colors.white,
                        collapsedIconColor: Colors.white,
                        children: [
                          for (var item in entry.value)
                            CheckboxListTile(
                              value: _selectedIds.contains(item.id),
                              onChanged: (checked) {
                                setState(() {
                                  if (checked ?? false) {
                                    _selectedIds.add(item.id);
                                  } else {
                                    _selectedIds.remove(item.id);
                                  }
                                });
                              },
                              title: Text(item.name, style: const TextStyle(color: Colors.white)),
                              subtitle: Text(
                                'Qty: ${item.quantity} ${item.unit}',
                                style: const TextStyle(color: Colors.white70),
                              ),
                              activeColor: const Color(0xFF1B5E20),
                              checkColor: Colors.white,
                              controlAffinity: ListTileControlAffinity.leading,
                            ),
                        ],
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: Consumer<PantryProvider>(
        builder: (context, provider, child) {
          return StreamBuilder<List<PantryItem>>(
            stream: provider.itemsStream,
            builder: (context, snapshot) {
              final items = snapshot.data ?? [];
              return FloatingActionButton.extended(
                onPressed: _selectedIds.isEmpty
                    ? null
                    : () {
                        final selected = items.where((item) => _selectedIds.contains(item.id)).toList();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RecipeSuggestionsScreen(initialItems: selected),
                          ),
                        );
                      },
                backgroundColor: _selectedIds.isEmpty ? Colors.grey : const Color(0xFF1B5E20),
                icon: const Icon(Icons.restaurant_menu),
                label: Text(_selectedIds.isEmpty ? 'Select ingredients' : 'Get Recipes (${_selectedIds.length})'),
              );
            },
          );
        },
      ),
    );
  }
}

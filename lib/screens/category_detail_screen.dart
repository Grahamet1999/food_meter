import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pantry_provider.dart';
import '../models/pantry_item.dart';
import 'item_detail_screen.dart';
import '../utils/expiration_progress.dart';

/// Screen to show all items in a given category.
class CategoryDetailScreen extends StatelessWidget {
  final String category;

  const CategoryDetailScreen({
    super.key,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$category Items'),
        backgroundColor: const Color(0xFF002244),
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFF002244),
      body: Consumer<PantryProvider>(
        builder: (context, provider, child) {
          return StreamBuilder<List<PantryItem>>(
            stream: provider.itemsStream,
            builder: (context, snapshot) {
              final items = (snapshot.data ?? []).where((item) => item.category == category).toList();
              if (items.isEmpty) {
                return const Center(child: Text('No items in this category.', style: TextStyle(color: Colors.white)));
              }
              return ListView.builder(
                itemCount: items.length,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final expProgress = ExpirationProgress.of(item.expirationDate);

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          label: 'Pantry item: ${item.name}, quantity ${item.quantity}, expires ${item.expirationDate.toLocal().toString().split(' ')[0]}',
                          button: true,
                          child: Tooltip(
                            message: 'Tap to view or edit ${item.name}',
                            child: ListTile(
                              title: Text(item.name, style: const TextStyle(color: Color(0xFF003366))),
                              subtitle: Text('Expires: ${item.expirationDate.toLocal().toString().split(' ')[0]}', style: const TextStyle(color: Color(0xFF003366))),
                              trailing: Text('Qty: ${item.quantity} ${item.unit}', style: const TextStyle(color: Color(0xFF003366))),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => ItemDetailScreen(item: item),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: LinearProgressIndicator(
                            value: expProgress.value,
                            minHeight: 16,
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(expProgress.color),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

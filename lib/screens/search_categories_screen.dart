import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pantry_provider.dart';
import '../models/pantry_item.dart';
import 'item_detail_screen.dart';

class SearchCategoriesScreen extends StatefulWidget {
  const SearchCategoriesScreen({super.key});

  @override
  State<SearchCategoriesScreen> createState() => _SearchCategoriesScreenState();
}

class _SearchCategoriesScreenState extends State<SearchCategoriesScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF002244),
        centerTitle: true,
        title: Container(
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white24),
          ),
          child: Row(
            children: [
              const SizedBox(width: 8),
              const Icon(Icons.search, color: Colors.white70),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  autofocus: true,
                  cursorColor: Colors.yellowAccent,
                  cursorWidth: 3.0,
                  cursorRadius: const Radius.circular(2),
                  decoration: const InputDecoration(
                    hintText: 'Search items or categories',
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.white70),
                  ),
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  onChanged: (v) => setState(() => _query = v.trim()),
                ),
              ),
              if (_query.isNotEmpty) ...[
                IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white70),
                  onPressed: () => setState(() => _query = ''),
                ),
              ],
            ],
          ),
        ),
      ),
      backgroundColor: const Color(0xFF002244),
      body: Consumer<PantryProvider>(
        builder: (context, provider, child) {
          return StreamBuilder<List<PantryItem>>(
            stream: provider.itemsStream,
            builder: (context, snapshot) {
              final items = snapshot.data ?? [];
              final filtered = items.where((item) {
                final q = _query.toLowerCase();
                return item.name.toLowerCase().contains(q) || item.category.toLowerCase().contains(q);
              }).toList();

              if (filtered.isEmpty) {
                return const Center(child: Text('No matches', style: TextStyle(color: Colors.white)));
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final item = filtered[index];
                  return GestureDetector(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => ItemDetailScreen(item: item))),
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.name, style: const TextStyle(color: Color(0xFF003366), fontSize: 18, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  Text('${item.category} • Expires: ${item.expirationDate.toLocal().toString().split(' ')[0]}', style: const TextStyle(color: Color(0xFF003366), fontSize: 14)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('${item.quantity} ${item.unit}', style: const TextStyle(color: Color(0xFF003366), fontSize: 16)),
                          ],
                        ),
                      ),
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

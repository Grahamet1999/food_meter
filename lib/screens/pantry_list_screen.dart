import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pantry_provider.dart';
import '../models/pantry_item.dart';
import 'category_detail_screen.dart';
import 'item_detail_screen.dart';
import 'search_categories_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'add_item_screen.dart';
import 'recipe_suggestions_screen.dart';
import 'ingredient_picker_screen.dart';
import '../utils/expiration_progress.dart';

/// Main screen displaying the list of pantry items grouped by category.
/// 
/// Each category is shown as an expandable section. Each item displays its name,
/// expiration date, quantity, and a progress bar that shrinks as the expiration date approaches.
class PantryListScreen extends StatefulWidget {
  const PantryListScreen({super.key});

  @override
  State<PantryListScreen> createState() => _PantryListScreenState();
}

class _PantryListScreenState extends State<PantryListScreen> {
  String? expandedCategory;
  PantryItem? highlightedItem;
  final scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pantry Items'),
        backgroundColor: const Color(0xFF002244),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.forum, color: Colors.white),
          tooltip: 'Join our Discord – report bugs & give feedback',
          onPressed: () async {
            final uri = Uri.parse('https://discord.gg/bEMFUTGWbP');
            // Discord invite links redirect through a deep-link attribution
            // URL (discord://...) that an in-app WebView can't handle, so
            // this must open externally (Discord app or the device browser).
            final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
            if (!launched && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Could not open link on this device.')),
              );
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.restaurant_menu),
            tooltip: 'Recipe Ideas',
            onPressed: () => _showRecipeModeDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'About',
            onPressed: () {
              showAboutDialog(
                context: context,
                applicationName: 'Food Meter',
                applicationVersion: '0.1.1',
                applicationLegalese: '© 2026 OOSSHH. All rights reserved.',
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      backgroundColor: const Color(0xFF002244),
      body: Consumer<PantryProvider>(
        builder: (context, provider, child) {
          return StreamBuilder<List<PantryItem>>(
            stream: provider.itemsStream,
            builder: (context, snapshot) {
              final items = snapshot.data ?? [];
              final Map<String, List<PantryItem>> categoryMap = {};
              for (var item in items) {
                categoryMap.putIfAbsent(item.category, () => []).add(item);
              }
              if (items.isEmpty) {
                return const Center(child: Text('No items added yet.', style: TextStyle(color: Colors.white, fontSize: 18, fontFamily: 'Arial')));
              }
              return ListView(
                controller: scrollController,
                children: [
                  for (var entry in categoryMap.entries)
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3E206D),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          key: PageStorageKey(entry.key),
                          initiallyExpanded: expandedCategory == entry.key,
                          onExpansionChanged: (expanded) {
                            setState(() {
                              expandedCategory = expanded ? entry.key : null;
                            });
                          },
                          title: Text(
                            entry.key,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontSize: 22, fontFamily: 'Arial'),
                          ),
                          collapsedBackgroundColor: Colors.transparent,
                          backgroundColor: Colors.transparent,
                          tilePadding: const EdgeInsets.symmetric(horizontal: 16.0),
                          childrenPadding: EdgeInsets.zero,
                          iconColor: Colors.white,
                          collapsedIconColor: Colors.white,
                          children: [
                            for (var item in (() {
                              final sorted = List<PantryItem>.from(entry.value);
                              sorted.sort((a, b) => a.expirationDate.compareTo(b.expirationDate));
                              return sorted.take(5);
                            })())
                              Builder(
                                builder: (context) {
                                  final expProgress = ExpirationProgress.of(item.expirationDate);
                                  return Semantics(
                                    label: 'Pantry item: ${item.name}, quantity ${item.quantity}, expires ${item.expirationDate.toLocal().toString().split(' ')[0]}',
                                    button: true,
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 500),
                                      decoration: BoxDecoration(
                                        color: highlightedItem == item ? Colors.yellow[200] : Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: highlightedItem == item
                                            ? Border.all(color: Colors.orange, width: 3)
                                            : null,
                                      ),
                                      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Tooltip(
                                            message: 'Tap to view or edit ${item.name}',
                                            child: ListTile(
                                              title: Text(item.name, style: const TextStyle(color: Color(0xFF003366), fontSize: 18, fontFamily: 'Arial')),
                                              subtitle: Text('Expires: ${item.expirationDate.toLocal().toString().split(' ')[0]}', style: const TextStyle(color: Color(0xFF003366), fontSize: 16, fontFamily: 'Arial')),
                                              trailing: Text('Qty: ${item.quantity} ${item.unit}', style: const TextStyle(color: Color(0xFF003366), fontSize: 16, fontFamily: 'Arial')),
                                              onTap: () {
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder: (context) => ItemDetailScreen(item: item),
                                                  ),
                                                );
                                              },
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
                                    ),
                                  );
                                },
                              ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Center(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1B5E20),
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => CategoryDetailScreen(
                                          category: entry.key,
                                        ),
                                      ),
                                    );
                                  },
                                  child: const Text('View All'),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            FloatingActionButton(
              heroTag: 'search',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SearchCategoriesScreen()),
                );
              },
              backgroundColor: Colors.blueGrey,
              tooltip: 'Search',
              child: const Icon(Icons.search),
            ),
            FloatingActionButton(
              heroTag: 'add',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddItemScreen()),
                );
              },
              backgroundColor: const Color(0xFF1B5E20),
              tooltip: 'Add Item',
              child: const Icon(Icons.add),
            ),
          ],
        ),
      ),
    );
  }

  void _showRecipeModeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF002244),
        title: const Text('Get Recipe Ideas', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Build a recipe from items expiring soonest, or pick your own ingredients?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const IngredientPickerScreen()),
              );
            },
            child: const Text('Choose ingredients'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B5E20),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RecipeSuggestionsScreen()),
              );
            },
            child: const Text('Use expiring items'),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/pantry_item.dart';
import '../providers/pantry_provider.dart';
import '../services/recipe_service.dart';

/// Screen showing recipe ideas generated from the user's current pantry
/// contents, weighted toward items expiring soonest.
class RecipeSuggestionsScreen extends StatefulWidget {
  const RecipeSuggestionsScreen({super.key});

  @override
  State<RecipeSuggestionsScreen> createState() => _RecipeSuggestionsScreenState();
}

class _RecipeSuggestionsScreenState extends State<RecipeSuggestionsScreen> {
  Future<List<RecipeSuggestion>>? _future;
  List<PantryItem> _latestItems = const [];

  void _fetch(List<PantryItem> items) {
    setState(() {
      _latestItems = items;
      _future = RecipeService.suggest(items);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipe Ideas'),
        backgroundColor: const Color(0xFF002244),
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFF002244),
      body: Consumer<PantryProvider>(
        builder: (context, provider, child) {
          return StreamBuilder<List<PantryItem>>(
            stream: provider.itemsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final items = snapshot.data ?? [];
              if (items.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Text(
                      'Add some items to your pantry first, then come back here for recipe ideas.',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              if (_future == null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && _future == null) _fetch(items);
                });
                return const Center(child: CircularProgressIndicator());
              }
              return FutureBuilder<List<RecipeSuggestion>>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Thinking of recipes…', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    );
                  }
                  if (snap.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${snap.error}',
                              style: const TextStyle(color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _fetch(_latestItems),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1B5E20),
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Try Again'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  final recipes = snap.data ?? [];
                  if (recipes.isEmpty) {
                    return const Center(
                      child: Text('No recipe ideas right now.', style: TextStyle(color: Colors.white)),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: recipes.length,
                    itemBuilder: (context, index) => _RecipeCard(recipe: recipes[index]),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: _future == null
          ? null
          : FloatingActionButton(
              onPressed: () => _fetch(_latestItems),
              backgroundColor: const Color(0xFF1B5E20),
              tooltip: 'Get new ideas',
              child: const Icon(Icons.refresh),
            ),
    );
  }
}

class _RecipeCard extends StatelessWidget {
  final RecipeSuggestion recipe;

  const _RecipeCard({required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      color: Colors.white,
      child: ExpansionTile(
        title: Text(
          recipe.title,
          style: const TextStyle(color: Color(0xFF003366), fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: recipe.usesExpiringItems.isEmpty
            ? null
            : Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: recipe.usesExpiringItems
                      .map((name) => Chip(
                            label: Text(name, style: const TextStyle(fontSize: 12)),
                            backgroundColor: Colors.orange[100],
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ))
                      .toList(),
                ),
              ),
        iconColor: const Color(0xFF003366),
        collapsedIconColor: const Color(0xFF003366),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (recipe.ingredientsUsed.isNotEmpty) ...[
                  const Text('From your pantry', style: TextStyle(color: Color(0xFF003366), fontWeight: FontWeight.bold)),
                  Text(recipe.ingredientsUsed.join(', '), style: const TextStyle(color: Color(0xFF003366))),
                  const SizedBox(height: 8),
                ],
                if (recipe.ingredientsNeeded.isNotEmpty) ...[
                  const Text("You'll also need", style: TextStyle(color: Color(0xFF003366), fontWeight: FontWeight.bold)),
                  Text(recipe.ingredientsNeeded.join(', '), style: const TextStyle(color: Color(0xFF003366))),
                  const SizedBox(height: 8),
                ],
                const Text('Instructions', style: TextStyle(color: Color(0xFF003366), fontWeight: FontWeight.bold)),
                Text(recipe.instructions, style: const TextStyle(color: Color(0xFF003366))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:cloud_functions/cloud_functions.dart';
import '../models/pantry_item.dart';

/// A recipe suggested from the user's current pantry contents.
class RecipeSuggestion {
  final String title;
  final int? servings;
  final int? prepTimeMinutes;
  final int? cookTimeMinutes;
  final List<String> usesExpiringItems;
  final List<String> ingredientsUsed;
  final List<String> ingredientsNeeded;
  final List<String> instructions;

  const RecipeSuggestion({
    required this.title,
    this.servings,
    this.prepTimeMinutes,
    this.cookTimeMinutes,
    required this.usesExpiringItems,
    required this.ingredientsUsed,
    required this.ingredientsNeeded,
    required this.instructions,
  });

  factory RecipeSuggestion.fromJson(Map<String, dynamic> json) {
    List<String> stringList(dynamic value) =>
        (value as List<dynamic>? ?? const []).map((e) => e.toString()).toList();
    return RecipeSuggestion(
      title: json['title'] as String? ?? 'Untitled recipe',
      servings: (json['servings'] as num?)?.toInt(),
      prepTimeMinutes: (json['prepTimeMinutes'] as num?)?.toInt(),
      cookTimeMinutes: (json['cookTimeMinutes'] as num?)?.toInt(),
      usesExpiringItems: stringList(json['usesExpiringItems']),
      ingredientsUsed: stringList(json['ingredientsUsed']),
      ingredientsNeeded: stringList(json['ingredientsNeeded']),
      instructions: stringList(json['instructions']),
    );
  }
}

/// Calls the `suggestRecipes` Cloud Function to get recipe ideas from a
/// list of pantry items, weighted toward items expiring soonest.
class RecipeService {
  /// Cap on items sent to the Cloud Function. Large pantries (many storage
  /// locations, dozens of items each) can exceed the server's item limit, so
  /// only the soonest-expiring items are sent — they're the most relevant
  /// for "use it before it goes bad" suggestions anyway.
  static const int _maxItems = 60;

  static Future<List<RecipeSuggestion>> suggest(List<PantryItem> items) async {
    final now = DateTime.now();
    final sorted = List<PantryItem>.from(items)
      ..sort((a, b) => a.expirationDate.compareTo(b.expirationDate));
    final payload = sorted
        .take(_maxItems)
        .map((item) => {
              'name': item.name,
              'daysUntilExpiration': item.expirationDate.difference(now).inDays,
              'quantity': item.quantity,
              'unit': item.unit,
            })
        .toList();

    try {
      final callable = FirebaseFunctions.instance.httpsCallable('suggestRecipes');
      final result = await callable.call<Map<String, dynamic>>({'items': payload});
      final recipes = (result.data['recipes'] as List<dynamic>? ?? const [])
          .map((r) => RecipeSuggestion.fromJson(Map<String, dynamic>.from(r as Map)))
          .toList();
      return recipes;
    } on FirebaseFunctionsException catch (e) {
      throw Exception(e.message ?? 'Could not get recipe suggestions. Please try again.');
    }
  }
}

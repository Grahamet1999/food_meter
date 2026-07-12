import 'package:cloud_functions/cloud_functions.dart';
import '../models/pantry_item.dart';

/// A recipe suggested from the user's current pantry contents.
class RecipeSuggestion {
  final String title;
  final List<String> usesExpiringItems;
  final List<String> ingredientsUsed;
  final List<String> ingredientsNeeded;
  final String instructions;

  const RecipeSuggestion({
    required this.title,
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
      usesExpiringItems: stringList(json['usesExpiringItems']),
      ingredientsUsed: stringList(json['ingredientsUsed']),
      ingredientsNeeded: stringList(json['ingredientsNeeded']),
      instructions: json['instructions'] as String? ?? '',
    );
  }
}

/// Calls the `suggestRecipes` Cloud Function to get recipe ideas from a
/// list of pantry items, weighted toward items expiring soonest.
class RecipeService {
  static Future<List<RecipeSuggestion>> suggest(List<PantryItem> items) async {
    final now = DateTime.now();
    final payload = items
        .map((item) => {
              'name': item.name,
              'daysUntilExpiration': item.expirationDate.difference(now).inDays,
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

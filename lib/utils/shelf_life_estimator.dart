/// Estimates a sensible default expiration date for a new pantry item.
///
/// This doesn't try to enumerate every food a person might type in — that
/// list is effectively infinite. Instead it leans on two much smaller,
/// well-understood vocabularies: the handful of ways people phrase storage
/// locations (fridge, freezer, spice drawer, ...) and a short list of common
/// perishables whose shelf life varies too much for a category guess alone
/// (milk vs. mustard, both plausibly stored in "Fridge"). Anything that
/// matches neither falls back to the same flat 30-day default the app has
/// always used, so this is a strict improvement, never worse than before.
class ShelfLifeEstimate {
  final int days;
  /// A short label describing why this estimate was chosen (e.g. "dairy",
  /// "frozen items"), or null when nothing matched and the flat default
  /// was used.
  final String? reason;

  const ShelfLifeEstimate(this.days, this.reason);
}

class ShelfLifeEstimator {
  static const int _defaultDays = 30;

  // Checked first, and wins over everything else: freezing dramatically
  // extends shelf life for nearly all food, so an item-specific "goes bad
  // in 2 days" rule below would be wrong for the same item once frozen.
  static const (List<String>, int, String) _freezerRule = (['freez'], 120, 'frozen items');

  // (keywords to match against the item name, days, label)
  static const List<(List<String>, int, String)> _itemKeywords = [
    (['milk'], 7, 'dairy'),
    (['yogurt', 'yoghurt'], 14, 'dairy'),
    (['egg'], 28, 'eggs'),
    (['butter'], 60, 'dairy'),
    (['cream cheese'], 14, 'dairy'),
    (['sour cream'], 21, 'dairy'),
    (['cottage cheese'], 10, 'dairy'),
    (['cheese'], 21, 'dairy'),
    (['chicken', 'turkey', 'poultry'], 2, 'raw poultry'),
    (['ground beef', 'ground pork', 'ground turkey', 'mince'], 2, 'ground meat'),
    (['steak', 'beef', 'pork', 'lamb'], 4, 'raw meat'),
    (['bacon'], 7, 'cured meat'),
    (['deli meat', 'lunch meat', 'cold cuts'], 5, 'deli meat'),
    (['fish', 'salmon', 'shrimp', 'seafood'], 2, 'seafood'),
    (['lettuce', 'spinach', 'salad greens', 'greens'], 7, 'leafy greens'),
    (['berries', 'strawberr', 'raspberr', 'blueberr'], 5, 'berries'),
    (['banana'], 5, 'produce'),
    (['tomato'], 7, 'produce'),
    (['bread', 'bun', 'roll'], 6, 'bakery'),
    (['tofu'], 7, 'refrigerated'),
    (['hummus'], 10, 'refrigerated dip'),
    (['leftover'], 4, 'leftovers'),
    (['juice'], 10, 'refrigerated'),
  ];

  // (keywords to match against the storage category, days, label)
  static const List<(List<String>, int, String)> _categoryKeywords = [
    (['fridge', 'refrigerat'], 14, 'refrigerated items'),
    (['spice', 'season'], 730, 'dried spices'),
    (['wine', 'cellar', 'liquor', 'bar'], 1095, 'long-lasting items'),
    (['cupboard', 'pantry', 'shelf', 'stash', 'drawer'], 180, 'dry pantry storage'),
  ];

  static ShelfLifeEstimate estimate({required String name, required String category}) {
    final normalizedName = name.trim().toLowerCase();
    final normalizedCategory = category.trim().toLowerCase();

    if (_matchesAny(normalizedCategory, _freezerRule.$1)) {
      return ShelfLifeEstimate(_freezerRule.$2, _freezerRule.$3);
    }

    if (normalizedName.isNotEmpty) {
      for (final rule in _itemKeywords) {
        if (_matchesAny(normalizedName, rule.$1)) {
          return ShelfLifeEstimate(rule.$2, rule.$3);
        }
      }
    }

    if (normalizedCategory.isNotEmpty) {
      for (final rule in _categoryKeywords) {
        if (_matchesAny(normalizedCategory, rule.$1)) {
          return ShelfLifeEstimate(rule.$2, rule.$3);
        }
      }
    }

    return const ShelfLifeEstimate(_defaultDays, null);
  }

  static bool _matchesAny(String haystack, List<String> keywords) => keywords.any((k) => haystack.contains(k));
}

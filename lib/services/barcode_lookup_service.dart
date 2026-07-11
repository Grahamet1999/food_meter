import 'dart:convert';
import 'package:http/http.dart' as http;

/// Product data resolved from a scanned barcode.
class ScannedProduct {
  final String name;
  final double? quantity;
  final String? unit;

  const ScannedProduct({required this.name, this.quantity, this.unit});
}

/// Looks up product info for a scanned barcode via the Open Food Facts API.
class BarcodeLookupService {
  // Maps recognized raw unit spellings to a (multiplier, canonical unit) pair
  // — most pass through as-is, but Open Food Facts' European-heavy data
  // frequently uses cl/dl, which this app's unit list doesn't have, so those
  // are converted to ml instead of being dropped. Exact match only — a
  // prefix match would also wrongly accept e.g. "gal" (gallon) as "g" (grams).
  static const _unitConversions = {
    'g': (1.0, 'g'), 'gr': (1.0, 'g'), 'grams': (1.0, 'g'),
    'kg': (1.0, 'kg'), 'kgs': (1.0, 'kg'), 'kilograms': (1.0, 'kg'),
    'ml': (1.0, 'ml'), 'milliliters': (1.0, 'ml'), 'millilitres': (1.0, 'ml'),
    'cl': (10.0, 'ml'), 'centiliters': (10.0, 'ml'), 'centilitres': (10.0, 'ml'),
    'dl': (100.0, 'ml'), 'deciliters': (100.0, 'ml'), 'decilitres': (100.0, 'ml'),
    'l': (1.0, 'L'), 'lt': (1.0, 'L'), 'liters': (1.0, 'L'), 'litres': (1.0, 'L'),
    'oz': (1.0, 'oz'), 'ounces': (1.0, 'oz'),
    'lb': (1.0, 'lb'), 'lbs': (1.0, 'lb'), 'pounds': (1.0, 'lb'),
  };

  /// Returns the product for [barcode], or null if not found or the lookup fails.
  static Future<ScannedProduct?> lookup(String barcode) async {
    try {
      final uri = Uri.parse(
        'https://world.openfoodfacts.org/api/v2/product/$barcode.json?fields=product_name,quantity',
      );
      final response = await http
          .get(uri, headers: {'User-Agent': 'FoodMeter - Flutter - Version 0.1.1'})
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['status'] != 1) return null;

      final product = data['product'] as Map<String, dynamic>?;
      final name = (product?['product_name'] as String?)?.trim();
      if (name == null || name.isEmpty) return null;

      final parsed = _parseQuantity(product?['quantity'] as String?);
      return ScannedProduct(name: name, quantity: parsed?.$1, unit: parsed?.$2);
    } catch (_) {
      return null;
    }
  }

  /// Best-effort parse of Open Food Facts' free-text quantity (e.g. "500 g", "1L").
  /// Returns null if it doesn't cleanly match a number followed by a known unit.
  static (double, String)? _parseQuantity(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final match = RegExp(r'^\s*([\d.,]+)\s*([a-zA-Z]+)').firstMatch(raw);
    if (match == null) return null;

    final value = double.tryParse(match.group(1)!.replaceAll(',', '.'));
    if (value == null) return null;

    final conversion = _unitConversions[match.group(2)!.toLowerCase()];
    if (conversion == null) return null;

    final (multiplier, canonicalUnit) = conversion;
    return (value * multiplier, canonicalUnit);
  }
}

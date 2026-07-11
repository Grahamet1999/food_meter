/// Represents an item stored in a pantry, fridge, or similar location.
/// Includes details such as name, quantity, expiration date, and category.
class PantryItem {
  /// Unique identifier for the item.
  final String id;
  /// Name of the item (e.g., "Milk").
  final String name;
  /// Quantity of the item (e.g., number of units, can be decimal).
  final double quantity;
  /// Unit of the item (e.g., g, kg, ml, pcs).
  final String unit;
  /// Expiration date of the item.
  final DateTime expirationDate;
  /// Category of the item (e.g., "Pantry", "Fridge").
  final String category;

  /// Creates a [PantryItem] with the given properties.
  PantryItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.expirationDate,
    required this.category,
  });

  /// Returns a copy of this item with updated fields.
  PantryItem copyWith({
    String? id,
    String? name,
    double? quantity,
    String? unit,
    DateTime? expirationDate,
    String? category,
  }) {
    return PantryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      expirationDate: expirationDate ?? this.expirationDate,
      category: category ?? this.category,
    );
  }

  /// Converts this item to a map for storage or serialization.

    /// Converts this item to a map for Firestore storage.
    /// Converts this item to a map for Firestore storage.
    ///
    /// Used by PantryProvider to upload item data to Firestore.
    /// All fields are serialized as strings or numbers for compatibility.
    Map<String, dynamic> toFirestore() {
      return {
        'id': id,
        'name': name,
        'quantity': quantity,
        'unit': unit,
        'expirationDate': expirationDate.toIso8601String(),
        'category': category,
      };
    }

  /// Creates a [PantryItem] from a map (e.g., from storage or network).
    factory PantryItem.fromMap(Map<String, dynamic> map) {
      return PantryItem(
        id: map['id'] as String,
        name: map['name'] as String,
        quantity: (map['quantity'] as num).toDouble(),
        unit: map['unit'] as String? ?? 'pcs',
        expirationDate: DateTime.parse(map['expirationDate'] as String),
        category: map['category'] as String,
      );
    }

    /// Creates a [PantryItem] from a Firestore document snapshot.
    /// Creates a [PantryItem] from a Firestore document snapshot.
    ///
    /// Used by PantryProvider to deserialize item data from Firestore.
    /// Accepts a DocumentSnapshot or QueryDocumentSnapshot.
    /// All fields are parsed from the Firestore document data.
    static PantryItem fromFirestore(dynamic doc) {
      final data = doc.data() as Map<String, dynamic>;
      return PantryItem(
        id: data['id'] as String,
        name: data['name'] as String,
        quantity: (data['quantity'] as num).toDouble(),
        unit: data['unit'] as String? ?? 'pcs',
        expirationDate: DateTime.parse(data['expirationDate'] as String),
        category: data['category'] as String,
      );
    }
}

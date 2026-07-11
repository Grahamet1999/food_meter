import 'package:flutter_test/flutter_test.dart';
import 'package:food_meter/models/pantry_item.dart';
import 'package:food_meter/providers/pantry_provider.dart';
// For real integration, use a test Firebase project or mock Firestore.

void main() {
  group('PantryProvider', () {
    late PantryProvider provider;

    setUp(() async {
      provider = PantryProvider();
      await provider.clear();
    });

    test('addItem adds a new item', () async {
      final item = PantryItem(
        id: '1',
        name: 'Milk',
        quantity: 1,
        unit: 'pcs',
        expirationDate: DateTime(2025, 9, 20),
        category: 'Fridge',
      );
      await provider.addItem(item);
      await expectLater(
        provider.itemsStream,
        emits(predicate<List<PantryItem>>((items) =>
          items.length == 1 && items.first.name == 'Milk')),
      );
    });

    test('addItem merges quantity for duplicate', () async {
      final item1 = PantryItem(
        id: '1',
        name: 'Bread',
        quantity: 1,
        unit: 'pcs',
        expirationDate: DateTime(2025, 9, 17),
        category: 'Pantry',
      );
      final item2 = PantryItem(
        id: '2',
        name: 'Bread',
        quantity: 2,
        unit: 'pcs',
        expirationDate: DateTime(2025, 9, 17),
        category: 'Pantry',
      );
      await provider.addItem(item1);
      await provider.addItem(item2);
      await expectLater(
        provider.itemsStream,
        emits(predicate<List<PantryItem>>((items) =>
          items.length == 1 && items.first.quantity == 3)),
      );
    });

    test('removeItem removes by id', () async {
      final item = PantryItem(
        id: '1',
        name: 'Eggs',
        quantity: 12,
        unit: 'pcs',
        expirationDate: DateTime(2025, 9, 10),
        category: 'Fridge',
      );
      await provider.addItem(item);
      // addItem assigns its own Firestore-generated id, so look it up rather
      // than assuming the id passed in stuck.
      final added = (await provider.itemsStream.first).first;
      await provider.removeItem(added.id);
      await expectLater(
        provider.itemsStream,
        emits(predicate<List<PantryItem>>((items) => items.isEmpty)),
      );
    });

    test('updateItem updates fields', () async {
      final item = PantryItem(
        id: '1',
        name: 'Milk',
        quantity: 1,
        unit: 'pcs',
        expirationDate: DateTime(2025, 9, 20),
        category: 'Fridge',
      );
      await provider.addItem(item);
      final added = (await provider.itemsStream.first).first;
      final updated = added.copyWith(quantity: 5);
      await provider.updateItem(added.id, updated);
      await expectLater(
        provider.itemsStream,
        emits(predicate<List<PantryItem>>((items) =>
          items.first.quantity == 5)),
      );
    });
  });
}

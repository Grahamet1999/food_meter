import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/pantry_item.dart';

/// Provider for managing pantry items in Firestore.
///
/// This provider uses Cloud Firestore to store pantry items for each authenticated user.
/// All CRUD operations (add, update, remove, get) interact directly with Firestore,
/// ensuring data is synced across devices and available online.
///
/// Firestore structure:
///   users/{uid}/pantry_items/{itemId}
///
/// - Each user has their own pantry_items subcollection.
/// - Items are stored as documents with fields: id, name, quantity, expirationDate, category.
///
/// Usage:
///   - Use [itemsStream] to listen for real-time updates to pantry items.
///   - Use [addItem], [updateItem], [removeItem], [getItemById], [clear] for CRUD operations.
class PantryProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Returns a stream of pantry items for the current user.
  Stream<List<PantryItem>> get itemsStream {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return _firestore
      .collection('users')
      .doc(uid)
      .collection('pantry_items')
      .orderBy('expirationDate')
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => PantryItem.fromFirestore(doc)).toList());
  }

  /// Adds a new [PantryItem] to Firestore. If an item with the same name, category, and expiration date exists, adds to its quantity instead.
  Future<void> addItem(PantryItem item) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final itemsRef = _firestore.collection('users').doc(uid).collection('pantry_items');
    final query = await itemsRef
      .where('name', isEqualTo: item.name)
      .where('category', isEqualTo: item.category)
      .where('expirationDate', isEqualTo: item.expirationDate.toIso8601String())
      .get();
    if (query.docs.isNotEmpty) {
      final doc = query.docs.first;
      final existing = PantryItem.fromFirestore(doc);
      await doc.reference.update({'quantity': existing.quantity + item.quantity});
    } else {
      final docRef = itemsRef.doc();
      await docRef.set(item.copyWith(id: docRef.id).toFirestore());
    }
    notifyListeners();
  }

  /// Updates an existing item by [id] in Firestore with [newItem] and notifies listeners.
  Future<void> updateItem(String id, PantryItem newItem) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final docRef = _firestore.collection('users').doc(uid).collection('pantry_items').doc(id);
    await docRef.set(newItem.toFirestore());
    notifyListeners();
  }

  /// Removes the item with the given [id] from Firestore and notifies listeners.
  Future<void> removeItem(String id) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final docRef = _firestore.collection('users').doc(uid).collection('pantry_items').doc(id);
    await docRef.delete();
    notifyListeners();
  }

  /// Returns the item with the given [id] from Firestore, or null if not found.
  Future<PantryItem?> getItemById(String id) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    final doc = await _firestore.collection('users').doc(uid).collection('pantry_items').doc(id).get();
    if (!doc.exists) return null;
    return PantryItem.fromFirestore(doc);
  }

  /// Removes all items from Firestore for the current user and notifies listeners.
  Future<void> clear() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final itemsRef = _firestore.collection('users').doc(uid).collection('pantry_items');
    final snapshot = await itemsRef.get();
    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
    notifyListeners();
  }
}

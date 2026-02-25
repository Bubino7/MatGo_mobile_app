import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_models/shared_models.dart';

/// Globálne kategórie – každá stavebnína môže priradiť kategóriu produktu. Kolekcia [Collections.categories].
class CategoriesService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Všetky kategórie (globálne), zoradené podľa názvu.
  Stream<List<Map<String, dynamic>>> categoriesStream() {
    return _firestore.collection(Collections.categories).snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      list.sort((a, b) => ((a['name'] ?? '') as String).compareTo((b['name'] ?? '') as String));
      return list;
    });
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    final snapshot = await _firestore.collection(Collections.categories).get();
    final list = snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
    list.sort((a, b) => ((a['name'] ?? '') as String).compareTo((b['name'] ?? '') as String));
    return list;
  }

  /// Vytvorí novú globálnu kategóriu (productIds prázdne).
  Future<String> addCategory(String name) async {
    final ref = _firestore.collection(Collections.categories).doc();
    final now = FieldValue.serverTimestamp();
    await ref.set({
      'name': name.trim(),
      'productIds': [],
      'createdAt': now,
      'updatedAt': now,
    });
    return ref.id;
  }

  Future<void> updateCategory(String categoryId, String name) async {
    await _firestore.collection(Collections.categories).doc(categoryId).update({
      'name': name.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteCategory(String categoryId) async {
    await _firestore.collection(Collections.categories).doc(categoryId).delete();
  }

  /// Pridá produkt do kategórie (pri vytvorení alebo zmene kategórie produktu).
  /// Ak kategória ešte nemá pole productIds (starý dokument so shopIds), doplní ho cez merge.
  Future<void> addProductToCategory(String categoryId, String productId) async {
    final ref = _firestore.collection(Collections.categories).doc(categoryId);
    final doc = await ref.get();
    if (!doc.exists) return;
    final data = doc.data();
    final hasProductIds = data?['productIds'] is List;
    if (hasProductIds) {
      await ref.update({
        'productIds': FieldValue.arrayUnion([productId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await ref.set({
        'productIds': [productId],
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  /// Odstráni produkt z kategórie (pri zmene kategórie alebo zmazaní produktu).
  Future<void> removeProductFromCategory(String categoryId, String productId) async {
    await _firestore.collection(Collections.categories).doc(categoryId).update({
      'productIds': FieldValue.arrayRemove([productId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

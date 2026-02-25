import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_models/shared_models.dart';

/// Správa stavebnín – Firestore kolekcia [Collections.shops]. ID dokumentu vygeneruje Firebase, slug = id.
/// Obrázok: ukladá sa ako data URL (base64) v imageUrl – bez Firebase Storage.
class ShopsService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Pridá stavebnínu. ID dokumentu vygeneruje Firebase, slug sa rovná id. Vráti nové id.
  Future<String> addShop(String name, {String? address, String? imageUrl}) async {
    final ref = _firestore.collection(Collections.shops).doc();
    final id = ref.id;
    final data = <String, dynamic>{
      'name': name.trim(),
      'slug': id,
      'createdAt': FieldValue.serverTimestamp(),
    };
    if (address != null && address.trim().isNotEmpty) data['address'] = address.trim();
    if (imageUrl != null && imageUrl.isNotEmpty) data['imageUrl'] = imageUrl;
    await ref.set(data);
    return id;
  }

  /// Aktualizuje stavebnínu. Slug sa nemení (= ID dokumentu).
  Future<void> updateShop(String docId, {String? name, String? address, String? imageUrl}) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (address != null) updates['address'] = address;
    if (imageUrl != null) updates['imageUrl'] = imageUrl;
    if (updates.isEmpty) return;
    await _firestore.collection(Collections.shops).doc(docId).update(updates);
  }

  /// Pridá užívateľa (uid) do poľa managedBy stavebnín. Obojsmerné prepojenie s user.managedShopIds.
  Future<void> addManagedBy(String shopId, String uid) async {
    await _firestore.collection(Collections.shops).doc(shopId).update({
      'managedBy': FieldValue.arrayUnion([uid]),
    });
  }

  /// Odstráni užívateľa (uid) z poľa managedBy stavebnín.
  Future<void> removeManagedBy(String shopId, String uid) async {
    await _firestore.collection(Collections.shops).doc(shopId).update({
      'managedBy': FieldValue.arrayRemove([uid]),
    });
  }

  /// Načíta jednu stavebnínu podľa id (pre shop portál).
  Future<Map<String, dynamic>?> getShop(String shopId) async {
    final doc = await _firestore.collection(Collections.shops).doc(shopId).get();
    if (doc.data() == null) return null;
    final data = doc.data()!;
    data['id'] = doc.id;
    return data;
  }

  /// Stream zoznamu stavebnín z Firestore (pre stránku Správa stavebnín).
  Stream<List<Map<String, dynamic>>> get shopsStream {
    return _firestore.collection(Collections.shops).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  /// Stavebniny ako id + name (pre dropdown managedShopIds v užívateľoch).
  Stream<List<Map<String, String>>> get firestoreShopsStream {
    return _firestore.collection(Collections.shops).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {'id': doc.id, 'name': (data['name'] ?? doc.id) as String};
      }).toList();
    });
  }
}

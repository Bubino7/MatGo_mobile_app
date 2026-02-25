import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_models/shared_models.dart';

import 'categories_service.dart';

/// Produkty na predaj. Kolekcia [Collections.products]: name, price, imageUrl?, shopId, createdAt, updatedAt, keywords, categoryId?.
class ProductsService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Map<String, dynamic>>> productsStream(String shopId) {
    return _firestore
        .collection(Collections.products)
        .where('shopId', isEqualTo: shopId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      list.sort((a, b) {
        final at = a['createdAt'];
        final bt = b['createdAt'];
        if (at == null && bt == null) return 0;
        if (at == null) return 1;
        if (bt == null) return -1;
        final am = at is Timestamp ? at.millisecondsSinceEpoch : 0;
        final bm = bt is Timestamp ? bt.millisecondsSinceEpoch : 0;
        return bm.compareTo(am);
      });
      return list;
    });
  }

  Future<String> addProduct({
    required String shopId,
    required String name,
    required double price,
    String? unit,
    String? imageUrl,
    String? categoryId,
  }) async {
    final ref = _firestore.collection(Collections.products).doc();
    final now = FieldValue.serverTimestamp();
    await ref.set({
      'shopId': shopId,
      'name': name.trim(),
      'price': price,
      'createdAt': now,
      'updatedAt': now,
      'keywords': MatGoUtils.searchKeywordsFromName(name),
      if (unit != null && unit.isNotEmpty) 'unit': unit,
      if (imageUrl != null && imageUrl.isNotEmpty) 'imageUrl': imageUrl,
      if (categoryId != null && categoryId.isNotEmpty) 'categoryId': categoryId,
    });
    if (categoryId != null && categoryId.isNotEmpty) {
      await Get.find<CategoriesService>().addProductToCategory(categoryId, ref.id);
    }
    return ref.id;
  }

  /// [clearImage] true = odstráni obrázok. [imageUrl] nová data URL (ak sme vybrali nový obrázok).
  /// [oldCategoryId] predchádzajúca kategória produktu – pri zmene kategórie sa produkt odstráni zo starej a pridá do novej.
  Future<void> updateProduct(
    String productId, {
    String? name,
    double? price,
    String? unit,
    String? imageUrl,
    bool clearImage = false,
    String? categoryId,
    String? oldCategoryId,
  }) async {
    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (name != null) {
      updates['name'] = name.trim();
      updates['keywords'] = MatGoUtils.searchKeywordsFromName(name);
    }
    if (price != null) updates['price'] = price;
    if (unit != null) updates['unit'] = unit.isEmpty ? FieldValue.delete() : unit;
    if (clearImage) updates['imageUrl'] = FieldValue.delete();
    else if (imageUrl != null) updates['imageUrl'] = imageUrl;
    if (categoryId != null) {
      updates['categoryId'] = categoryId.isEmpty ? FieldValue.delete() : categoryId;
    } else {
      updates['categoryId'] = FieldValue.delete();
    }
    await _firestore.collection(Collections.products).doc(productId).update(updates);

    final newCat = categoryId != null && categoryId.isNotEmpty ? categoryId : null;
    final oldCat = oldCategoryId != null && oldCategoryId.isNotEmpty ? oldCategoryId : null;
    if (oldCat == newCat) return;
    final cats = Get.find<CategoriesService>();
    if (oldCat != null) await cats.removeProductFromCategory(oldCat, productId);
    if (newCat != null) await cats.addProductToCategory(newCat, productId);
  }

  Future<void> deleteProduct(String productId) async {
    final doc = await _firestore.collection(Collections.products).doc(productId).get();
    final categoryId = doc.data()?['categoryId'] as String?;
    await _firestore.collection(Collections.products).doc(productId).delete();
    if (categoryId != null && categoryId.isNotEmpty) {
      await Get.find<CategoriesService>().removeProductFromCategory(categoryId, productId);
    }
  }

}

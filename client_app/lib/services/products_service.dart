import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_models/shared_models.dart';

import 'shops_service.dart';

/// Produkty z Firestore. Kolekcia [Collections.products].
class ProductsService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream produktov danej kategórie. Každá položka má pridané 'shopName' (načítané zo ShopsService).
  Stream<List<Map<String, dynamic>>> productsStreamByCategory(String categoryId) {
    return _firestore
        .collection(Collections.products)
        .where('categoryId', isEqualTo: categoryId)
        .snapshots()
        .asyncMap((snapshot) async {
      final shops = Get.find<ShopsService>();
      final list = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      final shopIds = list.map((p) => p['shopId'] as String?).whereType<String>().toSet();
      final nameByShop = <String, String>{};
      for (final id in shopIds) {
        final shop = await shops.getShop(id);
        nameByShop[id] = (shop?['name'] as String?) ?? id;
      }
      for (final p in list) {
        final sid = p['shopId'] as String?;
        p['shopName'] = sid != null ? nameByShop[sid] ?? sid : '';
      }
      list.sort((a, b) => ((a['name'] ?? '') as String).compareTo((b['name'] ?? '') as String));
      return list;
    });
  }

  /// Vyhľadávanie v produktoch podľa kľúčových slov (keywords). Používa [MatGoUtils.searchKeywordsFromName] a Firestore arrayContainsAny (max 30).
  /// Kľúčové slová kratšie ako 2 znaky sa vynechávajú, aby sa nezhodili produkty len kvôli jednému písmenu (napr. "d" v "do").
  Stream<List<Map<String, dynamic>>> productsStreamBySearch(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return Stream.value([]);
    }
    final keywords = MatGoUtils.searchKeywordsFromName(trimmed)
        .where((k) => k.length >= 2)
        .take(30)
        .toList();
    if (keywords.isEmpty) {
      return Stream.value([]);
    }
    return _firestore
        .collection(Collections.products)
        .where('keywords', arrayContainsAny: keywords)
        .snapshots()
        .asyncMap((snapshot) async {
      final shops = Get.find<ShopsService>();
      final list = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      final shopIds = list.map((p) => p['shopId'] as String?).whereType<String>().toSet();
      final nameByShop = <String, String>{};
      for (final id in shopIds) {
        final shop = await shops.getShop(id);
        nameByShop[id] = (shop?['name'] as String?) ?? id;
      }
      for (final p in list) {
        final sid = p['shopId'] as String?;
        p['shopName'] = sid != null ? nameByShop[sid] ?? sid : '';
      }
      list.sort((a, b) => ((a['name'] ?? '') as String).compareTo((b['name'] ?? '') as String));
      return list;
    });
  }

  /// Produkty jednej stavebnín (pre zoznam v obchode).
  Stream<List<Map<String, dynamic>>> productsStreamByShop(String shopId) {
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
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_models/shared_models.dart';

/// GetX service – Firestore zoznam stavebnín.
/// Registrovať v main.dart: Get.put(ShopsService());
/// Použitie: Get.find<ShopsService>().shopsStream
class ShopsService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream zoznamu stavebnín (name, address, …). Pri chybe vráti prázdny zoznam.
  Stream<List<Map<String, dynamic>>> get shopsStream {
    return _firestore.collection(Collections.shops).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  /// Jedna stavebnína podľa ID (pre zobrazenie názvu pri produktoch).
  Future<Map<String, dynamic>?> getShop(String shopId) async {
    final doc = await _firestore.collection(Collections.shops).doc(shopId).get();
    if (doc.data() == null) return null;
    final data = doc.data()!;
    data['id'] = doc.id;
    return data;
  }
}

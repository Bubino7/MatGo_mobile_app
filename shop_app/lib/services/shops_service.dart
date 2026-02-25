import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_models/shared_models.dart';

class ShopsService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>?> getShop(String shopId) async {
    final doc = await _firestore.collection(Collections.shops).doc(shopId).get();
    if (doc.data() == null) return null;
    final data = doc.data()!;
    data['id'] = doc.id;
    return data;
  }
}

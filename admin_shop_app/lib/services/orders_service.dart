import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_models/shared_models.dart';

/// Správa všetkých objednávok pre admina.
class OrdersService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream všetkých objednávok v systéme.
  Stream<List<Map<String, dynamic>>> get allOrdersStream {
    return _firestore
        .collection(Collections.orders)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      
      // Zoradenie od najnovších
      list.sort((a, b) {
        final aTime = a['createdAt'] as Timestamp?;
        final bTime = b['createdAt'] as Timestamp?;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });
      
      return list;
    });
  }

  /// Zrušenie objednávky adminom.
  Future<void> cancelOrder(String orderId) async {
    await _firestore.collection(Collections.orders).doc(orderId).update({
      'status': OrderStatus.cancelled,
      'updatedAt': FieldValue.serverTimestamp(),
      'cancelledBy': 'admin',
    });
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_models/shared_models.dart';

/// Objednávky z Firestore pre danú stavebnínu.
class OrdersService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream objednávok danej stavebníny, zoradených od najnovších.
  Stream<List<Map<String, dynamic>>> ordersStream(String shopId) {
    return _firestore
        .collection(Collections.orders)
        .where('shopId', isEqualTo: shopId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  /// Stream jednej objednávky podľa ID (pre detail stránku).
  Stream<Map<String, dynamic>?> orderStream(String orderId) {
    return _firestore
        .collection(Collections.orders)
        .doc(orderId)
        .snapshots()
        .map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      final data = doc.data()!;
      data['id'] = doc.id;
      return data;
    });
  }

  /// Zmení stav objednávky. Pri stave [OrderStatus.confirmed] doplní confirmedAt a confirmedByUserId.
  /// Hodnota `OrderStatus.confirmed` ('confirmed') sa používa v driver_app na zobrazenie objednávok „Chcem viezť“.
  Future<void> updateOrderStatus(
    String orderId,
    String newStatus, {
    String? confirmedByUserId,
  }) async {
    final updates = <String, dynamic>{
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (newStatus == OrderStatus.confirmed) {
      updates['confirmedAt'] = FieldValue.serverTimestamp();
      if (confirmedByUserId != null && confirmedByUserId.isNotEmpty) {
        updates['confirmedByUserId'] = confirmedByUserId;
      }
    }
    await _firestore.collection(Collections.orders).doc(orderId).update(updates);
  }
}

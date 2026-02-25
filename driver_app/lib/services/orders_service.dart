import 'package:cloud_firestore/cloud_firestore.dart' show FieldValue, FirebaseFirestore, Timestamp;
import 'package:get/get.dart';
import 'package:shared_models/shared_models.dart';

import 'users_service.dart';

/// Objednávky pre vodiča: dostupné na prevzatie (confirmed) a moje (driverId).
class OrdersService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Objednávky pripravené na vyzdvihnutie (stavebnína schválila – status confirmed).
  Stream<List<Map<String, dynamic>>> availableOrdersStream() {
    return _firestore
        .collection(Collections.orders)
        .where('status', isEqualTo: OrderStatus.confirmed)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      _sortByCreatedAt(list);
      return list;
    });
  }

  /// Objednávky priradené tomuto vodičovi (assigned, picked_up, delivered).
  Stream<List<Map<String, dynamic>>> myOrdersStream(String driverId) {
    return _firestore
        .collection(Collections.orders)
        .where('driverId', isEqualTo: driverId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      _sortByCreatedAt(list);
      return list;
    });
  }

  /// Stream aktuálnej aktívnej objednávky vodiča (assigned alebo picked_up).
  Stream<Map<String, dynamic>?> activeOrderStream(String driverId) {
    return _firestore
        .collection(Collections.orders)
        .where('driverId', isEqualTo: driverId)
        .snapshots()
        .map((snap) {
      final active = snap.docs.where((doc) {
        final status = doc.data()['status'] as String?;
        return status == OrderStatus.assigned || status == OrderStatus.pickedUp;
      });
      if (active.isEmpty) return null;
      final data = active.first.data();
      data['id'] = active.first.id;
      return data;
    });
  }

  /// Stream konkrétnej objednávky.
  Stream<Map<String, dynamic>?> orderStream(String orderId) {
    return _firestore.collection(Collections.orders).doc(orderId).snapshots().map((doc) {
      if (!doc.exists) return null;
      final data = doc.data();
      if (data != null) data['id'] = doc.id;
      return data;
    });
  }

  void _sortByCreatedAt(List<Map<String, dynamic>> list) {
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
  }

  /// Vodič sa prihlási o objednávku – nastaví status assigned a driverId.
  Future<void> claimOrder(String orderId, String driverId) async {
    String? driverName;
    String? driverPhone;

    try {
      final userDoc = await Get.find<UsersService>().getUser(driverId);
      if (userDoc != null) {
        final first = userDoc['firstName'] as String? ?? '';
        final last = userDoc['lastName'] as String? ?? '';
        driverName = '$first $last'.trim();
        if (driverName.isEmpty) driverName = null;
        driverPhone = userDoc['phone'] as String?;
      }
    } catch (_) {}

    await _firestore.collection(Collections.orders).doc(orderId).update({
      'status': OrderStatus.assigned,
      'driverId': driverId,
      if (driverName != null) 'driverName': driverName,
      if (driverPhone != null) 'driverPhone': driverPhone,
      'assignedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Zmení stav objednávky (používané na picked_up).
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    await _firestore.collection(Collections.orders).doc(orderId).update({
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Vodič označí doručenie – status delivered.
  Future<void> markDelivered(String orderId) async {
    await _firestore.collection(Collections.orders).doc(orderId).update({
      'status': OrderStatus.delivered,
      'deliveredAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

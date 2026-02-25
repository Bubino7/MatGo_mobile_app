import 'package:cloud_firestore/cloud_firestore.dart' show FieldValue, FirebaseFirestore, Timestamp;
import 'package:get/get.dart';
import 'package:shared_models/shared_models.dart';

import 'shops_service.dart';
import 'users_service.dart';
import '../models/cart_item.dart';

/// Služba pre vytváranie objednávok. Jedna objednávka = jedna stavebnína (košík sa rozdelí podľa shopId).
class OrdersService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const double shippingCostPerOrder = 5.00;
  static const double taxRate = 0.10;

  /// Rozdelí košík podľa shopId a pre každú stavebnínu vytvorí jednu objednávku v Firestore.
  /// [deliveryAddress] je adresa doručenia z formulára. [clientUserId] a [clientEmail] z Firebase Auth.
  /// Vráti počet vytvorených objednávok.
  Future<int> placeOrder({
    required List<CartItem> cartItems,
    required OrderAddress deliveryAddress,
    required String clientUserId,
    required String clientEmail,
    String? noteFromClient,
  }) async {
    if (cartItems.isEmpty) return 0;

    // Získame tel. číslo a meno zákazníka z profilu
    String? clientPhone;
    String? clientName;
    try {
      final userDoc = await Get.find<UsersService>().getUser(clientUserId);
      if (userDoc != null) {
        clientPhone = userDoc['phone'] as String?;
        final first = userDoc['firstName'] as String? ?? '';
        final last = userDoc['lastName'] as String? ?? '';
        final fullName = '$first $last'.trim();
        if (fullName.isNotEmpty) clientName = fullName;
      }
    } catch (_) {}

    final byShop = <String, List<CartItem>>{};
    for (final item in cartItems) {
      final sid = item.product.shopId;
      if (sid.isEmpty) continue;
      byShop.putIfAbsent(sid, () => []).add(item);
    }

    final shops = Get.find<ShopsService>();
    int count = 0;

    for (final entry in byShop.entries) {
      final shopId = entry.key;
      final items = entry.value;
      if (items.isEmpty) continue;

      final shop = await shops.getShop(shopId);
      final shopName = (shop?['name'] as String?) ?? shopId;
      final shopAddress = shop?['address'] as String? ?? '';

      final orderItems = <Map<String, dynamic>>[];
      double subtotal = 0;
      for (final item in items) {
        final p = item.product;
        final lineTotal = p.price * item.quantity;
        subtotal += lineTotal;
        orderItems.add(OrderItemData(
          productId: p.id,
          productName: p.name,
          shopId: p.shopId,
          quantity: item.quantity,
          unit: p.unit,
          pricePerUnit: p.price,
          lineTotal: lineTotal,
        ).toMap());
      }

      final shipping = shippingCostPerOrder;
      final tax = (subtotal + shipping) * taxRate;
      final total = subtotal + shipping + tax;

      final pickupMap = OrderAddress(
        street: shopAddress,
        city: '',
        zip: '',
        country: 'SK',
      ).toMap();

      final orderData = OrderData(
        clientUserId: clientUserId,
        clientEmail: clientEmail,
        shopId: shopId,
        shopName: shopName,
        pickupAddress: pickupMap,
        deliveryAddress: deliveryAddress.toMap(),
        items: orderItems,
        subtotal: subtotal,
        shippingCost: shipping,
        taxAmount: tax,
        total: total,
        noteFromClient: noteFromClient,
      );

      final data = orderData.toMap();
      if (clientPhone != null) data['clientPhone'] = clientPhone;
      if (clientName != null) data['clientName'] = clientName;
      data['createdAt'] = FieldValue.serverTimestamp();
      data['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore.collection(Collections.orders).add(data);
      count++;
    }

    return count;
  }

  /// Stream objednávok vytvorených daným klientom (clientUserId). Každá položka obsahuje [id] dokumentu + dáta z Firestore. Zoradené od najnovších.
  Stream<List<Map<String, dynamic>>> ordersStreamForClient(String clientUserId) {
    return _firestore
        .collection(Collections.orders)
        .where('clientUserId', isEqualTo: clientUserId)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map((doc) {
        final map = Map<String, dynamic>.from(doc.data());
        map['id'] = doc.id;
        return map;
      }).toList();
      list.sort((a, b) {
        final at = a['createdAt'];
        final bt = b['createdAt'];
        final am = at is Timestamp ? at.millisecondsSinceEpoch : 0;
        final bm = bt is Timestamp ? bt.millisecondsSinceEpoch : 0;
        return bm.compareTo(am);
      });
      return list;
    });
  }

  /// Stream počtu aktívnych objednávok (všetky okrem doručených a zrušených).
  Stream<int> activeOrdersCountStream(String clientUserId) {
    return _firestore
        .collection(Collections.orders)
        .where('clientUserId', isEqualTo: clientUserId)
        .snapshots()
        .map((snap) {
      return snap.docs.where((doc) {
        final status = doc.data()['status'] as String?;
        return status != OrderStatus.delivered && status != OrderStatus.cancelled;
      }).length;
    });
  }

  /// Zrušenie objednávky klientom (povolené len v počiatočnom stave).
  Future<void> cancelOrder(String orderId) async {
    await _firestore.collection(Collections.orders).doc(orderId).update({
      'status': OrderStatus.cancelled,
      'updatedAt': FieldValue.serverTimestamp(),
      'cancelledAt': FieldValue.serverTimestamp(),
      'cancelledBy': 'client',
    });
  }
}

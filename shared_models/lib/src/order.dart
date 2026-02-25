import 'collections.dart';

/// Stav objednávky v systéme.
///
/// Flow: Klient vytvorí (pending_shop) → Stavebnína schváli, že má na sklade (confirmed) →
/// V driver_app vodič sa prihlási o objednávku (assigned) → Stavebnína označí vyzdvihnutie (picked_up, vodič doručuje) →
/// Vodič v driver_app potvrdí doručenie (delivered).
abstract class OrderStatus {
  /// Čaká na schválenie stavebnínou (máme tovar na sklade?).
  static const String pendingShop = 'pending_shop';
  /// Schválená stavebnínou – v driver_app zobrazená ako objednávka, o ktorú sa vodič môže prihlásiť.
  static const String confirmed = 'confirmed';
  /// Vodič priradený (vodič sa prihlásil), čaká na vyzdvihnutie u stavebníny.
  static const String assigned = 'assigned';
  /// Vyzdvihnuté – vodič prebral, doručuje (navigácia na doručovaciu adresu).
  static const String pickedUp = 'picked_up';
  /// Doručené – vodič v aplikácii potvrdil doručenie.
  static const String delivered = 'delivered';
  static const String cancelled = 'cancelled';
}

/// Jedna položka v objednávke (zapisuje sa do Firestore ako prvok poľa items).
class OrderItemData {
  OrderItemData({
    required this.productId,
    required this.productName,
    required this.shopId,
    required this.quantity,
    this.unit,
    required this.pricePerUnit,
    required this.lineTotal,
  });

  final String productId;
  final String productName;
  final String shopId;
  final int quantity;
  final String? unit;
  final double pricePerUnit;
  final double lineTotal;

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'productName': productName,
        'shopId': shopId,
        'quantity': quantity,
        if (unit != null && unit!.isNotEmpty) 'unit': unit,
        'pricePerUnit': pricePerUnit,
        'lineTotal': lineTotal,
      };

  static OrderItemData fromMap(Map<String, dynamic> map) {
    final price = map['pricePerUnit'];
    final line = map['lineTotal'];
    return OrderItemData(
      productId: (map['productId'] as String?) ?? '',
      productName: (map['productName'] as String?) ?? '',
      shopId: (map['shopId'] as String?) ?? '',
      quantity: (map['quantity'] as int?) ?? 0,
      unit: map['unit'] as String?,
      pricePerUnit: price is num ? price.toDouble() : 0,
      lineTotal: line is num ? line.toDouble() : 0,
    );
  }
}

/// Dáta jednej objednávky pre zápis do Firestore (kolekcia [Collections.orders]).
class OrderData {
  OrderData({
    required this.clientUserId,
    required this.clientEmail,
    required this.shopId,
    required this.shopName,
    required this.pickupAddress,
    required this.deliveryAddress,
    required this.items,
    required this.subtotal,
    required this.shippingCost,
    required this.taxAmount,
    required this.total,
    this.noteFromClient,
  });

  final String clientUserId;
  final String clientEmail;
  final String shopId;
  final String shopName;
  final Map<String, dynamic> pickupAddress;
  final Map<String, dynamic> deliveryAddress;
  final List<Map<String, dynamic>> items;
  final double subtotal;
  final double shippingCost;
  final double taxAmount;
  final double total;
  final String? noteFromClient;

  Map<String, dynamic> toMap() => {
        'status': OrderStatus.pendingShop,
        'clientUserId': clientUserId,
        'clientEmail': clientEmail,
        'shopId': shopId,
        'shopName': shopName,
        'pickupAddress': pickupAddress,
        'deliveryAddress': deliveryAddress,
        'items': items,
        'subtotal': subtotal,
        'shippingCost': shippingCost,
        'taxAmount': taxAmount,
        'total': total,
        if (noteFromClient != null && noteFromClient!.isNotEmpty) 'noteFromClient': noteFromClient,
      };
}

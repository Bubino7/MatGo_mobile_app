import 'product.dart';

/// Položka v košíku: produkt + množstvo (reprezentácia pre Firestore ID stačí neskôr).
class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get lineTotal => product.price * quantity;

  /// Porovnanie podľa product.id (pre zlučovanie rovnakých produktov)
  bool isSameProduct(CartItem other) => product.id == other.product.id;
}

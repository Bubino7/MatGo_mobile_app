import 'dart:convert';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/cart_item.dart';
import '../models/product.dart';

class CartController extends GetxController {
  final cartItems = <CartItem>[].obs;

  static const String _cartKey = 'matgo_cart';
  static const int _cartExpirationMinutes = 30;

  SharedPreferences? _prefs;

  DateTime? _cartSavedAt;

  int? get remainingMinutes {
    if (_cartSavedAt == null || cartItems.isEmpty) return null;
    final elapsed = DateTime.now().difference(_cartSavedAt!).inMinutes;
    final r = _cartExpirationMinutes - elapsed;
    return r < 0 ? 0 : r;
  }

  @override
  void onInit() {
    super.onInit();
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _loadFromPrefs();
    } catch (_) {}
  }

  double get totalPrice =>
      cartItems.fold(0.0, (sum, item) => sum + item.lineTotal);

  int get totalItemCount =>
      cartItems.fold(0, (sum, item) => sum + item.quantity);

  void _loadFromPrefs() {
    try {
      if (_prefs == null) return;
      final jsonStr = _prefs!.getString(_cartKey);
      if (jsonStr == null || jsonStr.isEmpty) return;
      final data = jsonDecode(jsonStr);
      if (data is! Map<String, dynamic>) return;
      final savedAt = data['savedAt'];
      if (savedAt is! int) return;
      final savedTime = DateTime.fromMillisecondsSinceEpoch(savedAt);
      if (DateTime.now().difference(savedTime).inMinutes >= _cartExpirationMinutes) {
        _prefs!.remove(_cartKey);
        return;
      }
      final list = data['items'] as List<dynamic>?;
      if (list == null || list.isEmpty) return;
      final loaded = <CartItem>[];
      for (final raw in list) {
        if (raw is! Map<String, dynamic>) continue;
        final map = Map<String, dynamic>.from(raw);
        final productMap = map['product'];
        final quantity = map['quantity'];
        if (productMap is! Map<String, dynamic> || quantity is! int) continue;
        try {
          loaded.add(CartItem(
            product: Product.fromMap(Map<String, dynamic>.from(productMap)),
            quantity: quantity.clamp(1, 9999),
          ));
        } catch (_) {}
      }
      if (loaded.isNotEmpty) {
        cartItems.assignAll(loaded);
        _cartSavedAt = savedTime;
      }
    } catch (_) {}
  }

  void _saveToPrefs() {
    try {
      if (_prefs == null) return;
      final list = cartItems
          .map((item) => {
                'product': item.product.toMap(),
                'quantity': item.quantity,
              })
          .toList();
      final now = DateTime.now();
      final data = {
        'items': list,
        'savedAt': now.millisecondsSinceEpoch,
      };
      _prefs!.setString(_cartKey, jsonEncode(data));
      if (list.isNotEmpty) {
        _cartSavedAt = now;
      } else {
        _cartSavedAt = null;
      }
    } catch (_) {}
  }

  void addToCart(Product product, {int quantity = 1}) {
    if (quantity < 1) return;

    final existing = cartItems.indexWhere(
      (item) => item.product.id == product.id,
    );
    if (existing >= 0) {
      cartItems[existing].quantity += quantity;
    } else {
      cartItems.add(CartItem(product: product, quantity: quantity));
    }
    _saveToPrefs();
    Get.snackbar(
      'Košík',
      '${product.name} ($quantity ks) bol pridaný do košíka',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Get.theme.colorScheme.primaryContainer,
    );
  }

  void removeFromCartAt(int index) {
    if (index >= 0 && index < cartItems.length) {
      cartItems.removeAt(index);
      _saveToPrefs();
    }
  }

  void setQuantityAt(int index, int quantity) {
    if (index < 0 || index >= cartItems.length) return;
    if (quantity <= 0) {
      cartItems.removeAt(index);
      _saveToPrefs();
      return;
    }
    cartItems[index].quantity = quantity;
    cartItems.refresh();
    _saveToPrefs();
  }

  void clearCart() {
    cartItems.clear();
    _saveToPrefs();
  }
}

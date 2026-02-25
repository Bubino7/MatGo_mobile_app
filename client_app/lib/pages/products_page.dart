import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/cart_controller.dart';
import '../models/product.dart';
import '../services/products_service.dart';

class ProductsPage extends StatelessWidget {
  final String categoryId;
  final String categoryName;

  const ProductsPage({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  Widget build(BuildContext context) {
    final cartController = Get.find<CartController>();
    final productsStream = Get.find<ProductsService>().productsStreamByCategory(categoryId);

    return Scaffold(
      appBar: AppBar(
        title: Text(categoryName),
        backgroundColor: Colors.amber,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: productsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                  const SizedBox(height: 12),
                  Text('Chyba načítania', style: TextStyle(color: Colors.grey.shade700)),
                ],
              ),
            );
          }
          final list = snapshot.data ?? [];
          final products = list.map((m) => Product.fromMap(m, categoryName: categoryName)).toList();
          if (products.isEmpty) {
            return const Center(
              child: Text('V tejto kategórii zatiaľ nie sú žiadne produkty.'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final p = products[index];
              final unitStr = (p.unit != null && p.unit!.isNotEmpty) ? ' / ${p.unit}' : ' / ks';
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: p.imageUrl != null && p.imageUrl!.isNotEmpty
                      ? Image.network(
                          p.imageUrl!,
                          width: 48,
                          height: 48,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(Icons.inventory_2, color: Colors.amber, size: 48),
                        )
                      : (p.imagePath != null && p.imagePath!.isNotEmpty)
                          ? Image.asset(
                              p.imagePath!,
                              width: 48,
                              height: 48,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(Icons.inventory_2, color: Colors.amber, size: 48),
                            )
                          : const Icon(Icons.inventory_2, color: Colors.amber, size: 48),
                  title: Text(
                    p.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${p.shopName} · ${p.price.toStringAsFixed(2)} €$unitStr',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.add_shopping_cart, color: Colors.amber),
                    onPressed: () => showQuantityDialog(context, cartController, p),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// Vráti [Future] s [true] ak používateľ pridal do košíka, [false] ak zrušil.
  static Future<bool> showQuantityDialog(
    BuildContext context,
    CartController cartController,
    Product product,
  ) async {
    int quantity = 1;
    final unitStr = (product.unit != null && product.unit!.isNotEmpty) ? ' / ${product.unit}' : ' / ks';
    final added = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(product.name),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${product.shopName} · ${product.price.toStringAsFixed(2)} €$unitStr',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton.filled(
                      icon: const Icon(Icons.remove),
                      onPressed: quantity > 1
                          ? () => setState(() => quantity--)
                          : null,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        '$quantity',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton.filled(
                      icon: const Icon(Icons.add),
                      onPressed: () => setState(() => quantity++),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Spolu: ${(product.price * quantity).toStringAsFixed(2)} €',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Zrušiť'),
              ),
              FilledButton(
                onPressed: () {
                  cartController.addToCart(product, quantity: quantity);
                  Navigator.of(context).pop(true);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                ),
                child: const Text('Pridať do košíka'),
              ),
            ],
          );
        },
      ),
    );
    return added ?? false;
  }
}

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'firebase_options.dart';
import 'pages/portal_gate.dart';
import 'services/auth_service.dart';
import 'services/categories_service.dart';
import 'services/orders_service.dart';
import 'services/products_service.dart';
import 'services/shops_service.dart';
import 'services/users_service.dart';

/// Z URL cesty vráti shopId. Očakáva sa cesta /shop_app/{id} (alebo pri base-href /shop_app/ len segment s id).
String? _shopIdFromPath() {
  final path = Uri.base.path;
  final parts = path.split('/').where((s) => s.isNotEmpty).toList();
  final i = parts.indexOf('shop_app');
  if (i >= 0 && i + 1 < parts.length) return parts[i + 1];
  if (parts.length == 1) return parts[0];
  return null;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  Get.put(AuthService());
  Get.put(ShopsService());
  Get.put(UsersService());
  Get.put(ProductsService());
  Get.put(CategoriesService());
  Get.put(OrdersService());

  final shopId = _shopIdFromPath();
  if (shopId != null && shopId.isNotEmpty) {
    runApp(ShopPortalApp(shopId: shopId));
  } else {
    runApp(const _NoShopIdApp());
  }
}

class ShopPortalApp extends StatelessWidget {
  const ShopPortalApp({super.key, required this.shopId});
  final String shopId;

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'MatGo Stavebniny',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.amber),
        useMaterial3: true,
      ),
      home: PortalGate(shopId: shopId),
    );
  }
}

class _NoShopIdApp extends StatelessWidget {
  const _NoShopIdApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MatGo',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.link_off, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                const Text(
                  'V URL chýba ID stavebnín.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  'Otvorte odkaz v tvare …/shop_app/{id_stavebnice}',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/cart_controller.dart';
import '../models/product.dart';
import '../services/auth_service.dart';
import '../services/categories_service.dart';
import '../services/orders_service.dart';
import '../services/products_service.dart';
import '../services/shops_service.dart';
import 'my_orders_page.dart';
import 'products_page.dart';
import 'shops_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Bar – tap otvorí vyhľadávací sheet, query až po stlačení lupy
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: InkWell(
                  onTap: () => _openSearchSheet(context),
                  borderRadius: BorderRadius.circular(12),
                  child: IgnorePointer(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Vyhľadávanie',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Filter Buttons (Obľúbené, História, Objednávky)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    _buildFilterButton(
                      icon: Icons.favorite_border,
                      label: 'Obľúbené',
                      onTap: () {},
                    ),
                    const SizedBox(width: 12),
                    _buildFilterButton(
                      icon: Icons.history,
                      label: 'História',
                      onTap: () {},
                    ),
                    const SizedBox(width: 12),
                    StreamBuilder<int>(
                      stream: Get.find<AuthService>().currentUser == null
                          ? Stream.value(0)
                          : Get.find<OrdersService>().activeOrdersCountStream(Get.find<AuthService>().currentUser!.uid),
                      builder: (context, snapshot) {
                        final count = snapshot.data ?? 0;
                        return _buildFilterButton(
                          icon: Icons.receipt_long,
                          label: 'Objednávky',
                          badgeCount: count > 0 ? count : null,
                          onTap: () => Get.to(() => const MyOrdersPage()),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Promotional Banner
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.grey.shade800,
                        Colors.grey.shade600,
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Blurred background effect
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.black.withOpacity(0.3),
                          ),
                        ),
                      ),
                      // Logo + text overlay
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(
                                'assets/MatGo_icon_logo.png',
                                width: 56,
                                height: 56,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => Icon(Icons.construction, color: Colors.white.withOpacity(0.9), size: 56),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'MatGo',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // "Položky" Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Položky',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Všetko'),
                          Icon(Icons.arrow_forward_ios, size: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Kategórie z Firestore
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: Get.find<CategoriesService>().categoriesStream(),
                builder: (context, catSnap) {
                  if (!catSnap.hasData || catSnap.data!.isEmpty) {
                    return SizedBox(
                      height: 120,
                      child: Center(
                        child: Text(
                          'Žiadne kategórie',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                    );
                  }
                  final categories = catSnap.data!;
                  final colorList = [
                    Colors.amber.shade700,
                    Colors.blue.shade700,
                    Colors.grey.shade700,
                    Colors.green.shade700,
                    Colors.orange.shade700,
                  ];
                  return SizedBox(
                    height: 120,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      children: [
                        for (var i = 0; i < categories.length; i++) ...[
                          if (i > 0) const SizedBox(width: 16),
                          _buildCategoryItem(
                            icon: Icons.category_outlined,
                            label: categories[i]['name'] as String? ?? '',
                            color: colorList[i % colorList.length],
                            onTap: () => Get.to(() => ProductsPage(
                              categoryId: categories[i]['id'] as String? ?? '',
                              categoryName: categories[i]['name'] as String? ?? '',
                            )),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Stavebniny z Firestore
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Stavebniny',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Get.to(() => const ShopsPage()),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Všetko'),
                          Icon(Icons.arrow_forward_ios, size: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              StreamBuilder<List<Map<String, dynamic>>>(
                stream: Get.find<ShopsService>().shopsStream,
                builder: (context, shopSnap) {
                  if (!shopSnap.hasData || shopSnap.data!.isEmpty) {
                    return SizedBox(
                      height: 140,
                      child: Center(
                        child: Text(
                          'Žiadne stavebniny',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                    );
                  }
                  final shops = shopSnap.data!;
                  return SizedBox(
                    height: 140,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      children: [
                        for (var i = 0; i < shops.length; i++) ...[
                          if (i > 0) const SizedBox(width: 16),
                          _buildShopCard(
                            shopName: shops[i]['name'] as String? ?? 'Stavebnína',
                            imageUrl: shops[i]['imageUrl'] as String?,
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _openSearchSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final topBarrierHeight = MediaQuery.sizeOf(context).height * 0.1;
        return Stack(
          children: [
            // Klikateľná oblasť nad sheetom – zatvorí sheet
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: topBarrierHeight,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context).pop(),
                child: Container(color: Colors.transparent),
              ),
            ),
            // Sheet v spodnej časti
            Positioned(
              left: 0,
              right: 0,
              top: topBarrierHeight,
              bottom: 0,
              child: DraggableScrollableSheet(
                initialChildSize: 1,
                minChildSize: 0.5,
                maxChildSize: 1,
                builder: (context, scrollController) => Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: _SearchSheetContent(scrollController: scrollController),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    int? badgeCount,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Badge(
          isLabelVisible: badgeCount != null && badgeCount > 0,
          label: Text(badgeCount?.toString() ?? ''),
          backgroundColor: Colors.red,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: Colors.grey.shade700),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryItem({
    required IconData icon,
    required String label,
    required Color color,
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap ?? () {},
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 100,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconColor ?? Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShopCard({
    required String shopName,
    String? imageUrl,
  }) {
    return InkWell(
      onTap: () => Get.to(() => const ShopsPage()),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (imageUrl != null && imageUrl.isNotEmpty) ...[
              SizedBox(
                height: 40,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(Icons.store, color: Colors.amber, size: 40),
                ),
              ),
            ] else ...[
              const Icon(Icons.store, color: Colors.amber, size: 40),
            ],
            const SizedBox(height: 12),
            Text(
              shopName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Vyhľadávací sheet: pole + tlačidlo lupy vpravo, query sa spustí až po stlačení.
class _SearchSheetContent extends StatefulWidget {
  const _SearchSheetContent({required this.scrollController});

  final ScrollController scrollController;

  @override
  State<_SearchSheetContent> createState() => _SearchSheetContentState();
}

class _SearchSheetContentState extends State<_SearchSheetContent> {
  final TextEditingController _controller = TextEditingController();
  String? _executedQuery;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSearch() {
    setState(() {
      _executedQuery = _controller.text.trim();
      if (_executedQuery != null && _executedQuery!.isEmpty) _executedQuery = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Column(
        children: [
          // Riadok: vyhľadávacie pole + tlačidlo lupy vpravo
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    autofocus: true,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _onSearch(),
                    decoration: InputDecoration(
                      hintText: 'Vyhľadávanie',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _onSearch,
                  icon: const Icon(Icons.search),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Telo: prázdny stav alebo výsledky
          Expanded(
            child: _executedQuery == null || _executedQuery!.isEmpty
                ? Center(
                    child: Text(
                      'Zadajte hľadaný výraz a stlačte vyhľadať',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                    ),
                  )
                : StreamBuilder<List<Map<String, dynamic>>>(
                    stream: Get.find<ProductsService>().productsStreamBySearch(_executedQuery!),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final list = snapshot.data ?? [];
                      final products = list.map((m) => Product.fromMap(m, categoryName: '')).toList();
                      if (products.isEmpty) {
                        return Center(
                          child: Text(
                            'Žiadne produkty pre „$_executedQuery“',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        );
                      }
                      final cartController = Get.find<CartController>();
                      return ListView.builder(
                        controller: widget.scrollController,
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
                                  : const Icon(Icons.inventory_2, color: Colors.amber, size: 48),
                              title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                '${p.shopName} · ${p.price.toStringAsFixed(2)} €$unitStr',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.add_shopping_cart, color: Colors.amber),
                                onPressed: () async {
                                  final added = await ProductsPage.showQuantityDialog(context, cartController, p);
                                  if (context.mounted && added) Navigator.of(context).pop();
                                },
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

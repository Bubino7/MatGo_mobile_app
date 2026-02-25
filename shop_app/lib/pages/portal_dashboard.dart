import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/auth_service.dart';
import '../services/shops_service.dart';
import 'portal_orders_page.dart';
import 'portal_products_page.dart';

class PortalDashboard extends StatefulWidget {
  const PortalDashboard({
    super.key,
    required this.shopId,
    required this.shopName,
    this.userName,
  });
  final String shopId;
  final String shopName;
  final String? userName;

  @override
  State<PortalDashboard> createState() => _PortalDashboardState();
}

class _PortalDashboardState extends State<PortalDashboard> {
  DateTime _now = DateTime.now();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  static String _formatDate(DateTime d) {
    const days = ['Pondelok', 'Utorok', 'Streda', 'Štvrtok', 'Piatok', 'Sobota', 'Nedeľa'];
    final day = days[d.weekday - 1];
    return '$day, ${d.day}. ${d.month}. ${d.year}';
  }

  static String _formatTime(DateTime d) {
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}:${d.second.toString().padLeft(2, '0')}';
  }

  /// Ráno 5–11, deň 12–17, večer 18–4.
  static String _greetingWord(DateTime d) {
    final h = d.hour;
    if (h >= 5 && h < 10) return 'Dobré ráno';
    if (h >= 12 && h < 18) return 'Dobrý deň';
    return 'Dobrý večer';
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.userName?.trim();
    final greetingWord = _greetingWord(_now);
    final hasName = name != null && name.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text('MatGo – ${widget.shopName}'),
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Get.find<AuthService>().signOut(),
            tooltip: 'Odhlásiť sa',
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.amber.shade700),
              child: Text(
                'MatGo – ${widget.shopName}',
                style: const TextStyle(color: Colors.black87, fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.shopping_cart_outlined),
              title: const Text('Objednávky'),
              onTap: () {
                Navigator.pop(context);
                Get.to(() => PortalOrdersPage(shopId: widget.shopId, shopName: widget.shopName));
              },
            ),
            ListTile(
              leading: const Icon(Icons.inventory_2_outlined),
              title: const Text('Položky na predaj'),
              onTap: () {
                Navigator.pop(context);
                Get.to(() => PortalProductsPage(shopId: widget.shopId, shopName: widget.shopName));
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              greetingWord,
                              style: TextStyle(fontSize: 18, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                            ),
                            if (hasName) ...[
                              const SizedBox(height: 4),
                              Text(
                                name,
                                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.amber.shade800),
                              ),
                            ],
                            const SizedBox(height: 12),
                            Text(
                              _formatDate(_now),
                              style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatTime(_now),
                              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w300, color: Colors.grey.shade800, letterSpacing: 1),
                            ),
                          ],
                        ),
                      ),
                      FutureBuilder<Map<String, dynamic>?>(
                        future: Get.find<ShopsService>().getShop(widget.shopId),
                        builder: (context, snap) {
                          if (!snap.hasData || snap.data == null) return const SizedBox.shrink();
                          final shop = snap.data!;
                          final shopName = shop['name'] as String? ?? widget.shopName;
                          final address = shop['address'] as String?;
                          if (shopName.isEmpty && (address == null || address.isEmpty)) return const SizedBox.shrink();
                          return Container(
                            padding: const EdgeInsets.only(left: 20),
                            decoration: BoxDecoration(
                              border: Border(left: BorderSide(color: Colors.grey.shade300)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.store_outlined, size: 18, color: Colors.amber.shade700),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Administrácia',
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 220),
                                  child: Text(
                                    shopName,
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.grey.shade800),
                                    textAlign: TextAlign.right,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (address != null && address.trim().isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(maxWidth: 220),
                                    child: Text(
                                      address.trim(),
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                      textAlign: TextAlign.right,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Divider(height: 1, thickness: 1, color: Colors.grey.shade300),
            const SizedBox(height: 40),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Row(
                  children: [
                    Expanded(
                      child: _DashboardCard(
                        icon: Icons.shopping_cart_outlined,
                        title: 'Objednávky',
                        subtitle: 'Prehľad a správa objednávok',
                        count: null,
                        onTap: () => Get.to(() => PortalOrdersPage(shopId: widget.shopId, shopName: widget.shopName)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _DashboardCard(
                        icon: Icons.inventory_2_outlined,
                        title: 'Položky na predaj',
                        subtitle: 'Tovar a ceny',
                        count: null,
                        onTap: () => Get.to(() => PortalProductsPage(shopId: widget.shopId, shopName: widget.shopName)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.count,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final int? count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 28, color: Colors.amber.shade800),
              ),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600), textAlign: TextAlign.center),
              if (count != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('$count', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.amber.shade900)),
                ),
              ] else
                const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

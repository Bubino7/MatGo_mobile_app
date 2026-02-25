import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/auth_service.dart';
import '../services/orders_service.dart';
import '../services/users_service.dart';
import 'available_orders_page.dart';
import 'delivered_orders_page.dart';
import 'driver_order_detail_page.dart';

String _greetingWord(DateTime d) {
  final h = d.hour;
  if (h >= 5 && h < 10) return 'Dobré ráno';
  if (h >= 10 && h < 12) return 'Dobré dopoludnie';
  if (h >= 12 && h < 18) return 'Dobrý deň';
  return 'Dobrý večer';
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = Get.find<AuthService>().currentUser?.uid ?? '';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),
                    Icon(
                      Icons.local_shipping,
                      size: 64,
                      color: Colors.amber.shade800,
                    ),
                    const SizedBox(height: 24),
                    // Uvítanie s menom (zo Streamu)
                    StreamBuilder<Map<String, dynamic>?>(
                      stream: Get.find<UsersService>().userStream(uid),
                      builder: (context, snapshot) {
                        final data = snapshot.data;
                        final firstName = data?['firstName'] as String? ?? '';
                        final lastName = data?['lastName'] as String? ?? '';
                        final fullName = '$firstName $lastName'.trim();
                        final name = fullName.isNotEmpty ? fullName : 'Vodič';
                        return Column(
                          children: [
                            Text(_greetingWord(DateTime.now()), style: TextStyle(fontSize: 22, color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 6),
                            Text(name, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.amber.shade800)),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    Divider(thickness: 1, color: Colors.grey.shade200),
                    const Spacer(),
                  ],
                ),
              ),

              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Aktívna objednávka vs. Chcem viezť
                  StreamBuilder<Map<String, dynamic>?>(
                    stream: Get.find<OrdersService>().activeOrderStream(uid),
                    builder: (context, snapshot) {
                      final activeOrder = snapshot.data;

                      if (activeOrder != null) {
                        return _ActiveOrderCard(order: activeOrder);
                      }

                      return _NavButton(
                        icon: Icons.local_shipping_outlined,
                        label: 'Chcem viezť',
                        subtitle: 'Dostupné objednávky na vyzdvihnutie',
                        onTap: () => Get.to(() => const AvailableOrdersPage()),
                      );
                    },
                  ),

                  const SizedBox(height: 16),
                  _NavButton(
                    icon: Icons.check_circle_outline,
                    label: 'Vyvezené objednávky',
                    subtitle: 'História doručených objednávok',
                    onTap: () => Get.to(() => const DeliveredOrdersPage()),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveOrderCard extends StatelessWidget {
  const _ActiveOrderCard({required this.order});
  final Map<String, dynamic> order;

  @override
  Widget build(BuildContext context) {
    final items = order['items'] as List<dynamic>? ?? [];
    return Container(
      decoration: BoxDecoration(
        color: Colors.amber.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade300, width: 2),
      ),
      child: InkWell(
        onTap: () => Get.to(() => DriverOrderDetailPage(order: order)),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('AKTUÁLNA OBJEDNÁVKA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                    child: Text('${(order['total'] as num?)?.toStringAsFixed(2)} €', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(order['shopName'] ?? 'Stavebnína', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Položky:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ...items.take(3).map((it) => Text('• ${it['productName']}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13))),
              if (items.length > 3) Text('...a ďalších ${items.length - 3}', style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic)),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Text('ZOBRAZIŤ DETAIL A NAVIGOVAŤ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue)),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward, size: 14, color: Colors.blue),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.icon, required this.label, required this.subtitle, required this.onTap});
  final IconData icon;
  final String label, subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200), boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
          ]),
          child: Row(
            children: [
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(12)), child: Icon(icon, size: 28, color: Colors.amber.shade700)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(label, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                ]),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade500),
            ],
          ),
        ),
      ),
    );
  }
}

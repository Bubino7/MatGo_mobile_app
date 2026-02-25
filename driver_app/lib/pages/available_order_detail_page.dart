import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_models/shared_models.dart';
import '../services/auth_service.dart';
import '../services/orders_service.dart';

class AvailableOrderDetailPage extends StatelessWidget {
  const AvailableOrderDetailPage({super.key, required this.order});
  final Map<String, dynamic> order;

  @override
  Widget build(BuildContext context) {
    final shopName = order['shopName'] as String? ?? 'Stavebnína';
    final pickup = OrderAddress.fromMap(order['pickupAddress']);
    final delivery = OrderAddress.fromMap(order['deliveryAddress']);
    final items = order['items'] as List<dynamic>? ?? [];
    final total = (order['total'] as num?)?.toDouble() ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail ponuky'),
        backgroundColor: Colors.amber,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Obchod a suma
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          shopName,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${total.toStringAsFixed(2)} €',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Adresy (len náhľad, bez navigácie zatiaľ)
                  _AddressPreview(
                    title: 'VYZDVIHNUTIE',
                    address: pickup.displayLine,
                    icon: Icons.store,
                  ),
                  const SizedBox(height: 16),
                  _AddressPreview(
                    title: 'DORUČENIE',
                    address: delivery.displayLine,
                    icon: Icons.person_pin_circle,
                  ),
                  const SizedBox(height: 32),

                  // Položky
                  Text(
                    'POLOŽKY (${MatGoUtils.formatItemsCount(items.length)})',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  ...items.map((it) {
                    final name = it['productName'] ?? '—';
                    final qty = it['quantity'] ?? 0;
                    final unit = it['unit'] ?? 'ks';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.circle, size: 6, color: Colors.amber),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text('$qty $unit $name', style: const TextStyle(fontSize: 15)),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          // Tlačidlo prevziať
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton.icon(
                  onPressed: () => _confirmClaim(context),
                  icon: const Icon(Icons.local_shipping),
                  label: const Text('PREVZIAŤ OBJEDNÁVKU'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClaim(BuildContext context) async {
    final uid = Get.find<AuthService>().currentUser?.uid;
    if (uid == null) return;

    final confirmed = await Get.bottomSheet<bool>(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Icon(Icons.help_outline, size: 48, color: Colors.amber),
            const SizedBox(height: 16),
            const Text(
              'Prevziať objednávku?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Chcete prevziať túto objednávku od ${order['shopName'] ?? 'stavebníne'}?',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.back(result: false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    child: const Text('ZRUŠIŤ'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Get.back(result: true),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('PREVZIAŤ'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );

    if (confirmed == true) {
      try {
        await Get.find<OrdersService>().claimOrder(order['id'], uid);
        
        // Navigácia späť až na HomePage
        Get.until((route) => route.isFirst);
        
        Get.snackbar(
          'Objednávka',
          'Objednávka bola priradená vám.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade100,
        );
      } catch (e) {
        Get.snackbar('Chyba', e.toString(), backgroundColor: Colors.red.shade100);
      }
    }
  }
}

class _AddressPreview extends StatelessWidget {
  const _AddressPreview({required this.title, required this.address, required this.icon});
  final String title, address;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.amber.shade700),
            const SizedBox(width: 10),
            Expanded(
              child: Text(address, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      ],
    );
  }
}

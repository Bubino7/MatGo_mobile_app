import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_models/shared_models.dart';
import 'available_order_detail_page.dart';
import '../services/orders_service.dart';

/// Objednávky so statusom confirmed – vodič si ich môže prevziať (claim).
class AvailableOrdersPage extends StatelessWidget {
  const AvailableOrdersPage({super.key});

  static String _statusLabel(String? status) {
    switch (status) {
      case OrderStatus.confirmed:
        return 'Pripravené na vyzdvihnutie';
      default:
        return status ?? '—';
    }
  }

  @override
  Widget build(BuildContext context) {
    final ordersService = Get.find<OrdersService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chcem viezť'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Get.back()),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: ordersService.availableOrdersStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                    const SizedBox(height: 12),
                    Text(
                      'Chyba: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
            );
          }
          final orders = snapshot.data ?? [];
          if (orders.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      'Žiadne objednávky na vyzdvihnutie',
                      style: TextStyle(fontSize: 18, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tu sa zobrazujú objednávky so stavom „Schválené“ (confirmed).'
                      ' Stavebnína ich schvaluje v portáli MatGo – Objednávky: otvorí objednávku so stavom „Čaká na schválenie“ a stlačí „Schváliť objednávku“.'
                      ' Potom sa objednávka zobrazí tu a vodič ju môže prevziať.',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.4),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return _OrderCard(
                order: order,
                statusLabel: _statusLabel(order['status'] as String?),
                onTap: () => Get.to(() => AvailableOrderDetailPage(order: order)),
              );
            },
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.statusLabel,
    required this.onTap,
  });
  final Map<String, dynamic> order;
  final String statusLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final shopName = order['shopName'] as String? ?? '—';
    final total = (order['total'] as num?)?.toDouble() ?? 0;
    final items = order['items'] as List<dynamic>? ?? [];
    final createdAt = order['createdAt'];
    final date = MatGoUtils.parseDate(createdAt);
    final dateStr = date != null
        ? '${date.day}.${date.month}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}'
        : '—';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.store, color: Colors.amber.shade700, size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      shopName,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    '${total.toStringAsFixed(2)} €',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${MatGoUtils.formatItemsCount(items.length)} · $dateStr',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.amber.shade800),
                    ),
                  ),
                  const Row(
                    children: [
                      Text('DETAIL', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue)),
                      SizedBox(width: 4),
                      Icon(Icons.chevron_right, size: 16, color: Colors.blue),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

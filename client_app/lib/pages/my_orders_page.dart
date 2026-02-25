import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_models/shared_models.dart';
import '../services/auth_service.dart';
import '../services/orders_service.dart';
import 'order_detail_page.dart';

/// Podstránka „Moje objednávky“ – zoznam objednávok prihláseného používateľa.
class MyOrdersPage extends StatelessWidget {
  const MyOrdersPage({super.key});

  static String _statusLabel(String? status) {
    switch (status) {
      case OrderStatus.pendingShop:
        return 'Čaká na schválenie';
      case OrderStatus.confirmed:
        return 'Schválená';
      case OrderStatus.assigned:
        return 'Priradená vodičovi';
      case OrderStatus.pickedUp:
        return 'Vodič doručuje';
      case OrderStatus.delivered:
        return 'Doručené';
      case OrderStatus.cancelled:
        return 'Zrušená';
      default:
        return status ?? '—';
    }
  }

  static Color _statusColor(String? status) {
    switch (status) {
      case OrderStatus.pendingShop:
        return Colors.orange;
      case OrderStatus.confirmed:
        return Colors.blue;
      case OrderStatus.assigned:
      case OrderStatus.pickedUp:
        return Colors.amber.shade700;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Get.find<AuthService>().currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Moje objednávky'),
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Get.back()),
        ),
        body: Center(
          child: Text(
            'Musíte byť prihlásený, aby ste videli svoje objednávky.',
            style: TextStyle(color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Moje objednávky'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Get.back()),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: Get.find<OrdersService>().ordersStreamForClient(user.uid),
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
                      'Chyba načítania: ${snapshot.error}',
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'Žiadne objednávky',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Objednávky, ktoré vytvoríte, sa zobrazia tu.',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                  ),
                ],
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
                statusLabel: _statusLabel,
                statusColor: _statusColor,
                onTap: () => Get.to(() => OrderDetailPage(order: order)),
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
    required this.statusColor,
    required this.onTap,
  });
  final Map<String, dynamic> order;
  final String Function(String?) statusLabel;
  final Color Function(String?) statusColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = order['status'] as String?;
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: statusColor(status),
                child: const Icon(Icons.receipt_long, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shopName,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${MatGoUtils.formatItemsCount(items.length)} · $dateStr',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor(status).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusLabel(status),
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: statusColor(status)),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${total.toStringAsFixed(2)} €',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Icon(Icons.chevron_right, color: Colors.grey.shade500, size: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

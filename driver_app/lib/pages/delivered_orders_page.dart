import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_models/shared_models.dart';
import 'driver_order_detail_page.dart';
import '../services/auth_service.dart';
import '../services/orders_service.dart';

/// Objednávky priradené tomuto vodičovi (assigned, picked_up, delivered).
class DeliveredOrdersPage extends StatelessWidget {
  const DeliveredOrdersPage({super.key});

  static String _statusLabel(String? status) {
    switch (status) {
      case OrderStatus.assigned:
        return 'Priradená – čaká na vyzdvihnutie';
      case OrderStatus.pickedUp:
        return 'V ceste – doručujem';
      case OrderStatus.delivered:
        return 'Doručené';
      default:
        return status ?? '—';
    }
  }

  static Color _statusColor(String? status) {
    switch (status) {
      case OrderStatus.assigned:
        return Colors.orange;
      case OrderStatus.pickedUp:
        return Colors.blue;
      case OrderStatus.delivered:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = Get.find<AuthService>().currentUser?.uid;
    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('Musíte byť prihlásený.')),
      );
    }

    final ordersService = Get.find<OrdersService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vyvezené objednávky'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Get.back()),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: ordersService.myOrdersStream(uid),
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'Žiadne vaše objednávky',
                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Objednávky, ktoré prevážate alebo ste doručili, sa zobrazia tu.',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                    textAlign: TextAlign.center,
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
              final status = order['status'] as String?;
              return _OrderCard(
                order: order,
                statusLabel: _statusLabel(status),
                statusColor: _statusColor(status),
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
  });
  final Map<String, dynamic> order;
  final String statusLabel;
  final Color statusColor;

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
        onTap: () => Get.to(() => DriverOrderDetailPage(order: order)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: statusColor,
                    child: const Icon(Icons.local_shipping, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
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
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: statusColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

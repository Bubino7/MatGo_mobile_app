import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_models/shared_models.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import '../services/orders_service.dart';

/// Správa objednávok pre admina.
class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  String? _filterStatus;

  static String _statusLabel(String? status) {
    switch (status) {
      case OrderStatus.pendingShop:
        return 'Čaká na stavebninu';
      case OrderStatus.confirmed:
        return 'Schválená';
      case OrderStatus.assigned:
        return 'Priradený vodič';
      case OrderStatus.pickedUp:
        return 'Vyzdvihnutá';
      case OrderStatus.delivered:
        return 'Doručená';
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
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _confirmCancel(BuildContext context, Map<String, dynamic> order) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Zrušiť objednávku?'),
        content: Text('Naozaj chcete zrušiť objednávku od ${order['clientEmail']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Späť'),
          ),
          TextButton(
            onPressed: () async {
              await Get.find<OrdersService>().cancelOrder(order['id'] as String);
              if (context.mounted) Navigator.of(ctx).pop();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Zrušiť'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Správa objednávok'),
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black,
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Ľavý panel – Filtre
          Expanded(
            flex: 1,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                border: Border(right: BorderSide(color: Colors.grey.shade300)),
              ),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Filter podľa stavu',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildFilterChip(null, 'Všetky'),
                  _buildFilterChip(OrderStatus.pendingShop, 'Čaká na stavebninu'),
                  _buildFilterChip(OrderStatus.confirmed, 'Schválená'),
                  _buildFilterChip(OrderStatus.assigned, 'Priradený vodič'),
                  _buildFilterChip(OrderStatus.pickedUp, 'Vyzdvihnutá'),
                  _buildFilterChip(OrderStatus.delivered, 'Doručená'),
                  _buildFilterChip(OrderStatus.cancelled, 'Zrušená'),
                ],
              ),
            ),
          ),
          // Pravá časť – Zoznam
          Expanded(
            flex: 4,
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: Get.find<OrdersService>().allOrdersStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final allOrders = snapshot.data ?? [];
                final filteredOrders = _filterStatus == null
                    ? allOrders
                    : allOrders.where((o) => o['status'] == _filterStatus).toList();

                if (filteredOrders.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(24),
                  itemCount: filteredOrders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final order = filteredOrders[index];
                    return _OrderListTile(
                      order: order,
                      statusColor: _statusColor(order['status'] as String?),
                      statusLabel: _statusLabel(order['status'] as String?),
                      onCancel: () => _confirmCancel(context, order),
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

  Widget _buildFilterChip(String? status, String label) {
    final isSelected = _filterStatus == status;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _filterStatus = selected ? status : null;
          });
        },
        selectedColor: Colors.amber.shade200,
        backgroundColor: Colors.white,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Žiadne objednávky',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

class _OrderListTile extends StatelessWidget {
  final Map<String, dynamic> order;
  final Color statusColor;
  final String statusLabel;
  final VoidCallback onCancel;

  const _OrderListTile({
    required this.order,
    required this.statusColor,
    required this.statusLabel,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final createdAt = order['createdAt'] as Timestamp?;
    final dateStr = createdAt != null 
        ? '${createdAt.toDate().day}.${createdAt.toDate().month}. ${createdAt.toDate().year}' 
        : '—';
    final total = (order['total'] as num?)?.toDouble() ?? 0.0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order['clientEmail'] as String? ?? 'Anonymný zákazník',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Obchod: ${order['shopName'] ?? order['shopId']}',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${total.toStringAsFixed(2)} €',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  Text(
                    dateStr,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 16),
            if (order['status'] != OrderStatus.cancelled && order['status'] != OrderStatus.delivered)
              IconButton(
                icon: const Icon(Icons.cancel, color: Colors.red),
                tooltip: 'Zrušiť objednávku',
                onPressed: onCancel,
              ),
          ],
        ),
      ),
    );
  }
}

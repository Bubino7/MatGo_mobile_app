import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_models/shared_models.dart';
import '../services/orders_service.dart';
import 'portal_order_detail_page.dart';

/// Zoznam objednávok – ľavý panel filter podľa stavu, pravý zoznam položiek. Klik otvorí detail.
class PortalOrdersPage extends StatefulWidget {
  const PortalOrdersPage({
    super.key,
    required this.shopId,
    required this.shopName,
  });
  final String shopId;
  final String shopName;

  @override
  State<PortalOrdersPage> createState() => _PortalOrdersPageState();
}

class _PortalOrdersPageState extends State<PortalOrdersPage> {
  /// null = Všetky, inak filter podľa daného stavu
  String? _filterStatus;

  static String _statusLabel(String? status) {
    if (status == null) return 'Všetky';
    switch (status) {
      case OrderStatus.pendingShop:
        return 'Čaká na schválenie';
      case OrderStatus.confirmed:
        return 'Schválené';
      case OrderStatus.assigned:
        return 'Priradené vodičovi';
      case OrderStatus.pickedUp:
        return 'Vodič doručuje';
      case OrderStatus.delivered:
        return 'Doručené';
      case OrderStatus.cancelled:
        return 'Zrušené';
      default:
        return status;
    }
  }

  static const List<String?> _filterOptions = [
    null,
    OrderStatus.pendingShop,
    OrderStatus.confirmed,
    OrderStatus.assigned,
    OrderStatus.pickedUp,
    OrderStatus.delivered,
    OrderStatus.cancelled,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('MatGo – ${widget.shopName}'),
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 1,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                border: Border(right: BorderSide(color: Colors.grey.shade300)),
              ),
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                children: [
                  Text(
                    'Filter podľa stavu',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 8),
                  ..._filterOptions.map((status) {
                    final isSelected = _filterStatus == status;
                    return Material(
                      color: Colors.transparent,
                      child: ListTile(
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                        title: Text(
                          _statusLabel(status),
                          style: TextStyle(
                            fontSize: 13,
                            color: isSelected ? Colors.amber.shade800 : Colors.grey.shade800,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                        leading: Radio<String?>(
                          value: status,
                          groupValue: _filterStatus,
                          onChanged: (v) => setState(() => _filterStatus = v),
                          activeColor: Colors.amber.shade700,
                        ),
                        onTap: () => setState(() => _filterStatus = status),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: Get.find<OrdersService>().ordersStream(widget.shopId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  debugPrint('=== Firestore orders error ===');
                  debugPrint(snapshot.error.toString());
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
                final allOrders = snapshot.data ?? [];
                final orders = _filterStatus == null
                    ? allOrders
                    : allOrders.where((o) => (o['status'] as String?) == _filterStatus).toList();
                if (orders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          allOrders.isEmpty ? 'Žiadne objednávky' : 'Žiadne objednávky v tomto stave',
                          style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          allOrders.isEmpty
                              ? 'Objednávky od zákazníkov sa zobrazia tu.'
                              : 'Zmeňte filter v ľavom paneli.',
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
                    final orderId = order['id'] as String? ?? '';
                    return _OrderListTile(
                      order: order,
                      onTap: () => Get.to(() => PortalOrderDetailPage(
                            orderId: orderId,
                            shopId: widget.shopId,
                            shopName: widget.shopName,
                          )),
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

class _OrderListTile extends StatelessWidget {
  const _OrderListTile({required this.order, required this.onTap});
  final Map<String, dynamic> order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = order['status'] as String?;
    final clientEmail = order['clientEmail'] as String? ?? '—';
    final total = (order['total'] as num?)?.toDouble() ?? 0;
    final items = order['items'] as List<dynamic>? ?? [];
    final createdAt = order['createdAt'];
    DateTime? date = MatGoUtils.parseDate(createdAt);
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
                backgroundColor: _statusColor(status),
                child: const Icon(Icons.receipt_long, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clientEmail,
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
                        color: _statusColor(status).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _statusLabel(status),
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _statusColor(status)),
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
                  Icon(Icons.chevron_right, color: Colors.grey.shade500),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

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

  Color _statusColor(String? status) {
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
}

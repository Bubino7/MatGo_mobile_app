import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_models/shared_models.dart';
import '../services/auth_service.dart';
import '../services/orders_service.dart';

/// Detail objednávky – prehľad a zmena stavu.
///
/// Flow: Klient vytvorí → Čaká na schválenie → Stavebnína schváli (máme na sklade) →
/// Vodič sa v driver_app prihlási o objednávku → Stavebnína označí „Vyzdvihnuté“ (vodič doručuje) →
/// Vodič v aplikácii potvrdí doručenie.
class PortalOrderDetailPage extends StatelessWidget {
  const PortalOrderDetailPage({
    super.key,
    required this.orderId,
    required this.shopId,
    required this.shopName,
  });
  final String orderId;
  final String shopId;
  final String shopName;

  static String statusLabel(String? status) {
    switch (status) {
      case OrderStatus.pendingShop:
        return 'Čaká na schválenie (máme na sklade?)';
      case OrderStatus.confirmed:
        return 'Schválená (vodič sa môže prihlásiť)';
      case OrderStatus.assigned:
        return 'Priradená vodičovi (čaká na vyzdvihnutie)';
      case OrderStatus.pickedUp:
        return 'Vyzdvihnuté (vodič doručuje)';
      case OrderStatus.delivered:
        return 'Doručené (vodič potvrdil)';
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

  static String _formatDateTime(dynamic v) {
    final d = MatGoUtils.parseDate(v);
    if (d == null) return '—';
    return '${d.day}.${d.month}.${d.year} ${d.hour}:${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('MatGo – Objednávka #${orderId.length > 8 ? orderId.substring(0, 8) : orderId}'),
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: Get.find<OrdersService>().orderStream(orderId),
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
          final order = snapshot.data;
          if (order == null) {
            return const Center(child: Text('Objednávka sa nenašla.'));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SectionCard(
                  title: 'Stav',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: _statusColor(order['status']).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          statusLabel(order['status'] as String?),
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _statusColor(order['status'])),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: _StatusActionButtons(order: order),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Vytvorené: ${_formatDateTime(order['createdAt'])}',
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                              ),
                              Text(
                                'Upravené: ${_formatDateTime(order['updatedAt'])}',
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _HighlightSection(
                          title: 'Zákazník',
                          icon: Icons.person_outline,
                          color: Colors.orange.shade50,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _row('Meno', order['clientName'] as String? ?? '—'),
                              _row('Email', order['clientEmail'] as String? ?? '—'),
                              if (order['clientPhone'] != null) _row('Telefón', order['clientPhone'] as String),
                            ],
                          ),
                        ),
                      ),
                      if (order['driverId'] != null) ...[
                        const SizedBox(width: 16),
                        Expanded(
                          child: _HighlightSection(
                            title: 'Vodič',
                            icon: Icons.local_shipping_outlined,
                            color: Colors.amber.shade100,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _row('Meno', order['driverName'] as String? ?? '—'),
                                if (order['driverPhone'] != null) _row('Telefón', order['driverPhone'] as String),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Doručovacia adresa',
                  child: _AddressBlock(map: order['deliveryAddress'] as Map<String, dynamic>?),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Adresa vyzdvihnutia',
                  child: _AddressBlock(map: order['pickupAddress'] as Map<String, dynamic>?),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Položky (${MatGoUtils.formatItemsCount(order['items']?.length ?? 0)})',
                  child: _ItemsTable(items: order['items'] as List<dynamic>? ?? []),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Súhrn',
                  child: _SummaryRows(order: order),
                ),
                if ((order['noteFromClient'] as String?)?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Poznámka od zákazníka',
                    child: Text(order['noteFromClient'] as String? ?? ''),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatusActionButtons extends StatelessWidget {
  const _StatusActionButtons({required this.order});
  final Map<String, dynamic> order;

  Future<void> _confirmAndUpdate(
    BuildContext context, {
    required String title,
    required String message,
    required String newStatus,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Zrušiť'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
            child: const Text('Áno, potvrdzujem'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      final uid = Get.find<AuthService>().currentUser?.uid;
      await Get.find<OrdersService>().updateOrderStatus(
        order['id'] as String,
        newStatus,
        confirmedByUserId: uid,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Stav zmenený: ${PortalOrderDetailPage.statusLabel(newStatus)}'),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chyba: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentStatus = order['status'] as String? ?? OrderStatus.pendingShop;
    final buttons = <Widget>[];

    if (currentStatus == OrderStatus.pendingShop) {
      buttons.add(
        FilledButton.icon(
          onPressed: () => _confirmAndUpdate(
            context,
            title: 'Schváliť objednávku',
            message: 'Naozaj schváliť objednávku? Tým potvrdzujete, že máte tovar na sklade. Objednávka sa zviditeľní vodičom v aplikácii.',
            newStatus: OrderStatus.confirmed,
          ),
          icon: const Icon(Icons.check_circle_outline),
          label: const Text('Schváliť objednávku'),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.green.shade700,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          ),
        ),
      );
      buttons.add(
        OutlinedButton.icon(
          onPressed: () => _confirmAndUpdate(
            context,
            title: 'Zrušiť objednávku',
            message: 'Naozaj zrušiť túto objednávku? Táto akcia sa nedá vrátiť späť.',
            newStatus: OrderStatus.cancelled,
          ),
          icon: const Icon(Icons.cancel_outlined),
          label: const Text('Zrušiť objednávku'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red.shade700,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          ),
        ),
      );
    } else if (currentStatus == OrderStatus.confirmed || currentStatus == OrderStatus.assigned) {
      final hasDriver = order['driverId'] != null;
      buttons.add(
        FilledButton.icon(
          onPressed: hasDriver
              ? () => _confirmAndUpdate(
                    context,
                    title: 'Vodič vyzdvihol',
                    message: 'Naozaj označiť ako vyzdvihnuté? Vodič prebral tovar a doručuje zákazníkovi.',
                    newStatus: OrderStatus.pickedUp,
                  )
              : null, // Deaktivované ak nie je vodič
          icon: const Icon(Icons.local_shipping_outlined),
          label: const Text('Vodič vyzdvihol'),
          style: FilledButton.styleFrom(
            backgroundColor: hasDriver ? Colors.amber.shade700 : Colors.grey.shade300,
            foregroundColor: hasDriver ? Colors.black : Colors.grey.shade600,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          ),
        ),
      );
      if (!hasDriver) {
        buttons.add(
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Čaká sa na priradenie vodiča...',
              style: TextStyle(fontSize: 12, color: Colors.orange.shade800, fontStyle: FontStyle.italic),
            ),
          ),
        );
      }
      if (currentStatus == OrderStatus.confirmed) {
        buttons.add(
          OutlinedButton.icon(
            onPressed: () => _confirmAndUpdate(
              context,
              title: 'Zrušiť objednávku',
              message: 'Naozaj zrušiť túto objednávku? Táto akcia sa nedá vrátiť späť.',
              newStatus: OrderStatus.cancelled,
            ),
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Zrušiť objednávku'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red.shade700,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            ),
          ),
        );
      }
    } else if (currentStatus == OrderStatus.pickedUp || currentStatus == OrderStatus.delivered) {
      buttons.add(
        Text(
          currentStatus == OrderStatus.pickedUp
              ? 'Vodič doručuje. Doručenie potvrdí vodič v aplikácii.'
              : 'Objednávka bola doručená.',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
      );
    } else if (currentStatus == OrderStatus.cancelled) {
      buttons.add(
        Text(
          'Objednávka bola zrušená.',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: buttons,
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

Widget _row(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            '$label:',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
        ),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
      ],
    ),
  );
}

class _HighlightSection extends StatelessWidget {
  const _HighlightSection({required this.title, required this.icon, required this.child, required this.color});
  final String title;
  final IconData icon;
  final Widget child;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: Colors.grey.shade700),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _AddressBlock extends StatelessWidget {
  const _AddressBlock({this.map});
  final Map<String, dynamic>? map;

  @override
  Widget build(BuildContext context) {
    final a = OrderAddress.fromMap(map);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(a.displayLine, style: const TextStyle(fontSize: 14)),
        if (a.note != null && a.note!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text('Poznámka: ${a.note}', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          ),
      ],
    );
  }
}

class _ItemsTable extends StatelessWidget {
  const _ItemsTable({required this.items});
  final List<dynamic> items;

  @override
  Widget build(BuildContext context) {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(3),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1),
      },
      children: [
        TableRow(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('Položka', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey.shade700)),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('Množstvo', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey.shade700)),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('Suma', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey.shade700)),
            ),
          ],
        ),
        ...items.map<TableRow>((e) {
          final m = e is Map<String, dynamic> ? e : <String, dynamic>{};
          final name = m['productName'] as String? ?? '—';
          final qty = m['quantity'] as int? ?? 0;
          final unit = m['unit'] as String? ?? 'ks';
          final line = (m['lineTotal'] as num?)?.toDouble() ?? 0;
          return TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(name, style: const TextStyle(fontSize: 14)),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('$qty $unit', style: const TextStyle(fontSize: 14)),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('${line.toStringAsFixed(2)} €', style: const TextStyle(fontSize: 14)),
              ),
            ],
          );
        }),
      ],
    );
  }
}

class _SummaryRows extends StatelessWidget {
  const _SummaryRows({required this.order});
  final Map<String, dynamic> order;

  @override
  Widget build(BuildContext context) {
    final subtotal = (order['subtotal'] as num?)?.toDouble() ?? 0;
    final shipping = (order['shippingCost'] as num?)?.toDouble() ?? 0;
    final tax = (order['taxAmount'] as num?)?.toDouble() ?? 0;
    final total = (order['total'] as num?)?.toDouble() ?? 0;
    return Column(
      children: [
        _row('Medzisúčet', '${subtotal.toStringAsFixed(2)} €'),
        _row('Doprava', '${shipping.toStringAsFixed(2)} €'),
        _row('DPH', '${tax.toStringAsFixed(2)} €'),
        const Divider(height: 20),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Spolu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text('${total.toStringAsFixed(2)} €', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }
}

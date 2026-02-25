import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_models/shared_models.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html;
import '../services/orders_service.dart';

/// Stránka s náhľadom jednej objednávky – položky, sumy, stav, dátum.
class OrderDetailPage extends StatelessWidget {
  const OrderDetailPage({super.key, required this.order});
  final Map<String, dynamic> order;

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

  static String _deliveryAddressString(Map<String, dynamic> order) {
    final addr = order['deliveryAddress'];
    if (addr == null || addr is! Map) return '';
    final m = Map<String, dynamic>.from(addr);
    final street = m['street'] as String? ?? '';
    final city = m['city'] as String? ?? '';
    final zip = m['zip'] as String? ?? '';
    if (street.isEmpty && city.isEmpty && zip.isEmpty) return '';
    return 'Doručenie: ${[street, '$zip $city'.trim()].where((s) => s.isNotEmpty).join(', ')}';
  }

  @override
  Widget build(BuildContext context) {
    final shopName = order['shopName'] as String? ?? 'Objednávka';
    final status = order['status'] as String?;
    final createdAt = order['createdAt'];
    final date = MatGoUtils.parseDate(createdAt);
    final dateStr = date != null
        ? '${date.day}.${date.month}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}'
        : '—';
    final subtotal = (order['subtotal'] as num?)?.toDouble() ?? 0;
    final shipping = (order['shippingCost'] as num?)?.toDouble() ?? 0;
    final tax = (order['taxAmount'] as num?)?.toDouble() ?? 0;
    final total = (order['total'] as num?)?.toDouble() ?? 0;
    final items = order['items'] as List<dynamic>? ?? [];

    final statusColor = _statusColor(status);

    return Scaffold(
      appBar: AppBar(
        title: Text(shopName),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Get.back()),
      ),
      body: Column(
        children: [
          // Scrollovateľná časť: hlavička + položky
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Hlavička: dátum + stav
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: statusColor.withOpacity(0.5), width: 1),
                    ),
                    color: statusColor.withOpacity(0.12),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.receipt_long, color: statusColor, size: 28),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      dateStr,
                                      style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _statusLabel(status),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: statusColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${total.toStringAsFixed(2)} €',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ) ?? const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          if (_deliveryAddressString(order).isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              _deliveryAddressString(order),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                                height: 1.3,
                              ),
                            ),
                          ],
                          if (order['driverId'] != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.person, size: 16, color: Colors.grey.shade700),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Vodič: ${order['driverName'] ?? 'Priradený'}',
                                          style: TextStyle(fontSize: 12, color: Colors.grey.shade800, fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (order['driverPhone'] != null) ...[
                                    const SizedBox(height: 10),
                                    InkWell(
                                      onTap: () async {
                                        final telUrl = 'tel:${order['driverPhone']}';
                                        if (kIsWeb) {
                                          try {
                                            await launchUrl(Uri.parse(telUrl));
                                          } catch (e) {
                                            html.window.open(telUrl, '_self');
                                          }
                                        } else {
                                          final Uri telUri = Uri.parse(telUrl);
                                          if (await canLaunchUrl(telUri)) {
                                            await launchUrl(telUri);
                                          }
                                        }
                                      },
                                      child: Row(
                                        children: [
                                          Icon(Icons.phone, size: 16, color: Colors.green.shade700),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Volať vodičovi: ${order['driverPhone']}',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Colors.black87,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Nadpis sekcie položiek
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 12),
                    child: Text(
                      'Položky (${MatGoUtils.formatItemsCount(items.length)})',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                          ) ?? TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey.shade800),
                    ),
                  ),

                  // Zoznam položiek
                  if (items.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'Žiadne položky',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ),
                    )
                  else
                    ...items.asMap().entries.map((entry) {
                      final raw = entry.value;
                      final m = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
                      final name = m['productName'] as String? ?? '—';
                      final qty = m['quantity'] as int? ?? 0;
                      final unit = m['unit'] as String?;
                      final unitStr = (unit != null && unit.isNotEmpty) ? ' $unit' : ' ks';
                      final pricePerUnit = (m['pricePerUnit'] as num?)?.toDouble() ?? 0;
                      final lineTotal = (m['lineTotal'] as num?)?.toDouble() ?? 0;
                      final index = entry.key + 1;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade400, width: 1),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$index',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Colors.amber.shade800,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$qty$unitStr × ${pricePerUnit.toStringAsFixed(2)} €',
                                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${lineTotal.toStringAsFixed(2)} €',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),

                  // Tlačidlo na zrušenie objednávky (iba ak je v počiatočnom stave)
                  if (status == OrderStatus.pendingShop)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: OutlinedButton.icon(
                        onPressed: () => _confirmCancel(context, order['id']),
                        icon: const Icon(Icons.cancel_outlined),
                        label: const Text('Zrušiť objednávku'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade700,
                          side: BorderSide(color: Colors.red.shade200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Sekcia „Spolu“ pripevnená na spodku
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _SummaryRow(label: 'Medzisúčet', value: subtotal),
                  const SizedBox(height: 10),
                  _SummaryRow(label: 'Doprava', value: shipping),
                  const SizedBox(height: 10),
                  _SummaryRow(label: 'DPH (10 %)', value: tax),
                  const Divider(height: 24),
                  _SummaryRow(
                    label: 'Spolu',
                    value: total,
                    bold: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmCancel(BuildContext context, String orderId) async {
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
            const Icon(Icons.cancel_outlined, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Zrušiť objednávku?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Naozaj chcete zrušiť túto objednávku? Táto akcia je nevratná.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
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
                    child: const Text('SPÄŤ'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Get.back(result: true),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('ÁNO, ZRUŠIŤ'),
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
        await Get.find<OrdersService>().cancelOrder(orderId);
        if (context.mounted) {
          Get.back(); // Návrat zo stránky detailu
          Get.snackbar(
            'Objednávka',
            'Objednávka bola zrušená',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red.shade100,
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Chyba pri rušení: $e')));
        }
      }
    }
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value, this.bold = false});
  final String label;
  final double value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: bold ? 16 : 14,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color: Colors.grey.shade800,
          ),
        ),
        Text(
          '${value.toStringAsFixed(2)} €',
          style: TextStyle(
            fontSize: bold ? 18 : 14,
            fontWeight: FontWeight.w600,
            color: bold ? Colors.black87 : Colors.grey.shade800,
          ),
        ),
      ],
    );
  }
}

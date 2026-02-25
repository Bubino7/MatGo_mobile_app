import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_models/shared_models.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
// Použijeme univerzálny spôsob pre web bez nutnosti pluginu ak url_launcher zlyhá
import 'dart:html' as html;
import '../services/orders_service.dart';

class DriverOrderDetailPage extends StatelessWidget {
  const DriverOrderDetailPage({super.key, required this.order});
  final Map<String, dynamic> order;

  static String _statusLabel(String? status) {
    switch (status) {
      case OrderStatus.assigned:
        return 'Priradená – vyzdvihnite tovar';
      case OrderStatus.pickedUp:
        return 'Vyzdvihnutá – doručujte zákazníkovi';
      case OrderStatus.delivered:
        return 'Doručená zákazníkovi';
      case OrderStatus.cancelled:
        return 'Objednávka bola zrušená';
      default:
        return status ?? '—';
    }
  }

  static Color _statusColor(String? status) {
    switch (status) {
      case OrderStatus.assigned:
      case OrderStatus.pickedUp:
      case OrderStatus.delivered:
        return Colors.amber;
      case OrderStatus.cancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _openMap(String address) async {
    final query = Uri.encodeComponent(address);
    final googleUrl = 'https://www.google.com/maps/search/?api=1&query=$query';
    
    if (kIsWeb) {
      // Na webe skúsime najprv url_launcher, ale ak zlyhá plugin bridge, použijeme html.window
      try {
        await launchUrl(Uri.parse(googleUrl), mode: LaunchMode.externalApplication);
      } catch (e) {
        debugPrint('url_launcher failed, using window.open: $e');
        html.window.open(googleUrl, '_blank');
      }
    } else {
      // Pre mobilné platformy
      try {
        await launchUrl(Uri.parse(googleUrl), mode: LaunchMode.externalApplication);
      } catch (e) {
        final appleUrl = 'https://maps.apple.com/?q=$query';
        await launchUrl(Uri.parse(appleUrl), mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderId = order['id'] as String;

    return StreamBuilder<Map<String, dynamic>?>(
      stream: Get.find<OrdersService>().orderStream(orderId),
      initialData: order,
      builder: (context, snapshot) {
        final currentOrder = snapshot.data;
        if (currentOrder == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Detail objednávky')),
            body: const Center(child: Text('Objednávka už neexistuje.')),
          );
        }

        final status = currentOrder['status'] as String?;
        final shopName = currentOrder['shopName'] as String? ?? 'Stavebnína';
        final pickup = OrderAddress.fromMap(currentOrder['pickupAddress']);
        final delivery = OrderAddress.fromMap(currentOrder['deliveryAddress']);
        final items = currentOrder['items'] as List<dynamic>? ?? [];
        final clientPhone = currentOrder['clientPhone'] as String?;
        final color = _statusColor(status);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Detail objednávky'),
            backgroundColor: color,
            foregroundColor: status == OrderStatus.delivered ? Colors.white : Colors.black,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Stav
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Text('STAV OBJEDNÁVKY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color.computeLuminance() > 0.5 ? Colors.black54 : Colors.white70)),
                      const SizedBox(height: 4),
                      Text(_statusLabel(status), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 1. Vyzdvihnutie
                _NavCard(
                  title: '1. VYZDVIHNUTIE V STAVEBNINE',
                  subtitle: shopName,
                  address: pickup.displayLine,
                  icon: Icons.store,
                  isActive: status == OrderStatus.assigned,
                  isDone: status == OrderStatus.pickedUp || status == OrderStatus.delivered,
                  onNavTap: () => _openMap(pickup.displayLine),
                ),
                const SizedBox(height: 16),

                // 2. Doručenie
                _NavCard(
                  title: '2. DORUČENIE ZÁKAZNÍKOVI',
                  subtitle: currentOrder['clientName'] ?? 'Zákazník',
                  address: delivery.displayLine,
                  note: delivery.note,
                  icon: Icons.person_pin_circle,
                  isActive: status == OrderStatus.pickedUp,
                  isDone: status == OrderStatus.delivered,
                  onNavTap: () => _openMap(delivery.displayLine),
                  trailing: clientPhone != null
                      ? IconButton(
                          icon: const Icon(Icons.phone, color: Colors.green),
                          onPressed: () async {
                            final telUrl = 'tel:$clientPhone';
                            if (kIsWeb) {
                              try {
                                await launchUrl(Uri.parse(telUrl));
                              } catch (e) {
                                html.window.open(telUrl, '_self');
                              }
                            } else {
                              await launchUrl(Uri.parse(telUrl));
                            }
                          },
                        )
                      : null,
                ),
                const SizedBox(height: 24),

                // Položky
                Text(
                  'POLOŽKY (${MatGoUtils.formatItemsCount(items.length)})',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                ...items.map((it) {
                  final name = it['productName'] ?? '—';
                  final qty = it['quantity'] ?? 0;
                  final unit = it['unit'] ?? 'ks';
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text('• $qty $unit $name', style: const TextStyle(fontSize: 14)),
                  );
                }),
                const SizedBox(height: 32),

                // Akcie
                if (status == OrderStatus.assigned)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.grey.shade700),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Čaká sa na potvrdenie vyzdvihnutia stavebninami.',
                            style: TextStyle(fontSize: 13, color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (status == OrderStatus.pickedUp)
                  FilledButton.icon(
                    onPressed: () {
                      _showConfirmDeliveryBottomSheet(context, currentOrder);
                    },
                    icon: const Icon(Icons.check_circle),
                    label: const Text('DORUČENÉ ZÁKAZNÍKOVI'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                
                if (status == OrderStatus.delivered)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.green.shade200, width: 2),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 48),
                        const SizedBox(height: 12),
                        const Text(
                          'OBJEDNÁVKA DORUČENÁ',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Doručené: ${MatGoUtils.formatDateTime(currentOrder['deliveredAt'])}',
                          style: TextStyle(fontSize: 13, color: Colors.green.shade700),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showConfirmDeliveryBottomSheet(BuildContext context, Map<String, dynamic> order) {
    Get.bottomSheet(
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
              'Potvrdiť doručenie?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Naozaj chcete potvrdiť, že ste objednávku doručili zákazníkovi?',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.back(),
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
                    onPressed: () {
                      Get.back();
                      Get.find<OrdersService>().markDelivered(order['id']);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('POTVRDIŤ'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }
}

class _NavCard extends StatelessWidget {
  const _NavCard({
    required this.title,
    required this.subtitle,
    required this.address,
    this.note,
    required this.icon,
    required this.onNavTap,
    this.isActive = false,
    this.isDone = false,
    this.trailing,
  });

  final String title, subtitle, address;
  final String? note;
  final IconData icon;
  final VoidCallback onNavTap;
  final bool isActive;
  final bool isDone;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final bgColor = isActive ? Colors.white : Colors.grey.shade100;
    final borderColor = isActive ? Colors.black87 : Colors.grey.shade300;
    final titleColor = isActive ? Colors.black54 : Colors.grey.shade500;
    final subtitleSize = isActive ? 17.0 : 14.0;
    final padding = isActive ? 20.0 : 14.0;

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: isActive ? 1.5 : 1,
        ),
        boxShadow: isActive
            ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 6))]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: titleColor)),
              if (isDone) ...[
                const SizedBox(width: 8),
                Icon(Icons.check_circle, size: 12, color: Colors.grey.shade600),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(icon, color: isActive ? Colors.amber.shade800 : Colors.grey.shade400, size: isActive ? 28 : 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(subtitle, style: TextStyle(fontWeight: FontWeight.bold, fontSize: subtitleSize, color: isActive ? Colors.black : Colors.grey.shade700)),
                    Text(address, style: TextStyle(color: isActive ? Colors.grey.shade800 : Colors.grey.shade600, fontSize: isActive ? 14 : 12)),
                    if (note != null && note!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Poznámka: $note',
                        style: TextStyle(
                          fontSize: isActive ? 13 : 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.red.shade800,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) 
                Opacity(opacity: isActive ? 1.0 : 0.5, child: trailing!),
            ],
          ),
          if (isActive) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onNavTap,
                icon: const Icon(Icons.navigation, size: 18),
                label: const Text('NAVIGOVAŤ'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.blue.shade800,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 8),
            Text(isDone ? '(Dokončené)' : '(Nasledujúci krok)', style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontStyle: FontStyle.italic)),
          ],
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_models/shared_models.dart';

import '../controllers/cart_controller.dart';
import '../models/cart_item.dart';
import '../services/auth_service.dart';
import '../services/orders_service.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  static const double _shippingCost = 5.00;
  static const double _taxRate = 0.10; // 10% DPH

  OrderAddress? _deliveryAddress;

  @override
  Widget build(BuildContext context) {
    final CartController cart = Get.find<CartController>();
    final subtotal = cart.totalPrice;
    final taxes = (subtotal + _shippingCost) * _taxRate;
    final total = subtotal + _shippingCost + taxes;

    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade900,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Platba',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Obx(() {
        if (cart.cartItems.isEmpty) {
          return const Center(
            child: Text('Košík je prázdny. Pridajte položky.'),
          );
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildOptionsCard(context, cart),
              const SizedBox(height: 16),
              _buildItemsCard(cart),
              const SizedBox(height: 16),
              _buildSummaryCard(
                itemCount: cart.cartItems.length,
                subtotal: subtotal,
                shipping: _shippingCost,
                taxes: taxes,
                total: total,
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: () => _placeOrder(context, cart),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Objednať'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildOptionsCard(BuildContext context, CartController cart) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => _showAddressDialog(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'ADRESA',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: SizedBox(
                            height: 20,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                _deliveryAddress?.displayLine ?? 'Zadajte adresu',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _deliveryAddress == null ? Colors.grey : Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.end,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.chevron_right, size: 20, color: Colors.grey.shade600),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          _divider(),
          _optionRow('DORUČENIE', 'Čo najskôr', Icons.chevron_right),
          _divider(),
          _optionRow('PLATBA', 'Visa *1234', Icons.chevron_right),
          _divider(),
          _optionRow('PROMOS', 'Zadaj promo kód', Icons.chevron_right),
        ],
      ),
    );
  }

  void _showAddressDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    String street = _deliveryAddress?.street ?? '';
    String city = _deliveryAddress?.city ?? '';
    String zip = _deliveryAddress?.zip ?? '';
    String country = _deliveryAddress?.country ?? 'SK';
    String note = _deliveryAddress?.note ?? '';

    final screenWidth = MediaQuery.of(context).size.width;
    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            insetPadding: EdgeInsets.symmetric(
              horizontal: screenWidth > 600 ? 80 : 20,
              vertical: 24,
            ),
            contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            title: const Text('Doručovacia adresa'),
            content: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: screenWidth > 600 ? 500 : double.infinity),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      initialValue: street,
                      decoration: const InputDecoration(
                        labelText: 'Ulica a číslo *',
                        hintText: 'Hlavná 1',
                      ),
                      onChanged: (v) => street = v,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Zadajte ulicu' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            initialValue: zip,
                            decoration: const InputDecoration(labelText: 'PSČ *', hintText: '811 01'),
                            keyboardType: TextInputType.number,
                            onChanged: (v) => zip = v,
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Zadajte PSČ' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            initialValue: city,
                            decoration: const InputDecoration(labelText: 'Mesto *', hintText: 'Bratislava'),
                            onChanged: (v) => city = v,
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Zadajte mesto' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: country.isEmpty ? 'SK' : country,
                      decoration: const InputDecoration(labelText: 'Krajina'),
                      items: const [
                        DropdownMenuItem(value: 'SK', child: Text('Slovensko')),
                        DropdownMenuItem(value: 'CZ', child: Text('Česko')),
                      ],
                      onChanged: (v) => setDialogState(() => country = v ?? 'SK'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: note,
                      decoration: const InputDecoration(
                        labelText: 'Poznámka (voliteľné)',
                        hintText: 'Zvonček, poschodie...',
                      ),
                      maxLines: 2,
                      onChanged: (v) => note = v,
                    ),
                  ],
                ),
              ),
            ),
          ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Zrušiť'),
              ),
              FilledButton(
                onPressed: () {
                  if (!formKey.currentState!.validate()) return;
                  setState(() {
                    _deliveryAddress = OrderAddress(
                      street: street.trim(),
                      city: city.trim(),
                      zip: zip.trim(),
                      country: country,
                      note: note.trim().isEmpty ? null : note.trim(),
                    );
                  });
                  Navigator.of(ctx).pop();
                },
                style: FilledButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
                child: const Text('Použiť'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _optionRow(String label, String value, IconData trailingIcon) {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
                letterSpacing: 0.5,
              ),
            ),
            const Spacer(),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: SizedBox(
                      height: 20,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          value,
                          style: TextStyle(
                            fontSize: 14,
                            color: value == 'Zadajte adresu' || value == 'Zadaj promo kód'
                                ? Colors.grey
                                : Colors.black87,
                          ),
                          textAlign: TextAlign.end,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(trailingIcon, size: 20, color: Colors.grey.shade600),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() => Divider(height: 1, color: Colors.grey.shade200);

  Widget _buildItemsCard(CartController cart) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'POLOŽKY',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'DETAIL',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'CENA',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          ...cart.cartItems.map((item) => _buildOrderItemRow(item)),
        ],
      ),
    );
  }

  Widget _buildOrderItemRow(CartItem item) {
    final p = item.product;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: p.imagePath != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      p.imagePath!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.inventory_2,
                        color: Colors.amber,
                        size: 28,
                      ),
                    ),
                  )
                : const Icon(Icons.inventory_2, color: Colors.amber, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.shopName,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  p.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  p.category,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  'Počet: ${item.quantity} ks',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '€${item.lineTotal.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required int itemCount,
    required double subtotal,
    required double shipping,
    required double taxes,
    required double total,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _summaryRow('Spolu ($itemCount)', subtotal),
          const SizedBox(height: 8),
          _summaryRow('Doprava', shipping),
          const SizedBox(height: 8),
          _summaryRow('DPH', taxes),
          const Divider(height: 24),
          _summaryRow('Total', total, bold: true),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, double value, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: bold ? 16 : 14,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            color: Colors.black87,
          ),
        ),
        Text(
          '€${value.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: bold ? 18 : 14,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Future<void> _placeOrder(BuildContext context, CartController cart) async {
    if (_deliveryAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Najprv zadajte doručovaciu adresu.'),
          backgroundColor: Colors.orange,
        ),
      );
      _showAddressDialog(context);
      return;
    }

    final user = Get.find<AuthService>().currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Musíte byť prihlásený.'), backgroundColor: Colors.red),
      );
      return;
    }

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
            const Icon(Icons.shopping_cart_checkout, size: 48, color: Colors.amber),
            const SizedBox(height: 16),
            const Text(
              'Odoslať objednávku?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Naozaj chcete odoslať objednávku? Stavebnína ju následne spracuje a ozve sa vám.',
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
                    child: const Text('ZRUŠIŤ'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Get.back(result: true),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('ÁNO, ODOSLAŤ'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
    if (confirmed != true || !context.mounted) return;

    try {
      final ordersService = Get.find<OrdersService>();
      final count = await ordersService.placeOrder(
        cartItems: cart.cartItems,
        deliveryAddress: _deliveryAddress!,
        clientUserId: user.uid,
        clientEmail: user.email ?? '',
        noteFromClient: null,
      );
      if (!context.mounted) return;
      cart.clearCart();
      Get.back();
      Get.snackbar(
        'Objednávka',
        count > 0
            ? 'Objednávka bola odoslaná. Ďakujeme!${count > 1 ? ' ($count objednávok)' : ''}'
            : 'Nič nebolo odoslané.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100,
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Chyba pri odosielaní: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

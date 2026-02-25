import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/shops_service.dart';

class ShopsPage extends StatelessWidget {
  const ShopsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final shopsStream = Get.find<ShopsService>().shopsStream;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dostupné stavebniny'),
        backgroundColor: Colors.amber,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: shopsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Žiadne obchody v okolí'));
          }

          final shops = snapshot.data!;

          return ListView.builder(
            itemCount: shops.length,
            itemBuilder: (context, index) {
              final shop = shops[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: _ShopLeading(imageUrl: shop['imageUrl'] as String?),
                  title: Text(
                    shop['name'] ?? 'Obchod',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Otváram produkty... (Coming soon)")),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ShopLeading extends StatelessWidget {
  const _ShopLeading({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    const fallback = Icon(Icons.store, color: Colors.amber);
    final hasUrl = imageUrl != null && imageUrl!.isNotEmpty;
    if (!hasUrl) {
      return CircleAvatar(backgroundColor: Colors.amber.shade100, child: fallback);
    }
    final url = imageUrl!;
    if (url.startsWith('data:')) {
      try {
        final base64 = url.contains(',') ? url.split(',').last : url;
        final bytes = base64Decode(base64);
        return CircleAvatar(
          backgroundColor: Colors.amber.shade100,
          child: ClipOval(
            child: Image.memory(
              bytes,
              fit: BoxFit.contain,
              width: 48,
              height: 48,
              errorBuilder: (_, __, ___) => fallback,
            ),
          ),
        );
      } catch (_) {
        return CircleAvatar(backgroundColor: Colors.amber.shade100, child: fallback);
      }
    }
    return CircleAvatar(
      backgroundColor: Colors.amber.shade100,
      child: ClipOval(
        child: Image.network(
          url,
          fit: BoxFit.contain,
          width: 48,
          height: 48,
          errorBuilder: (_, __, ___) => fallback,
        ),
      ),
    );
  }
}

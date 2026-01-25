import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Stránka so zoznamom obchodov (pôvodný obsah HomeScreen)
class ShopsPage extends StatelessWidget {
  const ShopsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dostupné stavebniny'),
        backgroundColor: Colors.amber,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('shops').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Žiadne obchody v okolí'));
          }

          final shops = snapshot.data!.docs;

          return ListView.builder(
            itemCount: shops.length,
            itemBuilder: (context, index) {
              final shop = shops[index].data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.black12,
                    child: Icon(Icons.store),
                  ),
                  title: Text(
                    shop['name'] ?? 'Obchod',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(shop['address'] ?? ''),
                  onTap: () {
                    // TODO: Tu neskôr pridáme navigáciu na detail produktov
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

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Stránka profilu
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: Colors.amber,
        actions: [
          // Tlačidlo na odhlásenie
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.amber,
              child: Icon(Icons.person, size: 50, color: Colors.black),
            ),
            const SizedBox(height: 24),
            Text(
              user?.email ?? 'Neznámy užívateľ',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            // Tu môžeš neskôr pridať ďalšie možnosti profilu
            const Text(
              'Ďalšie nastavenia prídu neskôr...',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

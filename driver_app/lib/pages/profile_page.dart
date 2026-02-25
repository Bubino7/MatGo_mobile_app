import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/auth_service.dart';
import '../services/users_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _phoneController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = Get.find<AuthService>().currentUser;
    if (user != null) {
      final userData = await Get.find<UsersService>().getUser(user.uid);
      if (userData != null) {
        setState(() {
          _phoneController.text = userData['phone'] ?? '';
          _firstNameController.text = userData['firstName'] ?? '';
          _lastNameController.text = userData['lastName'] ?? '';
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    final user = Get.find<AuthService>().currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      await Get.find<UsersService>().updateProfile(
        uid: user.uid,
        phone: _phoneController.text,
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
      );
      Get.snackbar('Profil', 'Údaje boli uložené',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green.shade100);
    } catch (e) {
      Get.snackbar('Chyba', 'Nepodarilo sa uložiť údaje',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red.shade100);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Get.find<AuthService>().currentUser;
    final email = user?.email ?? '—';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: Colors.amber,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 40,
              backgroundColor: Colors.amber,
              child: Icon(Icons.local_shipping, size: 40, color: Colors.black),
            ),
            const SizedBox(height: 24),
            Text(email, style: const TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 32),
            TextField(
              controller: _firstNameController,
              decoration: const InputDecoration(labelText: 'Meno', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _lastNameController,
              decoration: const InputDecoration(labelText: 'Priezvisko', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Telefónne číslo',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                    : const Text('Uložiť profil'),
              ),
            ),
            const SizedBox(height: 40),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red.shade700),
              title: Text('Odhlásiť sa', style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w600)),
              onTap: () => Get.find<AuthService>().signOut(),
            ),
          ],
        ),
      ),
    );
  }
}

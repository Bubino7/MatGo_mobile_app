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
      if (userData != null && userData['phone'] != null) {
        setState(() {
          _phoneController.text = userData['phone'];
        });
      }
    }
  }

  Future<void> _savePhone() async {
    final user = Get.find<AuthService>().currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      await Get.find<UsersService>().updatePhoneNumber(user.uid, _phoneController.text);
      Get.snackbar('Profil', 'Telefónne číslo bolo uložené',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.green.shade100);
    } catch (e) {
      Get.snackbar('Chyba', 'Nepodarilo sa uložiť číslo',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red.shade100);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Get.find<AuthService>().currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: Colors.amber,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Get.find<AuthService>().signOut(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
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
            const SizedBox(height: 32),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Telefónne číslo',
                prefixIcon: Icon(Icons.phone),
                hintText: '+421 900 000 000',
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isLoading ? null : _savePhone,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Uložiť profil'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

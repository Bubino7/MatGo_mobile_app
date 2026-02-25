import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/auth_service.dart';
import '../services/shops_service.dart';
import '../services/users_service.dart';
import 'portal_dashboard.dart';
import 'portal_login_screen.dart';

class PortalGate extends StatelessWidget {
  const PortalGate({super.key, required this.shopId});
  final String shopId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: Get.find<AuthService>().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final user = snapshot.data;
        if (user == null) return PortalLoginScreen(shopId: shopId);
        return _AccessCheck(shopId: shopId, uid: user.uid);
      },
    );
  }
}

class _AccessCheck extends StatefulWidget {
  const _AccessCheck({required this.shopId, required this.uid});
  final String shopId;
  final String uid;

  @override
  State<_AccessCheck> createState() => _AccessCheckState();
}

class _AccessCheckState extends State<_AccessCheck> {
  bool? _hasAccess;
  String? _shopName;
  String? _userName;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkAccess();
  }

  Future<void> _checkAccess() async {
    try {
      final userDoc = await Get.find<UsersService>().getUser(widget.uid);
      final managed = userDoc?['managedShopIds'];
      final list = managed is List ? List<String>.from(managed.map((e) => e.toString())) : <String>[];
      final hasAccess = list.contains(widget.shopId);
      Map<String, dynamic>? shop;
      if (hasAccess) shop = await Get.find<ShopsService>().getShop(widget.shopId);
      String? userName;
      if (userDoc != null) {
        final first = (userDoc['firstName']?.toString())?.trim();
        final last = (userDoc['lastName']?.toString())?.trim();
        if (first != null && last != null && (first.isNotEmpty || last.isNotEmpty)) {
          userName = '$first $last'.trim();
        } else if (first != null && first.isNotEmpty) {
          userName = first;
        } else if (last != null && last.isNotEmpty) {
          userName = last;
        }
      }
      if (mounted) {
        setState(() {
          _hasAccess = hasAccess;
          _shopName = shop?['name'] as String?;
          _userName = userName;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() {
        _hasAccess = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasAccess == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_hasAccess != true) {
      return Scaffold(
        appBar: AppBar(title: const Text('Prístup odmietnutý'), backgroundColor: Colors.red.shade700),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.block, size: 64, color: Colors.red.shade300),
                const SizedBox(height: 16),
                const Text(
                  'Nemáte oprávnenie spravovať túto stavebnínu.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: TextStyle(fontSize: 12, color: Colors.grey.shade600), textAlign: TextAlign.center),
                ],
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => Get.find<AuthService>().signOut(),
                  icon: const Icon(Icons.logout),
                  label: const Text('Odhlásiť sa'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return PortalDashboard(shopId: widget.shopId, shopName: _shopName ?? 'Stavebnína', userName: _userName);
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/auth_service.dart';
import '../services/shops_service.dart';
import '../services/users_service.dart';
import '../services/orders_service.dart';
import 'users_page.dart';
import 'shops_page.dart';
import 'orders_page.dart';
import 'finances_page.dart';

/// Hlavná obrazovka po prihlásení – súhrn a odkazy na podstránky.
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MatGo Admin'),
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Get.find<AuthService>().logout(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            _buildStatsRow(context),
            const SizedBox(height: 28),
            const Text(
              'Správa',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildNavCard(
              context: context,
              icon: Icons.people,
              title: 'Správa užívateľov',
              subtitle: 'Registrovaní zákazníci',
              onTap: () => Get.to(() => const UsersPage()),
            ),
            const SizedBox(height: 12),
            _buildNavCard(
              context: context,
              icon: Icons.store,
              title: 'Správa stavebnín',
              subtitle: 'Obchody a slugy',
              onTap: () => Get.to(() => const ShopsPage()),
            ),
            const SizedBox(height: 12),
            _buildNavCard(
              context: context,
              icon: Icons.shopping_cart,
              title: 'Správa objednávok',
              subtitle: 'Zoznam a stavy objednávok',
              onTap: () => Get.to(() => const OrdersPage()),
            ),
            const SizedBox(height: 12),
            _buildNavCard(
              context: context,
              icon: Icons.account_balance_wallet,
              title: 'Správa financií',
              subtitle: 'Tržby, provízie, výkazy',
              onTap: () => Get.to(() => const FinancesPage()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: Get.find<OrdersService>().allOrdersStream,
            builder: (context, snap) {
              return _StatCard(
                icon: Icons.shopping_cart,
                label: 'Objednávky',
                value: '${snap.data?.length ?? 0}',
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: Get.find<UsersService>().usersStream,
            builder: (context, snap) {
              return _StatCard(
                icon: Icons.person,
                label: 'Užívatelia',
                value: '${snap.data?.length ?? 0}',
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: Get.find<ShopsService>().shopsStream,
            builder: (context, snap) {
              return _StatCard(
                icon: Icons.store,
                label: 'Stavebniny',
                value: '${snap.data?.length ?? 0}',
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNavCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.amber.shade100,
                child: Icon(icon, color: Colors.amber.shade800),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade600),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          children: [
            Icon(icon, size: 28, color: Colors.amber.shade700),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/users_service.dart';
import '../services/shops_service.dart';

/// Správa užívateľov – ľavý nav 1/5, pravý zoznam 4/5; pridanie cez popup; detail s plusom pre roly a managedShopIds.
class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  Map<String, dynamic>? _selectedUser;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  static InputDecoration _inputDecoration({
    required String label,
    String? hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, size: 20, color: Colors.amber.shade700),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.amber.shade700, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      suffixIcon: suffix,
    );
  }

  void _showAddUserPopup() {
    _firstNameController.clear();
    _lastNameController.clear();
    _emailController.clear();
    _passwordController.clear();
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        var obscure = true;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Icon(Icons.person_add_rounded, color: Colors.amber.shade700),
                  const SizedBox(width: 12),
                  const Text('Nový užívateľ'),
                ],
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Vyplňte údaje pre registráciu. Účet sa vytvorí v Firebase Auth a profil sa uloží do Firestore.',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.4),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _firstNameController,
                        decoration: _inputDecoration(label: 'Meno *', hint: 'Ján', icon: Icons.badge_outlined),
                        textCapitalization: TextCapitalization.words,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Zadajte meno' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _lastNameController,
                        decoration: _inputDecoration(label: 'Priezvisko *', hint: 'Novák', icon: Icons.badge_outlined),
                        textCapitalization: TextCapitalization.words,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Zadajte priezvisko' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _emailController,
                        decoration: _inputDecoration(label: 'Email *', hint: 'jan.novak@example.sk', icon: Icons.email_outlined),
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Zadajte email';
                          if (!GetUtils.isEmail(v.trim())) return 'Neplatný formát emailu';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: obscure,
                        decoration: _inputDecoration(
                          label: 'Heslo *',
                          hint: '••••••••',
                          icon: Icons.lock_outline,
                          suffix: IconButton(
                            icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                            onPressed: () => setDialogState(() => obscure = !obscure),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Zadajte heslo';
                          if (v.length < 6) return 'Heslo má mať aspoň 6 znakov';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              actions: [
                TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Zrušiť')),
                FilledButton.icon(
                  onPressed: () => _submitAddUser(ctx),
                  icon: const Icon(Icons.person_add, size: 20),
                  label: const Text('Registrovať'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _submitAddUser(BuildContext dialogContext) async {
    if (!_formKey.currentState!.validate()) return;
    final email = _emailController.text.trim();
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final password = _passwordController.text;
    showDialog(
      context: dialogContext,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Vytváram účet...'),
              ],
            ),
          ),
        ),
      ),
    );
    try {
      await Get.find<UsersService>().createUser(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
      );
      if (!dialogContext.mounted) return;
      Navigator.of(dialogContext).pop();
      Navigator.of(dialogContext).pop();
      _firstNameController.clear();
      _lastNameController.clear();
      _emailController.clear();
      _passwordController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Užívateľ $email bol zaregistrovaný'), backgroundColor: Colors.green.shade700, behavior: SnackBarBehavior.floating),
      );
    } on FirebaseAuthException catch (e) {
      if (!dialogContext.mounted) return;
      Navigator.of(dialogContext).pop();
      String msg = e.message ?? 'Registrácia zlyhala';
      if (e.code == 'email-already-in-use') msg = 'Email je už použitý. Zvoľte iný.';
      if (e.code == 'weak-password') msg = 'Heslo je príliš slabé.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700, behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      if (!dialogContext.mounted) return;
      Navigator.of(dialogContext).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chyba: $e'), backgroundColor: Colors.red.shade700, behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Správa užívateľov'),
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black,
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 1,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                border: Border(right: BorderSide(color: Colors.grey.shade300)),
              ),
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                children: [
                  FilledButton.icon(
                    onPressed: _showAddUserPopup,
                    icon: const Icon(Icons.person_add),
                    label: const Text('Pridať uživateľa'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 12),
                  Text('Filtre', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
                  const SizedBox(height: 8),
                  Text('Filtrovanie a ďalšie možnosti prídú neskôr.', style: TextStyle(fontSize: 12, color: Colors.grey.shade500, height: 1.3)),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: _selectedUser != null
                ? _UserDetailPanel(
                    user: _selectedUser!,
                    onBack: () => setState(() => _selectedUser = null),
                    onUserUpdated: (updated) => setState(() => _selectedUser = updated),
                  )
                : StreamBuilder<List<Map<String, dynamic>>>(
                    stream: Get.find<UsersService>().usersStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                              const SizedBox(height: 12),
                              Text('Chyba načítania', style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
                              const SizedBox(height: 4),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 32),
                                child: Text(snapshot.error.toString(), textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                              ),
                            ],
                          ),
                        );
                      }
                      final users = snapshot.data ?? [];
                      if (users.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text('Žiadni užívatelia', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
                              const SizedBox(height: 8),
                              Text('Pridajte užívateľa tlačidlom v ľavom menu.', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                            ],
                          ),
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          final u = users[index];
                          final firstName = u['firstName'] as String? ?? '';
                          final lastName = u['lastName'] as String? ?? '';
                          final email = u['email'] as String? ?? '';
                          final displayName = firstName.isEmpty && lastName.isEmpty ? email : '$firstName $lastName'.trim();
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: CircleAvatar(
                                backgroundColor: Colors.amber.shade100,
                                child: Text(
                                  displayName.isNotEmpty ? displayName.substring(0, 1).toUpperCase() : '?',
                                  style: TextStyle(color: Colors.amber.shade800, fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text(email, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                              trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
                              onTap: () => setState(() => _selectedUser = u),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

const List<String> _roleOptions = ['superuser', 'driver', 'customer', 'shop-staff'];

class _UserDetailPanel extends StatefulWidget {
  final Map<String, dynamic> user;
  final VoidCallback onBack;
  final void Function(Map<String, dynamic>) onUserUpdated;

  const _UserDetailPanel({required this.user, required this.onBack, required this.onUserUpdated});

  @override
  State<_UserDetailPanel> createState() => _UserDetailPanelState();
}

class _UserDetailPanelState extends State<_UserDetailPanel> {
  late List<String> _roles;
  late List<String> _managedShopIds;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _syncFromUser(widget.user);
  }

  @override
  void didUpdateWidget(covariant _UserDetailPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user['uid'] != widget.user['uid']) _syncFromUser(widget.user);
  }

  void _syncFromUser(Map<String, dynamic> user) {
    final r = user['roles'];
    final s = user['managedShopIds'];
    _roles = r is List ? List<String>.from(r.map((e) => e.toString())) : [];
    _managedShopIds = s is List ? List<String>.from(s.map((e) => e.toString())) : [];
  }

  String _formatCreatedAt(dynamic createdAt) {
    if (createdAt == null) return '—';
    if (createdAt is Timestamp) {
      final dt = createdAt.toDate();
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return createdAt.toString();
  }

  Future<void> _updateRoles(List<String> newRoles) async {
    final uid = widget.user['uid'] as String?;
    if (uid == null) return;
    setState(() => _saving = true);
    try {
      await Get.find<UsersService>().updateUser(uid, roles: newRoles);
      setState(() {
        _roles = newRoles;
        _saving = false;
        widget.onUserUpdated({...widget.user, 'roles': newRoles});
      });
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Chyba: $e'), backgroundColor: Colors.red.shade700));
    }
  }

  Future<void> _updateManagedShopIds(List<String> newIds) async {
    final uid = widget.user['uid'] as String?;
    if (uid == null) return;
    setState(() => _saving = true);
    try {
      final shopsService = Get.find<ShopsService>();
      await Get.find<UsersService>().updateUser(uid, managedShopIds: newIds);
      for (final shopId in newIds) {
        if (!_managedShopIds.contains(shopId)) await shopsService.addManagedBy(shopId, uid);
      }
      for (final shopId in _managedShopIds) {
        if (!newIds.contains(shopId)) await shopsService.removeManagedBy(shopId, uid);
      }
      setState(() {
        _managedShopIds = newIds;
        _saving = false;
        widget.onUserUpdated({...widget.user, 'managedShopIds': newIds});
      });
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Chyba: $e'), backgroundColor: Colors.red.shade700));
    }
  }

  void _showAddRoleMenu(BuildContext context) {
    final available = _roleOptions.where((r) => !_roles.contains(r)).toList();
    if (available.isEmpty) return;
    showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Pridať rolu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey.shade800)),
            ),
            ...available.map((r) => ListTile(title: Text(r), onTap: () {
                  Navigator.of(ctx).pop(r);
                })),
          ],
        ),
      ),
    ).then((v) {
      if (v != null) _updateRoles([..._roles, v]);
    });
  }

  void _showAddShopDialog(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => StreamBuilder<List<Map<String, String>>>(
        stream: Get.find<ShopsService>().firestoreShopsStream,
        builder: (context, snap) {
          final shops = snap.data ?? [];
          final available = shops.where((s) => !_managedShopIds.contains(s['id'])).toList();
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Pridať stavebniny',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey.shade800),
                  ),
                ),
                if (available.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Žiadne ďalšie stavebniny na pridanie.', style: TextStyle(color: Colors.grey.shade600)),
                  )
                else
                  ...available.map((s) => ListTile(
                        leading: const Icon(Icons.store_outlined),
                        title: Text(s['name']!),
                        onTap: () {
                          Navigator.of(ctx).pop();
                          _updateManagedShopIds([..._managedShopIds, s['id']!]);
                        },
                      )),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final firstName = user['firstName'] as String? ?? '';
    final lastName = user['lastName'] as String? ?? '';
    final email = user['email'] as String? ?? '';
    final displayName = firstName.isEmpty && lastName.isEmpty ? email : '$firstName $lastName'.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: Colors.grey.shade100,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                IconButton(icon: const Icon(Icons.arrow_back), onPressed: widget.onBack, tooltip: 'Späť na zoznam'),
                const SizedBox(width: 8),
                Text('Detail užívateľa', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey.shade800)),
                if (_saving) ...[const SizedBox(width: 12), const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))],
              ],
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.amber.shade100,
                    child: Text(
                      displayName.isNotEmpty ? displayName.substring(0, 1).toUpperCase() : '?',
                      style: TextStyle(fontSize: 32, color: Colors.amber.shade800, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(child: Text(displayName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
                const SizedBox(height: 24),
                _DetailRow(label: 'Email', value: email.isEmpty ? '—' : email),
                _DetailRow(label: 'Dátum vytvorenia', value: _formatCreatedAt(user['createdAt'])),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('Roly', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: Icon(Icons.add_circle_outline, size: 20, color: Colors.amber.shade700),
                      onPressed: _roleOptions.any((r) => !_roles.contains(r)) ? () => _showAddRoleMenu(context) : null,
                      tooltip: 'Pridať rolu',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: _roles.map((r) => Chip(
                    label: Text(r),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () => _updateRoles([..._roles]..remove(r)),
                    backgroundColor: Colors.amber.shade50,
                    side: BorderSide(color: Colors.amber.shade200),
                  )).toList(),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Text('Managed shop IDs', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: Icon(Icons.add_circle_outline, size: 20, color: Colors.amber.shade700),
                      onPressed: () => _showAddShopDialog(context),
                      tooltip: 'Pridať stavebnínu',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                StreamBuilder<List<Map<String, String>>>(
                  stream: Get.find<ShopsService>().firestoreShopsStream,
                  builder: (context, snap) {
                    final shops = snap.data ?? [];
                    final shopById = {for (var s in shops) s['id']!: s['name']!};
                    return Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: _managedShopIds.map((id) {
                        final name = shopById[id] ?? id;
                        return Chip(
                          label: Text(name),
                          deleteIcon: const Icon(Icons.close, size: 18),
                          onDeleted: () => _updateManagedShopIds([..._managedShopIds]..remove(id)),
                          backgroundColor: Colors.grey.shade100,
                          side: BorderSide(color: Colors.grey.shade300),
                        );
                      }).toList(),
                    );
                  },
                ),
                if ((user['uid'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text('UID', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
                  const SizedBox(height: 4),
                  SelectableText(user['uid'].toString(), style: TextStyle(fontSize: 12, fontFamily: 'monospace', color: Colors.grey.shade700)),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          SelectableText(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}

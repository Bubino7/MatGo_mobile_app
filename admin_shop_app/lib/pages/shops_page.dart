import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/shops_service.dart';
import '../utils/pick_image.dart';

/// Správa stavebnín – slug = ID dokumentu (z názvu), obrázok do Storage.
class ShopsPage extends StatefulWidget {
  const ShopsPage({super.key});

  @override
  State<ShopsPage> createState() => _ShopsPageState();
}

class _ShopsPageState extends State<ShopsPage> {
  Map<String, dynamic>? _selectedShop;

  void _openNewShop() {
    setState(() {
      _selectedShop = {
        '_isNew': true,
        'name': '',
        'address': '',
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Správa stavebnín'),
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
                    onPressed: _openNewShop,
                    icon: const Icon(Icons.add_business),
                    label: const Text('Pridať stavebnínu'),
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
                  Text('Filtrovanie prídú neskôr.', style: TextStyle(fontSize: 12, color: Colors.grey.shade500, height: 1.3)),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: _selectedShop != null
                ? _ShopDetailPanel(
                    shop: _selectedShop!,
                    onBack: () => setState(() => _selectedShop = null),
                    onSaved: (updated) => setState(() => _selectedShop = updated),
                  )
                : StreamBuilder<List<Map<String, dynamic>>>(
                    stream: Get.find<ShopsService>().shopsStream,
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
                      final shops = snapshot.data ?? [];
                      if (shops.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.store, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text('Žiadne stavebniny', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
                              const SizedBox(height: 8),
                              Text('Pridajte stavebnínu tlačidlom v ľavom menu.', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                            ],
                          ),
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: shops.length,
                        itemBuilder: (context, index) {
                          final shop = shops[index];
                          final name = shop['name'] as String? ?? '';
                          final slug = shop['slug'] as String? ?? shop['id'] as String? ?? '';
                          final imageUrl = shop['imageUrl'] as String?;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.amber.shade100,
                                ),
                                clipBehavior: Clip.antiAlias,
                                alignment: Alignment.center,
                                child: imageUrl != null && imageUrl.isNotEmpty
                                    ? Image.network(imageUrl, fit: BoxFit.contain, width: 56, height: 56, errorBuilder: (_, __, ___) => const Icon(Icons.store, color: Colors.black87))
                                    : const Icon(Icons.store, color: Colors.black87),
                              ),
                              title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text('/shop/$slug', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                              trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
                              onTap: () => setState(() => _selectedShop = Map<String, dynamic>.from(shop)),
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

class _ShopDetailPanel extends StatefulWidget {
  final Map<String, dynamic> shop;
  final VoidCallback onBack;
  final void Function(Map<String, dynamic>) onSaved;

  const _ShopDetailPanel({required this.shop, required this.onBack, required this.onSaved});

  @override
  State<_ShopDetailPanel> createState() => _ShopDetailPanelState();
}

class _ShopDetailPanelState extends State<_ShopDetailPanel> {
  late final bool _isNew;
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  Uint8List? _pickedImageBytes;
  String? _pickedImageMimeType;

  static InputDecoration _inputDecoration({
    required String label,
    String? hint,
    required IconData icon,
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
    );
  }

  @override
  void initState() {
    super.initState();
    _isNew = widget.shop['_isNew'] == true;
    _nameController = TextEditingController(text: (widget.shop['name'] as String?) ?? '');
    _addressController = TextEditingController(text: (widget.shop['address'] as String?) ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final result = await pickImage();
    if (result == null || !mounted) return;
    setState(() {
      _pickedImageBytes = result.bytes;
      _pickedImageMimeType = result.mimeType;
    });
  }

  /// Max veľkosť obrázka v bytoch pri ukladaní do Firestore (base64). Firestore limit 1 MB na dokument.
  static const int _maxImageBytes = 550000;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final name = _nameController.text.trim();
    final address = _addressController.text.trim();
    setState(() => _saving = true);
    try {
      final svc = Get.find<ShopsService>();
      String? imageUrl = widget.shop['imageUrl'] as String?;
      if (_pickedImageBytes != null) {
        final mime = _pickedImageMimeType ?? 'image/jpeg';
        if (_pickedImageBytes!.length > _maxImageBytes) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Obrázok je príliš veľký (max ${_maxImageBytes ~/ 1000} KB). Zvoľte menší.'),
              backgroundColor: Colors.orange.shade700,
              behavior: SnackBarBehavior.floating,
            ),
          );
          setState(() => _saving = false);
          return;
        }
        imageUrl = 'data:$mime;base64,${base64Encode(_pickedImageBytes!)}';
      }
      if (_isNew) {
        final id = await svc.addShop(name, address: address.isEmpty ? null : address, imageUrl: imageUrl);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Stavebnína $name bola pridaná'), backgroundColor: Colors.green.shade700, behavior: SnackBarBehavior.floating),
        );
        widget.onSaved({'id': id, 'name': name, 'slug': id, 'address': address.isEmpty ? null : address, 'imageUrl': imageUrl, 'createdAt': null});
      } else {
        final docId = widget.shop['id'] as String? ?? '';
        if (docId.isEmpty) throw Exception('Chýba ID dokumentu');
        await svc.updateShop(docId, name: name, address: address.isEmpty ? null : address, imageUrl: imageUrl);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Zmeny boli uložené'), backgroundColor: Colors.green.shade700, behavior: SnackBarBehavior.floating),
        );
        widget.onSaved({'id': docId, 'name': name, 'slug': docId, 'address': address.isEmpty ? null : address, 'imageUrl': imageUrl, 'createdAt': widget.shop['createdAt']});
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chyba: $e'), backgroundColor: Colors.red.shade700, behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  static String _formatCreatedAt(dynamic createdAt) {
    if (createdAt == null) return '—';
    if (createdAt is Timestamp) {
      final dt = createdAt.toDate();
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return createdAt.toString();
  }

  @override
  Widget build(BuildContext context) {
    final createdAt = widget.shop['createdAt'];
    final id = widget.shop['id'] as String? ?? '';
    final existingImageUrl = widget.shop['imageUrl'] as String?;

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
                Text(
                  _isNew ? 'Nová stavebnína' : 'Detail stavebníny',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey.shade800),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: GestureDetector(
                      onTap: _saving ? null : _pickImage,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 120,
                            height: 120,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: _pickedImageBytes != null
                                  ? Image.memory(_pickedImageBytes!, fit: BoxFit.contain)
                                  : existingImageUrl != null && existingImageUrl.isNotEmpty
                                      ? Image.network(existingImageUrl, fit: BoxFit.contain, width: 120, height: 120, errorBuilder: (_, Object err, StackTrace? st) => _placeholder())
                                      : _placeholder(),
                            ),
                          ),
                          if (!_saving)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: CircleAvatar(
                                backgroundColor: Colors.amber,
                                child: Icon(Icons.camera_alt, color: Colors.black87, size: 20),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton.icon(
                      onPressed: _saving ? null : _pickImage,
                      icon: const Icon(Icons.add_photo_alternate, size: 18),
                      label: Text(_pickedImageBytes != null || (existingImageUrl != null && existingImageUrl.isNotEmpty) ? 'Zmeniť obrázok' : 'Vybrať obrázok'),
                    ),
                  ),
                  if (!_isNew) ...[
                    const SizedBox(height: 8),
                    Center(child: Text(_nameController.text.isEmpty ? 'Stavebnína' : _nameController.text, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
                  ],
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _nameController,
                    decoration: _inputDecoration(label: 'Názov *', hint: 'napr. StavMat', icon: Icons.store_outlined),
                    textCapitalization: TextCapitalization.words,
                    onChanged: (_) => setState(() {}),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Zadajte názov' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _addressController,
                    decoration: _inputDecoration(label: 'Adresa', hint: 'ulica, mesto, PSČ', icon: Icons.location_on_outlined),
                    textCapitalization: TextCapitalization.words,
                    maxLines: 2,
                  ),
                  if (!_isNew && id.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text('Slug (ID dokumentu)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
                    const SizedBox(height: 4),
                    SelectableText(id, style: TextStyle(fontSize: 14, fontFamily: 'monospace', color: Colors.grey.shade700)),
                    const SizedBox(height: 4),
                    Text('/shop/$id', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  ],
                  if (!_isNew && createdAt != null) ...[
                    const SizedBox(height: 12),
                    Text('Dátum vytvorenia', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
                    const SizedBox(height: 4),
                    SelectableText(_formatCreatedAt(createdAt), style: const TextStyle(fontSize: 16)),
                  ],
                ],
              ),
            ),
          ),
        ),
        Material(
          color: Colors.grey.shade100,
          elevation: 2,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!_isNew) TextButton(onPressed: widget.onBack, child: const Text('Zrušiť')),
                  if (!_isNew) const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save, size: 20),
                    label: Text(_saving ? 'Ukladám...' : 'Uložiť'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _placeholder() {
    return Container(
      width: 120,
      height: 120,
      color: Colors.amber.shade100,
      child: const Icon(Icons.store, size: 48, color: Colors.black54),
    );
  }
}

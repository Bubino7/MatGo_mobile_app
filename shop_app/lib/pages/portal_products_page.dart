import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:shared_models/shared_models.dart';

import '../services/categories_service.dart';
import '../services/products_service.dart';
import '../utils/pick_image.dart';

/// Položky na predaj – zoznam a detail v kontajneroch. Produkty do kolekcie `products`.
class PortalProductsPage extends StatefulWidget {
  const PortalProductsPage({
    super.key,
    required this.shopId,
    required this.shopName,
  });
  final String shopId;
  final String shopName;

  @override
  State<PortalProductsPage> createState() => _PortalProductsPageState();
}

class _PortalProductsPageState extends State<PortalProductsPage> {
  Map<String, dynamic>? _selectedProduct;
  final Set<String> _filterCategoryIds = {};

  void _openNewProduct() {
    setState(() {
      _selectedProduct = {
        '_isNew': true,
        'name': '',
        'price': 0.0,
        'unit': null,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('MatGo – ${widget.shopName}'),
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Get.back()),
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
                    onPressed: _openNewProduct,
                    icon: const Icon(Icons.add),
                    label: const Text('Pridať položku'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text('Filter podľa kategórie', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
                  const SizedBox(height: 4),
                  Material(
                    color: Colors.transparent,
                    child: CheckboxListTile(
                      dense: true,
                      visualDensity: VisualDensity.compact,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                      title: Text('Všetky', style: TextStyle(fontSize: 12, color: Colors.grey.shade800)),
                      value: _filterCategoryIds.isEmpty,
                      tristate: false,
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: Colors.amber.shade700,
                      onChanged: (_) => setState(() => _filterCategoryIds.clear()),
                    ),
                  ),
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: Get.find<CategoriesService>().categoriesStream(),
                    builder: (context, snap) {
                      if (!snap.hasData) return const SizedBox.shrink();
                      final list = snap.data!;
                      if (list.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text('Žiadne kategórie.', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                        );
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: list.map((c) {
                          final id = c['id'] as String? ?? '';
                          final name = c['name'] as String? ?? '';
                          final isSelected = _filterCategoryIds.contains(id);
                          return Material(
                            color: Colors.transparent,
                            child: CheckboxListTile(
                              dense: true,
                              visualDensity: VisualDensity.compact,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                              title: Text(name, style: TextStyle(fontSize: 12, color: Colors.grey.shade800)),
                              value: isSelected,
                              tristate: false,
                              controlAffinity: ListTileControlAffinity.leading,
                              activeColor: Colors.amber.shade700,
                              onChanged: (_) {
                                setState(() {
                                  if (isSelected) {
                                    _filterCategoryIds.remove(id);
                                  } else {
                                    _filterCategoryIds.add(id);
                                  }
                                });
                              },
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: _selectedProduct != null
                ? _ProductDetailPanel(
                    shopId: widget.shopId,
                    product: _selectedProduct!,
                    onBack: () => setState(() => _selectedProduct = null),
                    onSaved: (updated) => setState(() => _selectedProduct = updated),
                  )
                : StreamBuilder<List<Map<String, dynamic>>>(
                    stream: Get.find<ProductsService>().productsStream(widget.shopId),
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
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 32),
                                child: Text(snapshot.error.toString(), textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                              ),
                            ],
                          ),
                        );
                      }
                      final allProducts = snapshot.data ?? [];
                      final products = _filterCategoryIds.isEmpty
                          ? allProducts
                          : allProducts.where((p) {
                              final cid = p['categoryId'] as String?;
                              return cid != null && cid.isNotEmpty && _filterCategoryIds.contains(cid);
                            }).toList();
                      if (products.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text(
                                _filterCategoryIds.isEmpty ? 'Žiadne položky' : 'Žiadna položka v zvolených kategóriách',
                                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _filterCategoryIds.isEmpty
                                    ? 'Pridajte položku tlačidlom v ľavom menu.'
                                    : 'Zrušte filter alebo pridajte položky do kategórií.',
                                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          final p = products[index];
                          final name = p['name'] as String? ?? '';
                          final price = p['price'];
                          final unit = p['unit'] as String?;
                          final imageUrl = p['imageUrl'] as String?;
                          final priceStr = price is num ? price.toStringAsFixed(2) : '—';
                          final unitStr = (unit != null && unit.isNotEmpty) ? ' / $unit' : '';
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2)),
                              ],
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: _productThumb(imageUrl, 56),
                              title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text('$priceStr €$unitStr', style: TextStyle(fontSize: 14, color: Colors.amber.shade800)),
                              trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
                              onTap: () => setState(() => _selectedProduct = Map<String, dynamic>.from(p)),
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

  Widget _productThumb(String? imageUrl, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.amber.shade100,
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl != null && imageUrl.isNotEmpty
          ? Image.network(imageUrl, fit: BoxFit.contain, width: size, height: size, errorBuilder: (_, __, ___) => Icon(Icons.inventory_2, color: Colors.amber.shade800, size: size * 0.5))
          : Icon(Icons.inventory_2, color: Colors.amber.shade800, size: size * 0.5),
    );
  }
}

class _ProductDetailPanel extends StatefulWidget {
  final String shopId;
  final Map<String, dynamic> product;
  final VoidCallback onBack;
  final void Function(Map<String, dynamic>) onSaved;

  const _ProductDetailPanel({
    required this.shopId,
    required this.product,
    required this.onBack,
    required this.onSaved,
  });

  @override
  State<_ProductDetailPanel> createState() => _ProductDetailPanelState();
}

class _ProductDetailPanelState extends State<_ProductDetailPanel> {
  late final bool _isNew;
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  Uint8List? _pickedImageBytes;
  String? _pickedImageMimeType;
  bool _clearImage = false;
  String? _categoryId;
  String? _unit;
  List<Map<String, dynamic>> _categories = [];

  static const int _maxImageBytes = 550000;

  static InputDecoration _inputDecoration({required String label, String? hint, required IconData icon}) {
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
    _isNew = widget.product['_isNew'] == true;
    _nameController = TextEditingController(text: (widget.product['name'] as String?) ?? '');
    final price = widget.product['price'];
    _priceController = TextEditingController(
      text: price is num ? price.toStringAsFixed(2) : '0.00',
    );
    _categoryId = widget.product['categoryId'] as String?;
    _unit = widget.product['unit'] as String?;
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final list = await Get.find<CategoriesService>().getCategories();
    if (mounted) setState(() {
      _categories = list;
      if (_categoryId != null && !list.any((c) => c['id'] == _categoryId)) _categoryId = null;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final result = await pickImage();
    if (result == null || !mounted) return;
    setState(() {
      _pickedImageBytes = result.bytes;
      _pickedImageMimeType = result.mimeType;
      _clearImage = false;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final name = _nameController.text.trim();
    final priceVal = double.tryParse(_priceController.text.replaceFirst(',', '.')) ?? 0.0;
    if (priceVal < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Cena musí byť nezáporná.'), backgroundColor: Colors.orange.shade700, behavior: SnackBarBehavior.floating),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final productsSvc = Get.find<ProductsService>();
      String? imageUrl = widget.product['imageUrl'] as String?;
      if (_clearImage) {
        imageUrl = null;
      } else if (_pickedImageBytes != null) {
        if (_pickedImageBytes!.length > _maxImageBytes) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Obrázok je príliš veľký (max ${_maxImageBytes ~/ 1000} KB).'), backgroundColor: Colors.orange.shade700, behavior: SnackBarBehavior.floating),
          );
          setState(() => _saving = false);
          return;
        }
        final mime = _pickedImageMimeType ?? 'image/jpeg';
        imageUrl = 'data:$mime;base64,${base64Encode(_pickedImageBytes!)}';
      }
      if (_isNew) {
        final id = await productsSvc.addProduct(
          shopId: widget.shopId,
          name: name,
          price: priceVal,
          unit: _unit?.isEmpty == true ? null : _unit,
          imageUrl: imageUrl,
          categoryId: _categoryId?.isEmpty == true ? null : _categoryId,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Položka $name bola pridaná'), backgroundColor: Colors.green.shade700, behavior: SnackBarBehavior.floating),
        );
        widget.onSaved({
          'id': id,
          'name': name,
          'price': priceVal,
          'imageUrl': imageUrl,
          'categoryId': _categoryId,
          'unit': _unit,
          'createdAt': null,
        });
      } else {
        final docId = widget.product['id'] as String? ?? '';
        if (docId.isEmpty) throw Exception('Chýba ID dokumentu');
        await productsSvc.updateProduct(
          docId,
          name: name,
          price: priceVal,
          unit: _unit?.isEmpty == true ? '' : _unit,
          imageUrl: _pickedImageBytes != null ? imageUrl : null,
          clearImage: _clearImage,
          categoryId: _categoryId?.isEmpty == true ? '' : _categoryId,
          oldCategoryId: widget.product['categoryId'] as String?,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Zmeny boli uložené'), backgroundColor: Colors.green.shade700, behavior: SnackBarBehavior.floating),
        );
        widget.onSaved({
          ...widget.product,
          'name': name,
          'price': priceVal,
          'imageUrl': _clearImage ? null : (imageUrl ?? widget.product['imageUrl']),
          'categoryId': _categoryId,
          'unit': _unit,
        });
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

  Future<void> _addCategoryDialog() async {
    final nameController = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nová kategória'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Názov'),
          autofocus: true,
          onSubmitted: (_) => Navigator.pop(ctx, true),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Zrušiť')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
            child: const Text('Pridať'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final name = nameController.text.trim();
    if (name.isEmpty) return;
    final newId = await Get.find<CategoriesService>().addCategory(name);
    await _loadCategories();
    if (!mounted) return;
    setState(() => _categoryId = newId);
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

  @override
  Widget build(BuildContext context) {
    final existingImageUrl = widget.product['imageUrl'] as String?;
    final hasImage = _pickedImageBytes != null || (existingImageUrl != null && existingImageUrl.isNotEmpty && !_clearImage);

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
                  _isNew ? 'Nová položka' : 'Detail položky',
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
                                  : hasImage && existingImageUrl != null
                                      ? Image.network(existingImageUrl, fit: BoxFit.contain, width: 120, height: 120, errorBuilder: (_, __, ___) => _placeholder())
                                      : _placeholder(),
                            ),
                          ),
                          if (!_saving)
                            Positioned(right: 0, bottom: 0, child: CircleAvatar(backgroundColor: Colors.amber, child: Icon(Icons.camera_alt, color: Colors.black87, size: 20))),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton.icon(
                          onPressed: _saving ? null : _pickImage,
                          icon: const Icon(Icons.add_photo_alternate, size: 18),
                          label: Text(hasImage ? 'Zmeniť obrázok' : 'Vybrať obrázok (nepovinné)'),
                        ),
                        if (hasImage && !_isNew) ...[
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: _saving ? null : () => setState(() => _clearImage = true),
                            icon: const Icon(Icons.delete_outline, size: 18),
                            label: const Text('Odstrániť'),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _nameController,
                    decoration: _inputDecoration(label: 'Názov *', hint: 'napr. Cement 25 kg', icon: Icons.label_outline),
                    textCapitalization: TextCapitalization.words,
                    onChanged: (_) => setState(() {}),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Zadajte názov' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _priceController,
                    decoration: _inputDecoration(label: 'Cena (€) *', hint: '0.00', icon: Icons.euro_outlined),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Zadajte cenu';
                      final n = double.tryParse(v.replaceFirst(',', '.'));
                      if (n == null || n < 0) return 'Neplatná cena';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  Text('Merná jednotka ceny', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                  const SizedBox(height: 8),
                  DropdownButton<String?>(
                    value: (_unit != null && (_unit!.isNotEmpty) && productUnits.contains(_unit)) ? _unit : null,
                    hint: const Text('—'),
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem<String?>(value: null, child: Text('—')),
                      ...productUnits.map((u) => DropdownMenuItem<String?>(value: u, child: Text(u))),
                    ],
                    onChanged: _saving ? null : (v) => setState(() => _unit = v),
                  ),
                  const SizedBox(height: 20),
                  Text('Kategória', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      DropdownButton<String?>(
                        value: (_categoryId != null && _categoryId!.isNotEmpty && _categories.any((c) => c['id'] == _categoryId)) ? _categoryId : null,
                        hint: const Text('Žiadna'),
                        items: [
                          const DropdownMenuItem<String?>(value: null, child: Text('Žiadna')),
                          ..._categories.map((c) => DropdownMenuItem<String?>(value: c['id'] as String?, child: Text(c['name'] as String? ?? ''))),
                        ],
                        onChanged: _saving ? null : (v) => setState(() => _categoryId = v),
                      ),
                      const SizedBox(width: 12),
                      TextButton.icon(
                        onPressed: _saving ? null : _addCategoryDialog,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Nová kategória'),
                      ),
                    ],
                  ),
                  if (!_isNew) ...[
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text('Dátum vytvorenia', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
                    const SizedBox(height: 4),
                    SelectableText(_formatCreatedAt(widget.product['createdAt']), style: const TextStyle(fontSize: 16)),
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
      child: Icon(Icons.inventory_2, size: 48, color: Colors.amber.shade800),
    );
  }
}

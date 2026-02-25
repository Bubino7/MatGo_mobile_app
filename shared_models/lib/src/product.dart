import 'collections.dart';
import 'utils.dart';

/// Bežné merné jednotky pre cenu (ks, m², m³, …). Použitie v UI výberu.
const List<String> productUnits = ['ks', 'm²', 'm³', 'kg', 'l', 'm', 'balenie', 'paleta'];

/// Model produktu – Firestore kolekcia [Collections.products].
class Product {
  Product({
    required this.id,
    required this.shopId,
    required this.name,
    required this.price,
    this.unit,
    this.imageUrl,
    this.keywords = const [],
    this.categoryId,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String shopId;
  final String name;
  final double price;
  final String? unit;
  final String? imageUrl;
  final List<String> keywords;
  final String? categoryId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  static Product? fromMap(Map<String, dynamic>? data, {String? documentId}) {
    if (data == null) return null;
    final id = documentId ?? data['id'] as String?;
    if (id == null) return null;
    final price = data['price'];
    return Product(
      id: id.toString(),
      shopId: (data['shopId'] as String?) ?? '',
      name: (data['name'] as String?) ?? '',
      price: price is num ? price.toDouble() : 0.0,
      unit: data['unit'] as String?,
      imageUrl: data['imageUrl'] as String?,
      keywords: _stringList(data['keywords']),
      categoryId: data['categoryId'] as String?,
      createdAt: MatGoUtils.parseDate(data['createdAt']),
      updatedAt: MatGoUtils.parseDate(data['updatedAt']),
    );
  }

  static List<String> _stringList(dynamic v) {
    if (v is! List) return [];
    return v.map((e) => e.toString()).toList();
  }

  Map<String, dynamic> toMap() => {
        'shopId': shopId,
        'name': name,
        'price': price,
        'keywords': keywords,
        if (unit != null && unit!.isNotEmpty) 'unit': unit,
        if (imageUrl != null && imageUrl!.isNotEmpty) 'imageUrl': imageUrl,
        if (categoryId != null && categoryId!.isNotEmpty) 'categoryId': categoryId,
      };
}

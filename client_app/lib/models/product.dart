/// Model produktu v client_app (z Firestore + shopName, categoryName).
class Product {
  final String id;
  final String name;
  final String shopName;
  final String shopId;
  final double price;
  final String? unit;
  final String? imageUrl;
  final String? imagePath;
  final String category;
  final String? categoryId;

  Product({
    required this.id,
    required this.name,
    required this.shopName,
    required this.shopId,
    required this.price,
    this.unit,
    this.imageUrl,
    this.imagePath,
    required this.category,
    this.categoryId,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'shopName': shopName,
        'shopId': shopId,
        'price': price,
        if (unit != null && unit!.isNotEmpty) 'unit': unit,
        if (imageUrl != null && imageUrl!.isNotEmpty) 'imageUrl': imageUrl,
        if (imagePath != null && imagePath!.isNotEmpty) 'imagePath': imagePath,
        'category': category,
        if (categoryId != null && categoryId!.isNotEmpty) 'categoryId': categoryId,
      };

  /// Z mapy z Firestore (s doplneným shopName z ProductsService).
  static Product fromMap(Map<String, dynamic> map, {String? categoryName}) {
    final price = map['price'];
    return Product(
      id: (map['id'] as String?) ?? '',
      name: (map['name'] as String?) ?? '',
      shopName: (map['shopName'] as String?) ?? '',
      shopId: (map['shopId'] as String?) ?? '',
      price: price is num ? price.toDouble() : 0.0,
      unit: map['unit'] as String?,
      imageUrl: map['imageUrl'] as String?,
      imagePath: map['imagePath'] as String?,
      category: categoryName ?? (map['categoryName'] as String?) ?? '',
      categoryId: map['categoryId'] as String?,
    );
  }
}

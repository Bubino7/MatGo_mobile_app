import 'collections.dart';
import 'utils.dart';

/// Model stavebnín – Firestore kolekcia [Collections.shops].
class Shop {
  Shop({
    required this.id,
    required this.name,
    required this.slug,
    this.address,
    this.imageUrl,
    this.createdAt,
  });

  final String id;
  final String name;
  final String slug;
  final String? address;
  final String? imageUrl;
  final DateTime? createdAt;

  static Shop? fromMap(Map<String, dynamic>? data, {String? documentId}) {
    if (data == null) return null;
    final id = documentId ?? data['id'] as String? ?? data['slug'] as String?;
    if (id == null) return null;
    return Shop(
      id: id.toString(),
      name: (data['name'] as String?) ?? '',
      slug: (data['slug'] as String?) ?? id.toString(),
      address: data['address'] as String?,
      imageUrl: data['imageUrl'] as String?,
      createdAt: MatGoUtils.parseDate(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'slug': slug,
        if (address != null && address!.isNotEmpty) 'address': address,
        if (imageUrl != null && imageUrl!.isNotEmpty) 'imageUrl': imageUrl,
      };
}

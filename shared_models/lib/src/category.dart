import 'collections.dart';
import 'utils.dart';

/// Globálna kategória – Firestore kolekcia [Collections.categories].
/// [productIds] = zoznam ID produktov v tejto kategórii. Kategóriu môže použiť ľubovoľná stavebnína.
class Category {
  Category({
    required this.id,
    required this.name,
    this.productIds = const [],
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final List<String> productIds;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  static Category? fromMap(Map<String, dynamic>? data, {String? documentId}) {
    if (data == null) return null;
    final id = documentId ?? data['id'] as String?;
    if (id == null) return null;
    final v = data['productIds'];
    final productIds = v is List ? v.map((e) => e.toString()).toList() : <String>[];
    return Category(
      id: id.toString(),
      name: (data['name'] as String?) ?? '',
      productIds: productIds,
      createdAt: MatGoUtils.parseDate(data['createdAt']),
      updatedAt: MatGoUtils.parseDate(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'productIds': productIds,
      };
}

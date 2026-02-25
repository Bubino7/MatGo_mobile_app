import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_models/shared_models.dart';

/// Kategórie z Firestore (iba čítanie). Kolekcia [Collections.categories].
class CategoriesService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Všetky kategórie (globálne), zoradené podľa názvu.
  Stream<List<Map<String, dynamic>>> categoriesStream() {
    return _firestore.collection(Collections.categories).snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      list.sort((a, b) => ((a['name'] ?? '') as String).compareTo((b['name'] ?? '') as String));
      return list;
    });
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    final snapshot = await _firestore.collection(Collections.categories).get();
    final list = snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
    list.sort((a, b) => ((a['name'] ?? '') as String).compareTo((b['name'] ?? '') as String));
    return list;
  }
}

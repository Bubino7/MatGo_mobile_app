import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_models/shared_models.dart';

class UsersService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>?> getUser(String uid) async {
    final doc = await _firestore.collection(Collections.users).doc(uid).get();
    if (doc.data() == null) return null;
    final data = doc.data()!;
    data['uid'] = doc.id;
    return data;
  }
}

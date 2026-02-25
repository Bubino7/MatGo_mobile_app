import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_models/shared_models.dart';

class UsersService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>?> getUser(String uid) async {
    final doc = await _firestore.collection(Collections.users).doc(uid).get();
    return doc.data();
  }

  Stream<Map<String, dynamic>?> userStream(String uid) {
    return _firestore.collection(Collections.users).doc(uid).snapshots().map((doc) => doc.data());
  }

  Future<void> updateProfile({required String uid, required String phone, String? firstName, String? lastName}) async {
    await _firestore.collection(Collections.users).doc(uid).set({
      'phone': phone.trim(),
      if (firstName != null) 'firstName': firstName.trim(),
      if (lastName != null) 'lastName': lastName.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

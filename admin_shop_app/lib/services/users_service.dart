import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:shared_models/shared_models.dart';

/// Registrácia cez Firebase Auth a ukladanie profilu do Firestore kolekcie [Collections.users].
class UsersService extends GetxService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createUser({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final uid = cred.user?.uid;
    if (uid == null) throw Exception('Registrácia zlyhala');

    await _firestore.collection(Collections.users).doc(uid).set({
      'email': email.trim(),
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'roles': [],
      'managedShopIds': [],
    });
  }

  /// Vráti dokument užívateľa z Firestore (pre kontrolu managedShopIds v shop portáli).
  Future<Map<String, dynamic>?> getUser(String uid) async {
    final doc = await _firestore.collection(Collections.users).doc(uid).get();
    if (doc.data() == null) return null;
    final data = doc.data()!;
    data['uid'] = doc.id;
    return data;
  }

  Future<void> updateUser(String uid, {List<String>? roles, List<String>? managedShopIds}) async {
    final updates = <String, dynamic>{};
    if (roles != null) updates['roles'] = roles;
    if (managedShopIds != null) updates['managedShopIds'] = managedShopIds;
    if (updates.isEmpty) return;
    await _firestore.collection(Collections.users).doc(uid).update(updates);
  }

  Stream<List<Map<String, dynamic>>> get usersStream {
    return _firestore.collection(Collections.users).snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) {
        final data = doc.data();
        data['uid'] = doc.id;
        return data;
      }).toList();
      list.sort((a, b) {
        final aTime = a['createdAt'] as Timestamp?;
        final bTime = b['createdAt'] as Timestamp?;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });
      return list;
    });
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

/// GetX service – obal nad Firebase Auth.
/// Registrovať v main.dart: Get.put(AuthService());
/// Použitie: Get.find<AuthService>().currentUser, .authStateChanges(), .signIn(...), .signOut()
class AuthService extends GetxService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) =>
      _auth.signInWithEmailAndPassword(email: email.trim(), password: password.trim());

  Future<UserCredential?> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) =>
      _auth.createUserWithEmailAndPassword(email: email.trim(), password: password.trim());

  Future<void> signOut() => _auth.signOut();
}

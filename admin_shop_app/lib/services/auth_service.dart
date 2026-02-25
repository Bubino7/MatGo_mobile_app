import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

/// Prihlásenie do admina cez Firebase Auth.
/// Po otvorení admin stránky sa vyžaduje prihlásenie emailom/heslom.
class AuthService extends GetxService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> logout() => signOut();
}

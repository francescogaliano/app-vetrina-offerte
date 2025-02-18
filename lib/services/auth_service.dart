import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_auth_service.dart';

class AuthService {
  final FirebaseAuthService _authService = FirebaseAuthService();

  Stream<User?> get authStateChanges =>
      FirebaseAuth.instance.authStateChanges();

  Future<User?> getCurrentUser() async {
    return FirebaseAuth.instance.currentUser;
  }

  Future<void> logout() async {
    await _authService.signOut();
  }
}

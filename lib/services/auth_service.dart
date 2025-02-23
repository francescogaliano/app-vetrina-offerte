import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_auth_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuthService _authService = FirebaseAuthService();
//  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🔹 Ottieni il token FCM e salvalo su Firestore
  Future<void> saveUserToken(String userId) async {
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      await _firestore.collection('users').doc(userId).set(
          {
            'fcmToken': token,
          },
          SetOptions(
              merge:
                  true)); // ✅ Usa `merge: true` per non sovrascrivere dati esistenti

      print("✅ Token FCM salvato per $userId: $token");
    } else {
      print("⚠️ Nessun token FCM ricevuto per $userId");
    }
  }

  /// 🔹 Chiamato all'accesso per aggiornare il token
  Future<void> handleUserLogin(String userId) async {
    await saveUserToken(userId);
  }

  Stream<User?> get authStateChanges =>
      FirebaseAuth.instance.authStateChanges();

  Future<User?> getCurrentUser() async {
    return FirebaseAuth.instance.currentUser;
  }

  Future<void> logout() async {
    await _authService.signOut();
  }

  /// 🔹 Login utente
  Future<User?> loginUser(String email, String password) async {
    return await _authService.signIn(email, password);
  }

  /// 🔹 Recupera dati utente
  Future<Map<String, dynamic>?> fetchUserData(String uid) async {
    return await _authService.fetchUserData(uid);
  }

  /// 🔹 Registra un UTENTE normale
  Future<User?> registerUser(String email, String password, String name) async {
    return await _authService.signUpUser(email, password, name);
  }

  /// 🔹 Registra un VENDITORE
  Future<User?> registerVendor(
      String email, String password, String shopName) async {
    return await _authService.signUpVendor(email, password, shopName);
  }
}

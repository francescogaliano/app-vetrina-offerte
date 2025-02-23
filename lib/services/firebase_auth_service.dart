import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return userCredential.user;
    } catch (e) {
      print("❌ Errore di login: $e");
      return null;
    }
  }

  /// 🔹 Registrazione per UTENTI normali
  Future<User?> signUpUser(String email, String password, String name) async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Salva i dati utente in Firestore
      await _firestore.collection("users").doc(userCredential.user!.uid).set({
        "email": email,
        "name": name,
        "role": "user", // ✅ Gli utenti normali sono "user"
      });

      return userCredential.user;
    } catch (e) {
      print("❌ Errore di registrazione utente: $e");
      return null;
    }
  }

  /// 🔹 Registrazione per VENDITORI
  Future<User?> signUpVendor(
      String email, String password, String shopName) async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Salva i dati venditore in Firestore
      await _firestore.collection("users").doc(userCredential.user!.uid).set({
        "email": email,
        "shopName": shopName,
        "role": "vendor", // ✅ I venditori hanno il ruolo "vendor"
      });

      return userCredential.user;
    } catch (e) {
      print("❌ Errore di registrazione venditore: $e");
      return null;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<Map<String, dynamic>?> fetchUserData(String uid) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection("users").doc(uid).get();

      if (userDoc.exists) {
        return userDoc.data() as Map<String, dynamic>;
      } else {
        print("⚠️ Nessun documento trovato per UID: $uid");
        return null;
      }
    } catch (e) {
      print("❌ Errore nel recupero dati Firestore: $e");
      return null;
    }
  }
}

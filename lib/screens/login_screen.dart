import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'user_home.dart'; // ✅ Home utente
import 'vendor_home.dart'; // ✅ Home venditore
import 'register_user_screen.dart'; // ✅ Registrazione utenti
import 'register_vendor_screen.dart'; // ✅ Registrazione venditori

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  String _errorMessage = ""; // ✅ Messaggio di errore

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Accedi")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
            SizedBox(height: 10),
            if (_errorMessage.isNotEmpty) // ✅ Mostra l'errore solo se esiste
              Text(_errorMessage, style: TextStyle(color: Colors.red)),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _login, // ✅ Chiama la funzione di login
              child: Text("Accedi"),
            ),
            SizedBox(height: 20),
            Text("Non hai un account?", style: TextStyle(fontSize: 14)),
            TextButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            RegisterUserScreen())); // ✅ Percorso utenti
              },
              child: Text("Registrati"),
            ),
            Divider(),
            Text("Sei un negoziante?",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            RegisterVendorScreen())); // ✅ Percorso venditori
              },
              child: Text("Registra il tuo negozio!"),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔹 Funzione di login con Firebase
  Future<void> _login() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      if (mounted) {
        setState(() => _errorMessage = "Inserisci email e password.");
      }
      return;
    }

    User? user = await _authService.loginUser(email, password);
    if (user != null) {
      Map<String, dynamic>? userData =
          await _authService.fetchUserData(user.uid);
      if (userData != null && userData.containsKey("role")) {
        String role = userData["role"];
        if (mounted) {
          if (role == "vendor") {
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => VendorHome(uid: user.uid)));
          } else {
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => UserHome(uid: user.uid)));
          }
        }
      } else {
        if (mounted) {
          setState(() =>
              _errorMessage = "Ruolo non trovato. Contatta l'assistenza.");
        }
      }
    } else {
      if (mounted) {
        setState(() => _errorMessage = "Email o password errati.");
      }
    }
  }
}

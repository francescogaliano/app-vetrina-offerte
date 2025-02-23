import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'vendor_home.dart';

class RegisterVendorScreen extends StatefulWidget {
  @override
  _RegisterVendorScreenState createState() => _RegisterVendorScreenState();
}

class _RegisterVendorScreenState extends State<RegisterVendorScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _shopNameController = TextEditingController();
  final AuthService _authService = AuthService();

  String _errorMessage = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Registrazione Negozio")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _shopNameController,
              decoration: InputDecoration(labelText: "Nome del Negozio"),
            ),
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
            if (_errorMessage.isNotEmpty)
              Text(_errorMessage, style: TextStyle(color: Colors.red)),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _register,
              child: Text("Registra il Negozio"),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔹 Registra l'utente su Firebase
  Future<void> _register() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    String shopName = _shopNameController.text.trim();

    if (email.isEmpty || password.isEmpty || shopName.isEmpty) {
      setState(() => _errorMessage = "Compila tutti i campi.");
      return;
    }

    User? user = await _authService.registerVendor(email, password, shopName);
    if (user != null) {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (context) => VendorHome(uid: user.uid)));
    } else {
      setState(() => _errorMessage = "Errore nella registrazione.");
    }
  }
}

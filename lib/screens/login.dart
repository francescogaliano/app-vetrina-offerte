import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'user_home.dart';
import 'vendor_home.dart';
import 'user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

UserModel? loggedInUser; // Oggetto dell'utente loggato
String loggedInVendor = ""; // Se è un negozio

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  List<dynamic> usersList = []; // Carica una sola volta

  @override
  void initState() {
    super.initState();
    _loadUserDatabase(); // Carichiamo il file una sola volta all'avvio
  }

  Future<void> _loadUserDatabase() async {
    final String response =
        await rootBundle.loadString('assets/user_data.json');
    final List<dynamic> data = json.decode(response);

    setState(() {
      usersList = data; // Memorizziamo tutti gli utenti in memoria
    });

    print("📂 Database utenti caricato con ${usersList.length} utenti.");
  }

  Future<void> _login() async {
    if (usersList.isEmpty) {
      print("⚠️ Nessun database utenti caricato!");
      return;
    }

    print("🔹 Tentativo di login con username: ${_usernameController.text}");

    // Cerchiamo l'utente nella lista DOPO che l'utente ha inserito i dati
    var foundUser = usersList.firstWhere(
      (user) => user['username'] == _usernameController.text,
      orElse: () => null,
    );

    if (foundUser == null) {
      print("⚠️ Utente non trovato!");
      return;
    }

    if (_passwordController.text == foundUser['password']) {
      print(
          "✅ Login riuscito per ${foundUser['username']} con ruolo ${foundUser['role']}");

      // Salva l'utente loggato
      loggedInUser = UserModel.fromJson(foundUser);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'loggedInUser', json.encode(loggedInUser!.toJson()));

      // Naviga alla home corrispondente
      if (foundUser['role'] == "vendor") {
        loggedInVendor = foundUser['username']; // Segna che è un venditore
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => VendorHome(userData: foundUser)),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => UserHome(userData: foundUser)),
        );
      }
    } else {
      print("❌ Password errata!");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/logo.png', height: 100),
              SizedBox(height: 20),
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(labelText: 'Username'),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed:
                    _login, // Ora chiama direttamente la funzione di login
                child: Text('Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

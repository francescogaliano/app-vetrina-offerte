import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';

class ProfilePage extends StatefulWidget {
  final String uid; // UID dell'utente autenticato

  const ProfilePage({super.key, required this.uid});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? userData;
  bool isLoading = true;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _shopController = TextEditingController();
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  /// 🔹 Recupera i dati dell'utente da Firestore
  Future<void> _fetchUserData() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .get();

      if (doc.exists) {
        setState(() {
          userData = doc.data() as Map<String, dynamic>?;
          _nameController.text = userData?['name'] ?? '';
          _shopController.text = userData?['shopName'] ?? '';
          isLoading = false;
        });
      }
    } catch (e) {
      print("Errore nel recupero dati utente: $e");
    }
  }

  /// 🔹 Permette di modificare nome o shopName
  Future<void> _updateProfile() async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .update({
        'name': _nameController.text.trim(),
        if (userData?['role'] == 'vendor')
          'shopName': _shopController.text.trim(),
      });

      setState(() {
        userData?['name'] = _nameController.text.trim();
        if (userData?['role'] == 'vendor') {
          userData?['shopName'] = _shopController.text.trim();
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Dati aggiornati con successo!")),
      );
    } catch (e) {
      print("Errore nell'aggiornamento profilo: $e");
    }
  }

  /// 🔹 Permette di cambiare la password con verifica della password attuale
  Future<void> _changePassword() async {
    User? user = FirebaseAuth.instance.currentUser;

    try {
      AuthCredential credential = EmailAuthProvider.credential(
        email: user!.email!,
        password: _oldPasswordController.text.trim(),
      );

      await user.reauthenticateWithCredential(credential);

      await user.updatePassword(_newPasswordController.text.trim());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Password aggiornata con successo!")),
      );

      _oldPasswordController.clear();
      _newPasswordController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Errore: password errata o troppo debole.")),
      );
    }
  }

  /// 🔹 Effettua il logout e torna alla LoginScreen
  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text("Profilo Utente")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 🔹 Nome e Ruolo
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: "Nome"),
            ),
            if (userData?['role'] == 'vendor')
              TextField(
                controller: _shopController,
                decoration: InputDecoration(labelText: "Nome Negozio"),
              ),
            SizedBox(height: 10),
            Text("Email: ${userData?['email']}",
                style: TextStyle(fontSize: 16)),
            Text("Ruolo: ${userData?['role']}",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),

            // 🔹 Pulsante Modifica Dati
            ElevatedButton(
              onPressed: _updateProfile,
              child: Text("Modifica Dati"),
            ),
            SizedBox(height: 20),

            // 🔹 Cambio Password
            ExpansionTile(
              title: Text("🔐 Cambia Password",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              children: [
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: _oldPasswordController,
                        obscureText: true,
                        decoration:
                            InputDecoration(labelText: "Password Attuale"),
                      ),
                      TextField(
                        controller: _newPasswordController,
                        obscureText: true,
                        decoration:
                            InputDecoration(labelText: "Nuova Password"),
                      ),
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _changePassword,
                        child: Text("Aggiorna Password"),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // 🔹 Logout
            SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _logout,
              icon: Icon(Icons.logout, color: Colors.white),
              label: Text("Logout"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}

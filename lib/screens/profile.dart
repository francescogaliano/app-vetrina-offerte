import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class ProfilePage extends StatefulWidget {
  final Map<String, dynamic> userData;
  final VoidCallback logoutCallback;

  ProfilePage({required this.userData, required this.logoutCallback});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late TextEditingController _nameController;
  late TextEditingController _surnameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _currentPasswordController;
  late TextEditingController _newPasswordController;
  bool isEditing = false;
  bool isChangingPassword = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userData['name']);
    _surnameController =
        TextEditingController(text: widget.userData['surname']);
    _emailController = TextEditingController(text: widget.userData['email']);
    _phoneController = TextEditingController(text: widget.userData['phone']);
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
  }

  Future<void> _saveUserData() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/user_data.json');

      Map<String, dynamic> updatedUserData = {
        "username": widget.userData['username'],
        "password":
            widget.userData['password'], // Mantiene la password esistente
        "name": _nameController.text,
        "surname": _surnameController.text,
        "email": _emailController.text,
        "phone": _phoneController.text
      };

      await file.writeAsString(jsonEncode(updatedUserData));
      setState(() {
        widget.userData.addAll(updatedUserData);
        isEditing = false;
      });
    } catch (e) {
      print("Errore nel salvataggio dei dati: $e");
    }
  }

  Future<void> _changePassword() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/user_data.json');

      if (_currentPasswordController.text != widget.userData['password']) {
        setState(() {
          errorMessage = "La password attuale non è corretta!";
        });
        return;
      }

      Map<String, dynamic> updatedUserData = {
        ...widget.userData,
        "password": _newPasswordController.text
      };

      await file.writeAsString(jsonEncode(updatedUserData));

      setState(() {
        widget.userData['password'] = _newPasswordController.text;
        isChangingPassword = false;
        errorMessage = null;
      });

      print("✅ Password aggiornata con successo!");
    } catch (e) {
      print("❌ Errore nel salvataggio della password: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.blue,
              child: Text(
                widget.userData['name'][0] + widget.userData['surname'][0],
                style: TextStyle(fontSize: 24, color: Colors.white),
              ),
            ),
            SizedBox(height: 20),
            isEditing
                ? Column(
                    children: [
                      TextField(
                          controller: _nameController,
                          decoration: InputDecoration(labelText: 'Nome')),
                      TextField(
                          controller: _surnameController,
                          decoration: InputDecoration(labelText: 'Cognome')),
                      TextField(
                          controller: _emailController,
                          decoration: InputDecoration(labelText: 'Email')),
                      TextField(
                          controller: _phoneController,
                          decoration: InputDecoration(labelText: 'Telefono')),
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _saveUserData,
                        child: Text('Salva'),
                      ),
                      TextButton(
                        onPressed: () => setState(() => isEditing = false),
                        child: Text('Annulla'),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      Text('Nome: ${widget.userData['name']}',
                          style: TextStyle(fontSize: 18)),
                      Text('Cognome: ${widget.userData['surname']}',
                          style: TextStyle(fontSize: 18)),
                      Text('Email: ${widget.userData['email']}',
                          style: TextStyle(fontSize: 18)),
                      Text('Telefono: ${widget.userData['phone']}',
                          style: TextStyle(fontSize: 18)),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => setState(() => isEditing = true),
                        child: Text('Modifica Dati'),
                      ),
                      ElevatedButton(
                        onPressed: () =>
                            setState(() => isChangingPassword = true),
                        child: Text('Cambia Password'),
                      ),
                    ],
                  ),
            if (isChangingPassword)
              Column(
                children: [
                  TextField(
                    controller: _currentPasswordController,
                    decoration: InputDecoration(labelText: 'Password Attuale'),
                    obscureText: true,
                  ),
                  TextField(
                    controller: _newPasswordController,
                    decoration: InputDecoration(labelText: 'Nuova Password'),
                    obscureText: true,
                  ),
                  if (errorMessage != null)
                    Text(errorMessage!, style: TextStyle(color: Colors.red)),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _changePassword,
                    child: Text('Salva Password'),
                  ),
                  TextButton(
                    onPressed: () => setState(() => isChangingPassword = false),
                    child: Text('Annulla'),
                  ),
                ],
              ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: widget.logoutCallback,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Logout', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

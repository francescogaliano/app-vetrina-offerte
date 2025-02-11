import 'package:flutter/material.dart';
import 'vendor_offers.dart';
import 'chat_page.dart'; // Importa la chat corretta
import 'profile.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class VendorHome extends StatefulWidget {
  final Map<String, dynamic> userData;

  VendorHome({required this.userData});

  @override
  _VendorHomeState createState() => _VendorHomeState();
}

class _VendorHomeState extends State<VendorHome> {
  int _selectedIndex = 0;
  String loggedInVendor = "";
  Map<String, List<String>> chatMessages = {};

  @override
  void initState() {
    super.initState();
    _loadVendorSession();
    _loadVendorChats();
  }

  Future<void> _loadVendorSession() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? vendorData = prefs.getString('loggedInUser');
    if (vendorData != null) {
      Map<String, dynamic> vendorMap = jsonDecode(vendorData);
      setState(() {
        loggedInVendor = vendorMap['username']; // Nome del negozio
      });
    }
  }

  Future<void> _loadVendorChats() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? chatsJson = prefs.getString('chat_$loggedInVendor');
    if (chatsJson != null) {
      setState(() {
        chatMessages = Map<String, List<String>>.from(json
            .decode(chatsJson)
            .map((key, value) => MapEntry(key, List<String>.from(value))));
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _logout() {
    SharedPreferences.getInstance().then((prefs) {
      prefs.remove('loggedInUser');
    });
    Navigator.pushReplacementNamed(context, "/login");
  }

  List<Widget> _pages() {
    return [
      VendorOffers(), // Gestione offerte del venditore
      ChatListPage(
        startChat: (String
            userName) {}, // Lasciato vuoto perché il venditore non avvia chat
        isVendor: true,
        currentUser:
            loggedInVendor, // Passiamo il nome del venditore per filtrare le chat
      ),
      ProfilePage(userData: widget.userData, logoutCallback: _logout),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            color: Colors.orange,
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () => _onItemTapped(0),
                  child: Text('Le Mie Offerte',
                      style: TextStyle(color: Colors.white, fontSize: 18)),
                ),
                TextButton(
                  onPressed: () => _onItemTapped(1),
                  child: Text('Chat Clienti',
                      style: TextStyle(color: Colors.white, fontSize: 18)),
                ),
                TextButton(
                  onPressed: () => _onItemTapped(2),
                  child: Text('Profilo',
                      style: TextStyle(color: Colors.white, fontSize: 18)),
                ),
              ],
            ),
          ),
          Expanded(child: _pages()[_selectedIndex]),
        ],
      ),
    );
  }
}

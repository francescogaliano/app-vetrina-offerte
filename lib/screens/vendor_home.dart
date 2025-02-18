import 'package:flutter/material.dart';
import 'vendor_offers.dart';
import 'chat_list_page.dart';
import 'profile.dart';
import 'login_screen.dart';
import '../services/auth_service.dart';
import '../services/firebase_auth_service.dart';
//import 'package:shared_preferences/shared_preferences.dart';
//import 'dart:convert';

class VendorHome extends StatefulWidget {
  //final Map<String, dynamic> userData;
  final String uid;
  final int initialPage; // Parametro per gestire la pagina iniziale

  const VendorHome({required this.uid, this.initialPage = 0, Key? key})
      : super(key: key);

  @override
  _VendorHomeState createState() => _VendorHomeState();
}

class _VendorHomeState extends State<VendorHome> {
  Map<String, dynamic>? userData;
  bool isLoading = true;
  int _selectedIndex = 0;

  String loggedInVendor = "";
  Map<String, List<String>> chatMessages = {};

  @override
  void initState() {
    super.initState();
    //_loadVendorSession();
    //_loadVendorChats();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    Map<String, dynamic>? fetchedData =
        await FirebaseAuthService().fetchUserData(widget.uid);
    setState(() {
      userData = fetchedData;
      isLoading = false;
      _selectedIndex = widget.initialPage; // Imposta la landing page
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _logout() {
    AuthService().logout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

/*   void _startChat(String customerId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(
          currentUserId: widget.uid, // L'UID del venditore
          receiverUserId: customerId, // L'UID del cliente
        ),
      ),
    );
  } */

  List<Widget> _widgetOptions() {
    if (userData == null) {
      return [
        Center(child: CircularProgressIndicator())
      ]; // Attesa caricamento dati
    }
    return [
      VendorOffers(uid: widget.uid),
      ChatListPage(uid: widget.uid), // Nuova pagina lista chat
      ProfilePage(uid: widget.uid),
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
          //Expanded(child: _pages()[_selectedIndex]),
          Expanded(
            child: userData == null
                ? Center(child: CircularProgressIndicator()) // Mostra loading
                : _widgetOptions()[_selectedIndex],
          ),
        ],
      ),
    );
  }
}

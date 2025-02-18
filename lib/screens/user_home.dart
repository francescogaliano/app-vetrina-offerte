import 'package:flutter/material.dart';
//import 'package:firebase_auth/firebase_auth.dart';
import 'chat_page.dart';
import 'chat_list_page.dart';
import 'profile.dart';
//import 'login_screen.dart';
import 'user_offers.dart';
import '../models/user_model.dart';
import '../services/firebase_auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserHome extends StatefulWidget {
  //final Map<String, dynamic> userData;
  final String uid;
  final int initialPage; // Parametro per gestire la pagina iniziale

  const UserHome({required this.uid, this.initialPage = 0, Key? key})
      : super(key: key);

  @override
  _UserHomeState createState() => _UserHomeState();
}

class _UserHomeState extends State<UserHome> {
  Map<String, dynamic>? userData;
  bool isLoading = true;
  int _selectedIndex = 0;

  bool isLoggedIn = true;
  Map<String, List<String>> chatMessages = {};
  String selectedChat = '';
  String selectedVendor = "";
  UserModel? loggedInUser;

  List<String> selectedCategories = [];
  DateTime? startDate;
  DateTime? endDate;
  bool isChatting = false;
  bool isFilterBoxExpanded = false;

  final List<String> allCategories = [
    'Abbigliamento',
    'Elettronica',
    'Cibo',
    'Gioielli',
    'Sport'
  ];
  final TextEditingController minDiscountController = TextEditingController();
  final TextEditingController maxDiscountController = TextEditingController();

  //final FirebaseAuthService _authService = FirebaseAuthService();

  @override
  void dispose() {
    minDiscountController.dispose();
    maxDiscountController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    //_loadUserSession();
    _fetchUserData();
    //_selectedIndex = widget.initialPage; // Imposta la landing page
  }

/*   Future<void> _loadUserData() async {
    userData = await AuthService().getUserData(widget.uid);
    if (userData != null) {
      setState(() {}); // Ricarica lo stato quando i dati sono disponibili
    }
  } */
  Future<void> _fetchUserData() async {
    Map<String, dynamic>? fetchedData =
        await FirebaseAuthService().fetchUserData(widget.uid);
    setState(() {
      userData = fetchedData;
      isLoading = false;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _startChat(String vendorId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(
          currentUserId: widget.uid, // L'UID dell'utente
          receiverUserId: vendorId, // L'UID del venditore con cui chatta
        ),
      ),
    );
  }

/*   void _logout() async {
    await _authService.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  } */

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(title: Text("Benvenuto ${userData?['email']}")),
      body: Column(
        children: [
          Container(
            color: Colors.blue,
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () => _onItemTapped(0),
                  child: Text('Offerte',
                      style: TextStyle(color: Colors.white, fontSize: 18)),
                ),
                TextButton(
                  onPressed: () => _onItemTapped(1),
                  child: Text('Chat',
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
          if (selectedChat.isNotEmpty)
            Container(
              color: Colors.blue.shade100,
              padding: EdgeInsets.all(8),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () {
                      setState(() {
                        selectedChat = '';
                        isChatting = false;
                      });
                    },
                  ),
                  Expanded(
                    child: Text(
                      'Chat con $selectedChat',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          /* Expanded(
            child: selectedChat.isEmpty
                ? _widgetOptions().elementAt(_selectedIndex)
                : ChatPage(
                    vendorName: selectedChat,
                    currentUser: loggedInUser!.username),
          ), */
          Expanded(
            child: userData == null
                ? Center(child: CircularProgressIndicator()) // Mostra loading
                : _widgetOptions()[_selectedIndex],
          ),
        ],
      ),
    );
  }

  List<Widget> _widgetOptions() {
    if (userData == null) {
      return [
        Center(child: CircularProgressIndicator())
      ]; // Attesa caricamento dati
    }
    return [
      UserOffersPage(uid: widget.uid),
      ChatListPage(uid: widget.uid), // Nuova pagina lista chat
      ProfilePage(uid: widget.uid),
    ];
  }
}

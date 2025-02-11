import 'package:flutter/material.dart';
//import 'offers_list.dart';
import 'chat_page.dart';
import 'profile.dart';
import 'login.dart';
import 'user_offers.dart';
import 'user_model.dart';

class UserHome extends StatefulWidget {
  final Map<String, dynamic> userData;

  UserHome({required this.userData});

  @override
  _UserHomeState createState() => _UserHomeState();
}

class _UserHomeState extends State<UserHome> {
  int _selectedIndex = 0;
  bool isLoggedIn = true;
  Map<String, List<String>> chatMessages = {};
  String selectedChat = '';
  String selectedVendor = "";

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

  @override
  void dispose() {
    minDiscountController.dispose();
    maxDiscountController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadUserSession();
  }

  Future<void> _loadUserSession() async {
    // Recupera l'utente loggato se non è già stato caricato
    if (loggedInUser == null) {
      loggedInUser = UserModel.fromJson(widget.userData);
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      if (index == 1) {
        selectedChat = ''; // Torna alla lista delle chat
      } else {
        isChatting = false; // Se si cambia pannello, chiude la chat
        selectedChat = '';
      }
      _selectedIndex = index;
    });
  }

  void _startChat(String vendorName) {
    setState(() {
      selectedVendor = vendorName;
    });

    if (!chatMessages.containsKey(vendorName)) {
      chatMessages[vendorName] = [];
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(
            vendorName: selectedChat, currentUser: loggedInUser!.username),
      ),
    );
  }

  void _logout() {
    setState(() {
      isLoggedIn = false;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          //if (_selectedIndex == 0 && !isChatting) _buildFilterToggleButton(),
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
          Expanded(
            child: selectedChat.isEmpty
                ? _widgetOptions().elementAt(_selectedIndex)
                : ChatPage(
                    vendorName: selectedChat,
                    currentUser: loggedInUser!.username),
          ),
        ],
      ),
    );
  }

  List<Widget> _widgetOptions() {
    return <Widget>[
      UserOffersPage(),
      ChatListPage(
        startChat: _startChat,
        isVendor: false, // L'utente non è un venditore
        currentUser: loggedInUser!.username,
      ),
      ProfilePage(
        userData: widget.userData,
        logoutCallback: _logout,
      ),
    ];
  }
}

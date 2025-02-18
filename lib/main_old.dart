/* import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'screens/offers_list.dart';
import 'screens/chat_old.dart';
import 'screens/profile.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vetrina App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool isAuthenticated = false;
  Map<String, dynamic>? userData;

  Future<void> _loadUserData() async {
    final String response =
        await rootBundle.loadString('assets/user_data.json');
    final data = json.decode(response);
    setState(() {
      userData = data;
    });
  }

  void _login() {
    if (userData != null &&
        _usernameController.text == userData!['username'] &&
        _passwordController.text == userData!['password']) {
      setState(() {
        isAuthenticated = true;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => MainScreen(
                    userData: userData!,
                  )),
        );
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
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
              Image.asset(
                'assets/logo.png', // Assicurati che il file sia nella cartella assets
                height: 300,
              ),
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
                onPressed: _login,
                child: Text('Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  MainScreen({required this.userData});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  bool isLoggedIn = true;
  Map<String, List<String>> chatMessages = {};
  String selectedChat = '';

  double minDiscount = 0;
  double maxDiscount = 100;
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
  void initState() {
    super.initState();
    minDiscountController.text = minDiscount.toStringAsFixed(0);
    maxDiscountController.text = maxDiscount.toStringAsFixed(0);
  }

  @override
  void dispose() {
    minDiscountController.dispose();
    maxDiscountController.dispose();
    super.dispose();
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

  void _startChat(String negozio) {
    setState(() {
      chatMessages.putIfAbsent(negozio, () => []);
      selectedChat = negozio;
      isChatting = true;
      _selectedIndex = 1;
    });
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
          if (_selectedIndex == 0 && !isChatting) _buildFilterToggleButton(),
          if (_selectedIndex == 0 && !isChatting && isFilterBoxExpanded)
            _buildFilterBox(),
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
                : ChatDetailPage(
                    chatMessages: chatMessages, selectedChat: selectedChat),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterToggleButton() {
    return Padding(
      padding: EdgeInsets.all(8.0),
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            isFilterBoxExpanded = !isFilterBoxExpanded;
          });
        },
        child: Text(isFilterBoxExpanded ? 'Nascondi Filtri ▲' : 'Filtra ▼'),
      ),
    );
  }

  Widget _buildFilterBox() {
    return Padding(
      padding: EdgeInsets.all(8.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        color: Colors.lightBlue.shade50,
        child: Padding(
          padding: EdgeInsets.all(12.0),
          child: Column(
            children: [
              PopupMenuButton<String>(
                onOpened: () => setState(() {}),
                itemBuilder: (BuildContext context) {
                  return [
                    PopupMenuItem(
                      child: StatefulBuilder(
                        builder:
                            (BuildContext context, StateSetter setStatePopup) {
                          return Column(
                            children: allCategories.map((category) {
                              return CheckboxListTile(
                                title: Text(category),
                                value: selectedCategories.contains(category),
                                onChanged: (bool? value) {
                                  setState(() {
                                    if (value == true) {
                                      selectedCategories.add(category);
                                    } else {
                                      selectedCategories.remove(category);
                                    }
                                  });
                                  setStatePopup(() {});
                                },
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ),
                  ];
                },
                child: ListTile(
                  title: Text('Seleziona Categorie'),
                  trailing: Icon(Icons.arrow_drop_down),
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    selectedCategories.clear();
                  });
                },
                child: Text('Clear'),
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: minDiscountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: 'Sconto Minimo'),
                      onChanged: (value) {
                        setState(() {
                          minDiscount = double.tryParse(value) ?? 0;
                          minDiscountController.text =
                              minDiscount.toStringAsFixed(0);
                        });
                      },
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: maxDiscountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: 'Sconto Massimo'),
                      onChanged: (value) {
                        setState(() {
                          maxDiscount = double.tryParse(value) ?? 100;
                          maxDiscountController.text =
                              maxDiscount.toStringAsFixed(0);
                        });
                      },
                    ),
                  ),
                ],
              ),
              RangeSlider(
                values: RangeValues(minDiscount, maxDiscount),
                min: 0,
                max: 100,
                divisions: 20,
                labels: RangeLabels(
                  minDiscount.toStringAsFixed(0) + '%',
                  maxDiscount.toStringAsFixed(0) + '%',
                ),
                onChanged: (RangeValues values) {
                  setState(() {
                    minDiscount = values.start;
                    maxDiscount = values.end;
                    minDiscountController.text = minDiscount.toStringAsFixed(0);
                    maxDiscountController.text = maxDiscount.toStringAsFixed(0);
                  });
                },
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2101),
                        );
                        if (picked != null) {
                          setState(() {
                            startDate = picked;
                          });
                        }
                      },
                      child: Text(startDate == null
                          ? 'Data Inizio'
                          : startDate.toString().split(' ')[0]),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2101),
                        );
                        if (picked != null) {
                          setState(() {
                            endDate = picked;
                          });
                        }
                      },
                      child: Text(endDate == null
                          ? 'Data Fine'
                          : endDate.toString().split(' ')[0]),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _widgetOptions() {
    return <Widget>[
      OffersPage(
          startChat: _startChat,
          minDiscount: 0,
          maxDiscount: 100,
          //minDiscount: minDiscount,
          //maxDiscount: maxDiscount,
          selectedCategory:
              selectedCategories.isNotEmpty ? selectedCategories.first : '',
          startDate: startDate,
          endDate: endDate),
      ChatListPage(chatMessages: chatMessages, startChat: _startChat),
      ProfilePage(
        userData: widget.userData,
        logoutCallback: _logout,
      ),
    ];
  }
} */

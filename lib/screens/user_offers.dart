import 'package:flutter/material.dart';
import '../services/database_service.dart';
import 'chat_page.dart';
import 'user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class UserOffersPage extends StatefulWidget {
  @override
  _UserOffersPageState createState() => _UserOffersPageState();
}

class _UserOffersPageState extends State<UserOffersPage> {
  List<Offer> filteredOffers = [];
  String selectedCategory = "";
  double minDiscount = 0;
  double maxDiscount = 100;
  DateTime? startDateFilter;
  DateTime? endDateFilter;
  final List<String> categories = [
    "Abbigliamento",
    "Elettronica",
    "Cibo",
    "Gioielli",
    "Sport"
  ];
  late TextEditingController minDiscountController;
  late TextEditingController maxDiscountController;
  Map<String, List<String>> chatMessages = {};
  UserModel? loggedInUser;

  @override
  void initState() {
    super.initState();
    minDiscountController =
        TextEditingController(text: minDiscount.toStringAsFixed(0));
    maxDiscountController =
        TextEditingController(text: maxDiscount.toStringAsFixed(0));
    _loadUserSession();
    _loadOffers();
  }

  Future<void> _loadUserSession() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userData = prefs.getString('loggedInUser');

    if (userData == null || userData.isEmpty) {
      print("⚠️ Nessun utente salvato in SharedPreferences!");
      return;
    }

    try {
      Map<String, dynamic> userMap = jsonDecode(userData);
      setState(() {
        loggedInUser = UserModel.fromJson(userMap);
      });
      print("✅ Utente caricato: ${loggedInUser!.username}");
    } catch (e) {
      print("❌ Errore nel parsing del JSON: $e");
    }
  }

  void _loadOffers() {
    setState(() {
      filteredOffers = DatabaseService.getOffers()
          .where((offer) =>
              (selectedCategory.isEmpty ||
                  offer.category == selectedCategory) &&
              offer.discount >= minDiscount &&
              offer.discount <= maxDiscount &&
              (startDateFilter == null ||
                  offer.startDate != null &&
                      offer.startDate!.isAfter(startDateFilter!)) &&
              (endDateFilter == null ||
                  offer.endDate != null &&
                      offer.endDate!.isBefore(endDateFilter!)))
          .toList();
    });
  }

  void _startChat(String vendorName) {
    if (loggedInUser == null) {
      print("⚠️ Nessun utente loggato!");
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(
          vendorName: vendorName,
          currentUser: loggedInUser!.username,
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            title: Text("Filtra Offerte"),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  DropdownButtonFormField(
                    value:
                        selectedCategory.isNotEmpty ? selectedCategory : null,
                    items: categories.map((String category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedCategory = value.toString();
                      });
                    },
                    decoration: InputDecoration(labelText: "Categoria"),
                  ),
                  TextField(
                    controller: minDiscountController,
                    decoration: InputDecoration(labelText: "Sconto Minimo"),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        double? val = double.tryParse(value);
                        if (val != null && val >= 0 && val <= maxDiscount) {
                          setDialogState(() {
                            minDiscount = val;
                          });
                        }
                      });
                    },
                  ),
                  TextField(
                    controller: maxDiscountController,
                    decoration: InputDecoration(labelText: "Sconto Massimo"),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        double? val = double.tryParse(value);
                        if (val != null && val >= minDiscount && val <= 100) {
                          setDialogState(() {
                            maxDiscount = val;
                          });
                        }
                      });
                    },
                  ),
                  RangeSlider(
                    values: RangeValues(minDiscount, maxDiscount),
                    min: 0,
                    max: 100,
                    divisions: 20,
                    labels: RangeLabels(
                      "${minDiscount.toStringAsFixed(0)}%",
                      "${maxDiscount.toStringAsFixed(0)}%",
                    ),
                    onChanged: (RangeValues values) {
                      setDialogState(() {
                        minDiscount = values.start;
                        maxDiscount = values.end;
                        minDiscountController.text =
                            minDiscount.toStringAsFixed(0);
                        maxDiscountController.text =
                            maxDiscount.toStringAsFixed(0);
                      });
                    },
                  ),
                  ListTile(
                    title: Text(startDateFilter == null
                        ? "Seleziona data di inizio"
                        : "Inizio: ${startDateFilter!.toLocal().toString().split(' ')[0]}"),
                    trailing: Icon(Icons.calendar_today),
                    onTap: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() {
                          startDateFilter = picked;
                        });
                      }
                    },
                  ),
                  ListTile(
                    title: Text(endDateFilter == null
                        ? "Seleziona data di fine"
                        : "Fine: ${endDateFilter!.toLocal().toString().split(' ')[0]}"),
                    trailing: Icon(Icons.calendar_today),
                    onTap: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() {
                          endDateFilter = picked;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: Text("Annulla"),
                onPressed: () => Navigator.of(context).pop(),
              ),
              ElevatedButton(
                child: Text("Applica"),
                onPressed: () {
                  _loadOffers();
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                onPressed: () {
                  setDialogState(() {
                    selectedCategory = "";
                    minDiscount = 0;
                    maxDiscount = 100;
                    startDateFilter = null;
                    endDateFilter = null;
                    minDiscountController.text = "0";
                    maxDiscountController.text = "100";
                  });
                },
                child:
                    Text("Reset Filtri", style: TextStyle(color: Colors.red)),
              ),
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Offerte Disponibili"),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: filteredOffers.length,
        itemBuilder: (context, index) {
          Offer offer = filteredOffers[index];

          return Card(
            elevation: 4,
            margin: EdgeInsets.all(8),
            child: ListTile(
              contentPadding: EdgeInsets.all(10),
              leading: Image.network(
                offer.imageUrl,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              ),
              title: Text(offer.title,
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("${offer.discount}% di sconto"),
                  Text("Categoria: ${offer.category}"),
                  Text("Negozio: ${offer.vendor}"),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => _startChat(offer.vendor),
                    child: Text("Chatta con il venditore"),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

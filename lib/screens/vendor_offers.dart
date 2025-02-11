import 'package:flutter/material.dart';
import '../services/database_service.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class VendorOffers extends StatefulWidget {
  @override
  _VendorOffersState createState() => _VendorOffersState();
}

class _VendorOffersState extends State<VendorOffers> {
  List<Offer> vendorOffers = [];
  String loggedInVendor = ""; // Nome del negozio
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

  @override
  void initState() {
    super.initState();
    minDiscountController =
        TextEditingController(text: minDiscount.toStringAsFixed(0));
    maxDiscountController =
        TextEditingController(text: maxDiscount.toStringAsFixed(0));
    _loadVendorSession();
  }

  Future<void> _loadVendorSession() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? vendorData = prefs.getString('loggedInUser');
    if (vendorData != null) {
      Map<String, dynamic> vendorMap = jsonDecode(vendorData);
      setState(() {
        loggedInVendor = vendorMap['username']; // Nome del negozio
        _loadOffers(); // Carichiamo le offerte SOLO del venditore
      });
    }
  }

  void _loadOffers() {
    setState(() {
      vendorOffers = DatabaseService.getOffers()
          .where((offer) =>
              offer.vendor ==
                  loggedInVendor && // Mostra solo le offerte del venditore loggato
              (selectedCategory.isEmpty ||
                  offer.category == selectedCategory) &&
              offer.discount >= minDiscount &&
              offer.discount <= maxDiscount &&
              (startDateFilter == null ||
                  (offer.startDate != null &&
                      offer.startDate!.isAfter(startDateFilter!))) &&
              (endDateFilter == null ||
                  (offer.endDate != null &&
                      offer.endDate!.isBefore(endDateFilter!))))
          .toList();
    });
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

  void _showAddOfferDialog() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    final TextEditingController discountController = TextEditingController();
    final TextEditingController imageUrlController = TextEditingController();
    DateTime? startDate;
    DateTime? endDate;
    String selectedCategory = categories.first;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Aggiungi Nuova Offerta"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(labelText: "Titolo"),
                ),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(labelText: "Descrizione"),
                ),
                DropdownButtonFormField(
                  value: selectedCategory,
                  items: categories.map((String category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    selectedCategory = value.toString();
                  },
                  decoration: InputDecoration(labelText: "Categoria"),
                ),
                TextField(
                  controller: discountController,
                  decoration: InputDecoration(labelText: "Sconto (%)"),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: imageUrlController,
                  decoration: InputDecoration(labelText: "URL Immagine"),
                ),
                ListTile(
                  title: Text(startDate == null
                      ? "Seleziona data di inizio"
                      : "Inizio: ${startDate!.toLocal()}"),
                  trailing: Icon(Icons.calendar_today),
                  onTap: () async {
                    DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() {
                        startDate = picked;
                      });
                    }
                  },
                ),
                ListTile(
                  title: Text(endDate == null
                      ? "Seleziona data di fine"
                      : "Fine: ${endDate!.toLocal()}"),
                  trailing: Icon(Icons.calendar_today),
                  onTap: () async {
                    DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() {
                        endDate = picked;
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
              child: Text("Aggiungi"),
              onPressed: () {
                String newId = Random().nextInt(10000).toString();
                Offer newOffer = Offer(
                  id: newId,
                  title: titleController.text,
                  description: descriptionController.text,
                  category: selectedCategory,
                  discount: int.tryParse(discountController.text) ?? 0,
                  imageUrl: imageUrlController.text,
                  vendor: loggedInVendor, // Da recuperare dalle credenziali
                  startDate: startDate, // Aggiunto
                  endDate: endDate, // Aggiunto
                );

                DatabaseService.addOffer(newOffer);
                _loadOffers();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _deleteOffer(String id) {
    DatabaseService.deleteOffer(id);
    _loadOffers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Le Mie Offerte"),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: vendorOffers.length,
        itemBuilder: (context, index) {
          Offer offer = vendorOffers[index];
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
                  Text("Inizio: ${offer.startDate?.toLocal()}"),
                  Text("Fine: ${offer.endDate?.toLocal()}"),
                  Text("Negozio: ${offer.vendor}"),
                ],
              ),
              trailing: IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deleteOffer(offer.id),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddOfferDialog,
        child: Icon(Icons.add),
      ),
    );
  }
}

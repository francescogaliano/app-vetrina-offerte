import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/chat_service.dart';
import 'chat_page.dart';

class VendorOffers extends StatefulWidget {
  final String uid; // L'UID del venditore

  const VendorOffers({required this.uid, Key? key}) : super(key: key);

  @override
  _VendorOffersState createState() => _VendorOffersState();
}

class _VendorOffersState extends State<VendorOffers> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ChatService _chatService = ChatService();
  List<String> selectedCategories =
      []; // Lista per la selezione multipla delle categorie
  // String selectedCategory = "";
  bool isFiltered = false;
  double minDiscount = 0;
  double maxDiscount = 100;
  DateTime? startDate;
  DateTime? endDate;
  final List<String> categories = [
    "Abbigliamento",
    "Elettronica",
    "Cibo",
    "Gioielli",
    "Sport"
  ];

/*   /// **🔹 Recupera le offerte del venditore corrente**
  Stream<QuerySnapshot> _getVendorOffers() {
    return _firestore
        .collection('offers')
        .where('vendorId', isEqualTo: widget.uid)
        .snapshots();
  } */

  Stream<QuerySnapshot> _getVendorOffers() {
    Query query = _firestore
        .collection('offers')
        .where('vendorId', isEqualTo: widget.uid);

    if (selectedCategories.isNotEmpty) {
      query = query.where('category', whereIn: selectedCategories);
    }

    if (minDiscount >= 0 || maxDiscount <= 100) {
      query = query
          .orderBy('discount')
          .where('discount', isGreaterThanOrEqualTo: minDiscount);
      query = query.where('discount', isLessThanOrEqualTo: maxDiscount);
    }

    if (startDate != null) {
      query = query.where('startDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate!));
    }

    if (endDate != null) {
      query = query.where('endDate',
          isLessThanOrEqualTo: Timestamp.fromDate(endDate!));
    }

    return query.snapshots();
  }

  /// ✅ Mostra la finestra per i filtri
  void _showFilterDialog() {
    double tempMinDiscount = minDiscount;
    double tempMaxDiscount = maxDiscount;
    List<String> tempSelectedCategories = List.from(selectedCategories);
    DateTime? tempStartDate = startDate;
    DateTime? tempEndDate = endDate;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text("Filtra Offerte"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ✅ Dropdown con CheckboxListTile per selezionare più categorie
                    ExpansionTile(
                      title: Text("Categorie"),
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: () {
                                setDialogState(() {
                                  tempSelectedCategories =
                                      List.from(categories);
                                });
                              },
                              child: Text("Seleziona Tutti"),
                            ),
                            TextButton(
                              onPressed: () {
                                setDialogState(() {
                                  tempSelectedCategories.clear();
                                });
                              },
                              child: Text("Clear"),
                            ),
                          ],
                        ),
                        Column(
                          children: categories.map((String category) {
                            return CheckboxListTile(
                              title: Text(category),
                              value: tempSelectedCategories.contains(category),
                              onChanged: (bool? value) {
                                setDialogState(() {
                                  if (value == true) {
                                    tempSelectedCategories.add(category);
                                  } else {
                                    tempSelectedCategories.remove(category);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    TextField(
                      controller: TextEditingController(
                          text: tempMinDiscount.toStringAsFixed(0)),
                      decoration: InputDecoration(labelText: "Sconto Minimo"),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setDialogState(() {
                          double? parsedValue = double.tryParse(value);
                          if (parsedValue != null &&
                              parsedValue >= 0 &&
                              parsedValue <= tempMaxDiscount) {
                            tempMinDiscount = parsedValue;
                          }
                        });
                      },
                    ),
                    TextField(
                      controller: TextEditingController(
                          text: tempMaxDiscount.toStringAsFixed(0)),
                      decoration: InputDecoration(labelText: "Sconto Massimo"),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setDialogState(() {
                          double? parsedValue = double.tryParse(value);
                          if (parsedValue != null &&
                              parsedValue >= tempMinDiscount &&
                              parsedValue <= 100) {
                            tempMaxDiscount = parsedValue;
                          }
                        });
                      },
                    ),
                    RangeSlider(
                      values: RangeValues(tempMinDiscount, tempMaxDiscount),
                      min: 0,
                      max: 100,
                      divisions: 20,
                      labels: RangeLabels(
                        "${tempMinDiscount.toStringAsFixed(0)}%",
                        "${tempMaxDiscount.toStringAsFixed(0)}%",
                      ),
                      onChanged: (RangeValues values) {
                        setDialogState(() {
                          tempMinDiscount = values.start;
                          tempMaxDiscount = values.end;
                        });
                      },
                    ),
                    ListTile(
                      title: Text(tempStartDate == null
                          ? "Seleziona data di inizio"
                          : "Inizio: ${tempStartDate!.toLocal().toString().split(' ')[0]}"),
                      trailing: Icon(Icons.calendar_today),
                      onTap: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            tempStartDate = picked;
                          });
                        }
                      },
                    ),
                    ListTile(
                      title: Text(tempEndDate == null
                          ? "Seleziona data di fine"
                          : "Fine: ${tempEndDate!.toLocal().toString().split(' ')[0]}"),
                      trailing: Icon(Icons.calendar_today),
                      onTap: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            tempEndDate = picked;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: Text("Reset"),
                  onPressed: () {
                    setDialogState(() {
                      tempSelectedCategories.clear();
                      tempMinDiscount = 0;
                      tempMaxDiscount = 100;
                      tempStartDate = null;
                      tempEndDate = null;
                    });
                  },
                ),
                TextButton(
                  child: Text("Annulla"),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                ElevatedButton(
                  child: Text("Applica"),
                  onPressed: () {
                    setState(() {
                      selectedCategories = tempSelectedCategories;
                      minDiscount = tempMinDiscount;
                      maxDiscount = tempMaxDiscount;
                      startDate = tempStartDate;
                      endDate = tempEndDate;
                      isFiltered = true;
                    });
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// **🔹 Mostra il modulo per aggiungere un'offerta**
  void _showAddOfferDialog() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    final TextEditingController discountController = TextEditingController();
    final TextEditingController imageUrlController = TextEditingController();

    String selectedCategory = categories.first;

    DateTime? startDate;
    DateTime? endDate;

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
                    setState(() {
                      selectedCategory = value.toString();
                    });
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
              onPressed: () async {
                try {
                  await _firestore.collection('offers').add({
                    'title': titleController.text.trim(),
                    'description': descriptionController.text.trim(),
                    'category': selectedCategory,
                    'discount': int.tryParse(discountController.text) ?? 0,
                    'imageUrl': imageUrlController.text.trim().isNotEmpty
                        ? imageUrlController.text.trim()
                        : null, // Se non c'è immagine, imposta `null`
                    'vendorId': widget.uid,
                    'startDate': startDate != null
                        ? Timestamp.fromDate(startDate!)
                        : null,
                    'endDate':
                        endDate != null ? Timestamp.fromDate(endDate!) : null,
                    'timestamp': FieldValue.serverTimestamp(),
                  });
                  Navigator.of(context).pop();
                } catch (e) {
                  print("❌ Errore nell'aggiunta dell'offerta: $e");
                }
              },
            ),
          ],
        );
      },
    );
  }

  /// **🔹 Elimina un'offerta**
  Future<void> _deleteOffer(String offerId) async {
    try {
      await _firestore.collection('offers').doc(offerId).delete();
    } catch (e) {
      print("❌ Errore nell'eliminazione dell'offerta: $e");
    }
  }

  Stream<QuerySnapshot> _getCustomerChats() {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: widget.uid)
        .snapshots();
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
      body: StreamBuilder<QuerySnapshot>(
        stream: _getVendorOffers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("Nessuna offerta disponibile"));
          }

          var offers = snapshot.data!.docs;

          return ListView.builder(
            itemCount: offers.length,
            itemBuilder: (context, index) {
              var offer = offers[index];

              return Card(
                elevation: 4,
                margin: EdgeInsets.all(8),
                child: ListTile(
                  contentPadding: EdgeInsets.all(10),
                  leading: offer['imageUrl'] != null
                      ? Image.network(
                          offer['imageUrl'],
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        )
                      : Icon(Icons.image_not_supported, size: 50),
                  title: Text(
                    offer['title'],
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("${offer['discount']}% di sconto"),
                      Text("Categoria: ${offer['category']}"),
                      Text(
                        "Inizio: ${offer['startDate'] != null ? (offer['startDate'] as Timestamp).toDate() : 'Non disponibile'}",
                      ),
                      Text(
                        "Fine: ${offer['endDate'] != null ? (offer['endDate'] as Timestamp).toDate() : 'Non disponibile'}",
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteOffer(offer.id),
                  ),
                ),
              );
            },
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

import 'package:flutter/material.dart';
import 'chat_page.dart';
import 'offer_details.dart';
import '../services/api_service.dart';

class UserOffersPage extends StatefulWidget {
  final String uid;

  const UserOffersPage({required this.uid, Key? key}) : super(key: key);

  @override
  _UserOffersPageState createState() => _UserOffersPageState();
}

class _UserOffersPageState extends State<UserOffersPage> {
  //final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>>? _offersFuture;
  List<String> selectedCategories = [];
  double minDiscount = 0;
  double maxDiscount = 100;
  DateTime? startDate;
  DateTime? endDate;
  //final ChatService _chatService = ChatService();

  final List<String> categories = [
    "Abbigliamento",
    "Elettronica",
    "Cibo",
    "Gioielli",
    "Sport"
  ];

  bool isFiltered = false;

  @override
  void initState() {
    super.initState();
    _offersFuture =
        _getFilteredOffers(); // ✅ Carichiamo le offerte una sola volta all'avvio
  }

  /// ✅ Recupera le offerte con o senza filtri
/*   Stream<QuerySnapshot> _getFilteredOffers() {
    Query query = _firestore.collection('offers');

    if (isFiltered) {
      if (selectedCategories.isNotEmpty) {
        query = query.where('category', arrayContainsAny: selectedCategories);
      }
      query = query.where('discount', isGreaterThanOrEqualTo: minDiscount);
      query = query.where('discount', isLessThanOrEqualTo: maxDiscount);
      if (startDate != null) {
        query = query.where('startDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate!));
      }
      if (endDate != null) {
        query = query.where('endDate',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate!));
      }
    }
    return query.snapshots();
  } */

  Future<List<Map<String, dynamic>>> _getFilteredOffers() async {
    print("🔄 Chiamata a _getFilteredOffers()");

    List<Map<String, dynamic>>? offers = await ApiService.getOffers(
      categories: selectedCategories.isNotEmpty ? selectedCategories : null,
      minDiscount: minDiscount,
      maxDiscount: maxDiscount,
      startDate: startDate != null ? startDate!.toIso8601String() : null,
      endDate: endDate != null ? endDate!.toIso8601String() : null,
    );

    if (offers != null) {
      print("✅ Offerte ricevute: ${offers.length}");
      return offers;
    } else {
      print("❌ Nessuna offerta ricevuta.");
      return [];
    }
  }

  /// **🔹 Recupera le offerte dal database**
  /* void _loadOffers() async {
    try {
      print("🔹 UID utente: ${widget.uid}");
      List<Map<String, dynamic>> fetchedOffers =
          await DatabaseService().getOffers();
      print("✅ Offerte caricate: ${fetchedOffers.length}");

      setState(() {
        filteredOffers = fetchedOffers
            .where((offer) =>
                (selectedCategory.isEmpty ||
                    offer['category'] == selectedCategory) &&
                offer['discount'] >= minDiscount &&
                offer['discount'] <= maxDiscount &&
                (startDateFilter == null ||
                    (offer['startDate'] != null &&
                        (offer['startDate'] as Timestamp)
                            .toDate()
                            .isAfter(startDateFilter!))) &&
                (endDateFilter == null ||
                    (offer['endDate'] != null &&
                        (offer['endDate'] as Timestamp)
                            .toDate()
                            .isBefore(endDateFilter!))))
            .toList();
      });
    } catch (e) {
      print("❌ Errore nel caricamento delle offerte: $e");
    }
  } */

  /// ✅ Mostra la finestra per i filtri
  Future<void> _showFilterDialog() async {
    double tempMinDiscount = minDiscount;
    double tempMaxDiscount = maxDiscount;
    List<String> tempSelectedCategories = List.from(selectedCategories);
    DateTime? tempStartDate = startDate;
    DateTime? tempEndDate = endDate;

    await showDialog(
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
                    setState(() {
                      _offersFuture =
                          _getFilteredOffers(); // ✅ Aggiorniamo le offerte dopo il filtro
                    });
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  /*  String _generateChatId(String userId1, String userId2) {
    List<String> ids = [userId1, userId2];
    ids.sort(); // Ordina gli ID per avere sempre la stessa chat tra due utenti
    return ids.join("_");
  }
 */
  /* Future<String> _createChatIfNotExists(String userId, String vendorId) async {
    String chatId = _getChatId(userId, vendorId);
    DocumentSnapshot chatDoc =
        await FirebaseFirestore.instance.collection('chats').doc(chatId).get();

    if (!chatDoc.exists) {
      await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
        'user1': userId,
        'user2': vendorId,
        'lastMessage': '',
        'timestamp': FieldValue.serverTimestamp(),
      });
    }

    return chatId;
  }
 */
  void _startChat(String vendorId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(
          currentUserId: widget.uid,
          receiverUserId: vendorId,
        ),
      ),
    );
  }
/*   void _startChat(String vendorId) async {
    String chatId = await _createChatIfNotExists(widget.uid, vendorId);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(
          currentUserId: widget.uid,
          receiverUserId: vendorId,
        ),
      ),
    );
  } */

  /*  String _getChatId(String user1, String user2) {
    List<String> ids = [user1, user2];
    ids.sort(); // Ordina per garantire sempre lo stesso ID
    return ids.join('_');
  } */

  /// 🔹 Converte un `Timestamp` in una `String` leggibile
  String _convertTimestamp(dynamic date) {
    if (date is String) {
      return date.split("T")[0]; // 🔹 YYYY-MM-DD
    }
    return "Non disponibile";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Le Mie Offerte"),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: () async {
              print("🔹 Bottone filtro premuto - Chiamo _showFilterDialog()");
              await _showFilterDialog();
              setState(() {
                _offersFuture =
                    _getFilteredOffers(); // ✅ Aggiorniamo dopo il filtro
              });
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>?>(
        future: _offersFuture, // 🔹 Ora usiamo FastAPI
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("Nessuna offerta disponibile"));
          }

          var offers = snapshot.data!;

          return ListView.builder(
            itemCount: offers.length,
            itemBuilder: (context, index) {
              var offer = offers[index];

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OfferDetailsPage(
                        offerId: offer["id"],
                      ),
                    ),
                  );
                },
                child: Card(
                  elevation: 4,
                  margin: EdgeInsets.all(8),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(10),
                    leading: offer["imageUrl"] != null &&
                            offer["imageUrl"].isNotEmpty
                        ? Image.network(
                            offer["imageUrl"],
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          )
                        : Icon(Icons.image_not_supported, size: 50),
                    title: Text(
                      offer["title"] ?? "Senza titolo",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("${offer["discount"] ?? 0}% di sconto"),
                        Text("Categoria: ${offer["category"] ?? "N/A"}"),
                        Text(
                          "Inizio: ${_convertTimestamp(offer["startDate"])}",
                        ),
                        Text(
                          "Fine: ${_convertTimestamp(offer["endDate"])}",
                        ),
                        SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () => _startChat(offer["vendorId"]),
                          child: Text("Chatta con il venditore"),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

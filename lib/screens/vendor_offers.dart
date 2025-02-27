import 'package:flutter/material.dart';
//import 'package:cloud_firestore/cloud_firestore.dart';
//import '../services/chat_service.dart';
//import 'chat_page.dart';
import 'offer_details.dart';
import '../services/api_service.dart';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';

class VendorOffers extends StatefulWidget {
  final String uid; // L'UID del venditore

  const VendorOffers({required this.uid, Key? key}) : super(key: key);

  @override
  _VendorOffersState createState() => _VendorOffersState();
}

class _VendorOffersState extends State<VendorOffers> {
  void _openCreateOfferSheet() async {
    bool? offerCreated = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => CreateOfferSheet(vendorId: widget.uid),
    );

    if (offerCreated == true) {
      setState(() {}); // Ricarica la lista delle offerte
    }
  }

  //final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  //final ChatService _chatService = ChatService();
  List<String> selectedCategories =
      []; // Lista per la selezione multipla delle categorie

  List<File> selectedImages = [];
  File? coverImage; // L'immagine selezionata come copertina

  List<Map<String, dynamic>> vendorOffers = [];
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

  List<String> imageUrls = [];
  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _getVendorOffers(); // ✅ Carichiamo all'avvio
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _getVendorOffers();
  }

  /// 🔹 Recupera le offerte del venditore da FastAPI
  Future<void> _getVendorOffers() async {
    print("🔄 Chiamata a _getVendorOffers()");

    List<Map<String, dynamic>>? offers = await ApiService.getOffers(
      vendorId: widget.uid,
      categories: selectedCategories.isNotEmpty ? selectedCategories : null,
      minDiscount: minDiscount,
      maxDiscount: maxDiscount,
      startDate: startDate != null ? startDate!.toIso8601String() : null,
      endDate: endDate != null ? endDate!.toIso8601String() : null,
    );

    if (offers != null) {
      print("✅ Offerte ricevute: ${offers.length}");
      setState(() {
        vendorOffers = offers;
      });
    } else {
      print("❌ Nessuna offerta ricevuta.");
    }
    print("🔄 Chiamata a _getVendorOffers() - FINE");
  }

/*   Future<void> _pickImages() async {
    final List<XFile>? pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles != null && pickedFiles.isNotEmpty) {
      setState(() {
        selectedImages = pickedFiles.map((file) => File(file.path)).toList();
        if (coverImage == null && selectedImages.isNotEmpty) {
          coverImage = selectedImages
              .first; // Imposta la prima immagine come copertina di default
        }
      });
    }
  }

  Future<void> _uploadImages(String offerId) async {
    List<Map<String, dynamic>> uploadedImages = [];

    for (var image in selectedImages) {
      Map<String, dynamic>? uploadedImage =
          await ApiService.uploadOfferImage(offerId, image);
      if (uploadedImage != null) {
        uploadedImages.add(uploadedImage);
      }
    }

    // Aggiorna l'offerta con la lista delle immagini
    await ApiService.updateOffer(offerId, {"images": uploadedImages});
  }
 */
  Future<void> _setCoverImage(String offerId, String imageUrl) async {
    await ApiService.setCoverImage(offerId, imageUrl);
    setState(() {
      var offer = vendorOffers.firstWhere((offer) => offer["id"] == offerId);
      for (var img in offer["images"]) {
        img["is_cover"] = img["url"] == imageUrl;
      }
    });
  }

  String? _getCoverImageUrl(Map<String, dynamic> offer) {
    if (offer["images"] != null && (offer["images"] as List).isNotEmpty) {
      var imagesList = offer["images"] as List;
      var coverImage = imagesList.firstWhere(
        (img) => img["is_cover"] == true,
        orElse: () =>
            imagesList.first, // Se non c'è copertina, prende la prima immagine
      );
      String imageUrl = coverImage["url"];

      // 🔹 Stampiamo il valore per vedere il formato
      print("🔍 DEBUG: URL Grezzo -> $imageUrl");
      print("🔍 DEBUG: Tipo di URL -> ${imageUrl.runtimeType}");

      // 🔹 Se ha doppi apici, li rimuoviamo
      if (imageUrl.startsWith('"') && imageUrl.endsWith('"')) {
        imageUrl = imageUrl.substring(1, imageUrl.length - 1);
        print("✅ Corretto URL: $imageUrl");
      }
      // 🔹 Se l'URL è in formato `gs://`, lo convertiamo in un URL HTTP
      if (imageUrl.startsWith("gs://")) {
        imageUrl = imageUrl.replaceFirst(
            "gs://", "https://firebasestorage.googleapis.com/v0/b/");
        imageUrl = imageUrl.replaceFirst("/o/", "/o?alt=media&token=");
      }
      print("✅ Copertina trovata (URL Convertito): $imageUrl");
      return imageUrl;
    }
    print("❌ Nessuna immagine trovata per l'offerta ${offer["offer_id"]}");
    return null;
  }

  /// ✅ Mostra la finestra per i filtri
  Future<void> _showFilterDialog() async {
    print("🔄 Entrato in _showFilterDialog()"); // 🔹 DEBUG

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
                    print(
                        "✅ FILTRI APPLICATI - STO PER CHIUDERE IL DIALOGO"); // 🔹 DEBUG

                    setState(() {
                      selectedCategories = tempSelectedCategories;
                      minDiscount = tempMinDiscount;
                      maxDiscount = tempMaxDiscount;
                      startDate = tempStartDate;
                      endDate = tempEndDate;
                      isFiltered = true;
                    });

                    Navigator.of(context).pop();
                    print(
                        "✅ DIALOGO CHIUSO - ORA CHIAMO _getVendorOffers()"); // 🔹 DEBUG

                    _getVendorOffers();
                  },
                ),
              ],
            );
          },
        );
      },
    );
    print("✅ USCITO DA _showFilterDialog()"); // 🔹 DEBUG
  }

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
              print(
                  "🔹 Bottone filtro premuto - Chiamo _showFilterDialog()"); // 🔹 DEBUG
              await _showFilterDialog();
              _getVendorOffers(); // 🔹 Aggiorniamo le offerte dopo il filtro
            },
          ),
        ],
      ),
      body: vendorOffers.isEmpty
          ? Center(child: Text("Nessuna offerta disponibile"))
          : ListView.builder(
              itemCount: vendorOffers.length,
              itemBuilder: (context, index) {
                var offer = vendorOffers[index];
                String? coverImageUrl = _getCoverImageUrl(offer);
                print(
                    "🔍 UI - Offerta ${offer["id"]} - Immagine di copertina: $coverImageUrl");
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OfferDetailsPage(
                          offerId: offer["id"],
                        ),
                      ),
                    ).then((_) =>
                        _getVendorOffers()); // ✅ Aggiorna la lista appena si torna indietro
                  },
                  child: Card(
                    elevation: 4,
                    margin: EdgeInsets.all(8),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // **Mostra SOLO l'immagine di copertina**
                          coverImageUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: CachedNetworkImage(
                                    imageUrl: coverImageUrl,
                                    width: 150,
                                    height: 150,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Center(
                                        child: CircularProgressIndicator()),
                                    errorWidget: (context, url, error) {
                                      print(
                                          "❌ Errore nel caricamento dell'immagine: $error");
                                      return Container(
                                        width: 150,
                                        height: 150,
                                        color: Colors.grey[300],
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.image_not_supported,
                                                size: 50, color: Colors.red),
                                            SizedBox(height: 8),
                                            Text("Errore nel caricamento",
                                                style: TextStyle(
                                                    color: Colors.red)),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                )
                              : Container(
                                  width: 150,
                                  height: 150,
                                  color: Colors.grey[300],
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.image_not_supported,
                                          size: 50, color: Colors.grey),
                                      SizedBox(height: 8),
                                      Text("Nessuna immagine disponibile"),
                                    ],
                                  ),
                                ),
                          SizedBox(width: 10), // 🔹 Spazio tra immagine e testo
                          // 🔹 Testo a destra
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  offer['title'] ?? "Senza titolo",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 5),
                                Text(
                                  "${offer['discount'] ?? 0}% di sconto",
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.green),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  "Categoria: ${offer['category'] ?? "N/A"}",
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.grey[700]),
                                ),
                                SizedBox(height: 5),
                                Text(
                                    "Inizio: ${_convertTimestamp(offer['startDate'])}"),
                                Text(
                                    "Fine: ${_convertTimestamp(offer['endDate'])}"),
                              ],
                            ),
                          ),

                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              await ApiService.deleteOffer(offer["id"]);
                              _getVendorOffers();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateOfferSheet,
        child: Icon(Icons.add),
      ),
    );
  }
}

class CreateOfferSheet extends StatefulWidget {
  final String vendorId;

  const CreateOfferSheet({Key? key, required this.vendorId}) : super(key: key);

  @override
  _CreateOfferSheetState createState() => _CreateOfferSheetState();
}

class _CreateOfferSheetState extends State<CreateOfferSheet> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController discountController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  List<XFile> selectedImages = [];
  XFile? coverImage;
  List<Uint8List?> imageBytes = []; // Per Flutter Web
  DateTime? startDate;
  DateTime? endDate;

  final List<String> categories = [
    "Abbigliamento",
    "Elettronica",
    "Cibo",
    "Gioielli",
    "Sport"
  ];
  late String selectedCategory;

  @override
  void initState() {
    super.initState();
    selectedCategory = categories.first;
  }

  Future<void> _pickImages() async {
    final List<XFile>? pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles != null && pickedFiles.isNotEmpty) {
      setState(() {
        selectedImages = pickedFiles;
        coverImage ??= selectedImages.first;
      });

      if (kIsWeb) {
        // Se siamo su Web, convertiamo le immagini in byte
        List<Uint8List?> byteList = await Future.wait(
          selectedImages.map((file) => file.readAsBytes()),
        );
        setState(() {
          imageBytes = byteList;
        });
      }
    }
  }

  Future<void> _uploadImages(String offerId) async {
    List<Map<String, dynamic>> uploadedImages = [];

    for (var image in selectedImages) {
      Map<String, dynamic>? uploadedImage =
          await ApiService.uploadOfferImage(offerId, image);
      if (uploadedImage != null) {
        // **Se questa immagine è la copertina, imposta `is_cover: true`**
        uploadedImage["is_cover"] = coverImage == image;
        uploadedImages.add(uploadedImage);
      }
    }

    await ApiService.updateOffer(offerId, {"images": uploadedImages});
  }

  Future<void> _createOffer() async {
    String title = titleController.text.trim();
    String description = descriptionController.text.trim();
    double discount = double.tryParse(discountController.text) ?? 0.0;

    if (title.isEmpty || description.isEmpty || selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text("Compila tutti i campi e seleziona almeno un'immagine")),
      );
      return;
    }

    // **1️⃣ Crea offerta SENZA immagini**
    Map<String, dynamic>? newOffer = await ApiService.createOffer(
        title, //title
        description, //description
        selectedCategory, //category
        discount, //discount
        "", //imageUrl
        startDate != null ? startDate!.toIso8601String() : "", //startDate
        endDate != null ? endDate!.toIso8601String() : "", //endDate
        widget.vendorId //vendorId
        );

    if (newOffer != null && newOffer["offer_id"] != null) {
      // **2️⃣ Carica immagini**
      await _uploadImages(newOffer["offer_id"]);

      // **3️⃣ Imposta la copertina**
      if (coverImage != null) {
        await ApiService.setCoverImage(newOffer["offer_id"], coverImage!.path);
      }

      Navigator.of(context)
          .pop(true); // Chiude la Bottom Sheet e segnala il successo
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Crea Nuova Offerta",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _pickImages,
                child: Text("Seleziona Immagini"),
              ),
              SizedBox(height: 10),
              if (selectedImages.isNotEmpty) ...[
                Text("Seleziona immagine di copertina"),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: selectedImages.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            coverImage = selectedImages[index];
                          });
                        },
                        child: Stack(
                          children: [
                            kIsWeb
                                ? Image.memory(imageBytes[index]!,
                                    width: 100, height: 100, fit: BoxFit.cover)
                                : Image.file(File(selectedImages[index].path),
                                    width: 100, height: 100, fit: BoxFit.cover),
                            if (coverImage == selectedImages[index])
                              Positioned(
                                top: 5,
                                right: 5,
                                child: Icon(Icons.star, color: Colors.yellow),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
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
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _createOffer,
                child: Text("Crea Offerta"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

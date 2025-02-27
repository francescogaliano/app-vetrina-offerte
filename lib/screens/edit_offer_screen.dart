import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/api_service.dart';

class EditOfferScreen extends StatefulWidget {
  final String offerId;
  final String title;
  final String category;
  final String description;
  final double discount;
  final List<dynamic> images;
  final dynamic startDate;
  final dynamic endDate;

  const EditOfferScreen({
    Key? key,
    required this.offerId,
    required this.title,
    required this.category,
    required this.description,
    required this.discount,
    required this.images,
    required this.startDate,
    required this.endDate,
  }) : super(key: key);

  @override
  _EditOfferScreenState createState() => _EditOfferScreenState();
}

class _EditOfferScreenState extends State<EditOfferScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _categoryController;
  late TextEditingController _descriptionController;
  late TextEditingController _discountController;
  late TextEditingController _startDateController;
  late TextEditingController _endDateController;
  List<dynamic> images = [];
  String? selectedCoverImage;
  final ImagePicker _picker = ImagePicker();
  List<XFile> newImages = [];
  List<Uint8List> webImages = [];
  bool isCoverUpdated = false; // 🔹 Variabile per gestire il cambio della cover

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.title);
    _categoryController = TextEditingController(text: widget.category);
    _descriptionController = TextEditingController(text: widget.description);
    _discountController =
        TextEditingController(text: widget.discount.toString());
    _startDateController =
        TextEditingController(text: _convertTimestamp(widget.startDate));
    _endDateController =
        TextEditingController(text: _convertTimestamp(widget.endDate));

    images = List.from(widget.images);
    selectedCoverImage = images.firstWhere(
      (img) => img['is_cover'] == true,
      orElse: () => images.isNotEmpty ? images.first : null,
    )?["url"];
  }

  /// 🔹 Converte `Timestamp` in `String` (YYYY-MM-DD)
  String _convertTimestamp(dynamic date) {
    if (date is Timestamp) {
      return date.toDate().toLocal().toIso8601String().split('T')[0];
    } else if (date is String) {
      return date.split('T')[0];
    }
    return "";
  }

  Future<void> _deleteImage(String imageUrl) async {
    try {
      print("🗑️ Eliminazione immagine: $imageUrl");

      // 🔹 1. Rimuovere l'immagine da Firebase Storage
      await ApiService.deleteOfferImage(widget.offerId, imageUrl);
      print("✅ Immagine eliminata da Storage!");

      // 🔹 2. Rimuovere il riferimento all'immagine dalla lista `images`
      setState(() {
        images.removeWhere((img) => img["url"] == imageUrl);

        // Se l'immagine eliminata era la cover, resettiamo la cover su un'altra immagine
        if (selectedCoverImage == imageUrl) {
          selectedCoverImage = images.isNotEmpty ? images.first["url"] : null;
          isCoverUpdated = true; // ✅ Indichiamo che la cover è cambiata
        }
      });

      // 🔹 3. Aggiornare Firestore con la nuova lista di immagini
      await ApiService.updateOffer(widget.offerId, {"images": images});
      print("✅ Riferimento eliminato da Firestore!");
    } catch (e) {
      print("❌ Errore eliminazione immagine: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Errore durante l'eliminazione dell'immagine")),
      );
    }
  }

  Future<void> _pickNewImages() async {
    final List<XFile>? pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles != null && pickedFiles.isNotEmpty) {
      setState(() {
        if (kIsWeb) {
          // 🔹 Solo per Web: Converte XFile in Uint8List
          Future.wait(pickedFiles.map((file) => file.readAsBytes()))
              .then((bytesList) {
            setState(() {
              webImages.addAll(bytesList);
            });
          });
        } else {
          // 🔹 Solo per Mobile: Aggiunge a newImages
          newImages.addAll(pickedFiles);
        }
      });
    }
  }

/*   Future<void> _setCoverImage(String? imageUrl) async {
    await ApiService.setCoverImage(widget.offerId, imageUrl);
    setState(() {
      isCoverUpdated = true; // 🔹 Segniamo che la cover è stata cambiata
      selectedCoverImage = imageUrl;
      for (var img in images) {
        img["is_cover"] = img["url"] == imageUrl;
      }
    });
  } */

  void _updateOffer() async {
    if (_formKey.currentState!.validate()) {
      Map<String, dynamic> updatedData = {};

      if (_titleController.text != widget.title)
        updatedData["title"] = _titleController.text;
      if (_categoryController.text != widget.category)
        updatedData["category"] = _categoryController.text;
      if (_descriptionController.text != widget.description)
        updatedData["description"] = _descriptionController.text;
      if (_discountController.text != widget.discount.toString()) {
        updatedData["discount"] = double.parse(_discountController.text);
      }
      if (_startDateController.text != widget.startDate)
        updatedData["startDate"] = _startDateController.text;
      if (_endDateController.text != widget.endDate)
        updatedData["endDate"] = _endDateController.text;

      List<Map<String, dynamic>> uploadedImages = [];

      // 🔹 Upload nuove immagini SOLO al salvataggio
      for (var image in newImages) {
        print("📸 Caricamento immagine Mobile: ${image.path}");
        Map<String, dynamic>? uploadedImage =
            await ApiService.uploadOfferImage(widget.offerId, image);
        if (uploadedImage != null) {
          uploadedImages.add(uploadedImage);
        }
      }

      for (var image in webImages) {
        print("🌍 Caricamento immagine Web...");
        XFile webFile = XFile.fromData(image, name: "web_temp.jpg");
        Map<String, dynamic>? uploadedImage =
            await ApiService.uploadOfferImage(widget.offerId, webFile);
        if (uploadedImage != null) {
          uploadedImages.add(uploadedImage);
        }
      }

      // 🔹 Aggiungiamo solo le immagini effettivamente caricate
      if (uploadedImages.isNotEmpty) {
        print("✅ Immagini caricate con successo: ${uploadedImages.length}");
        images.addAll(uploadedImages);
      }

      // 🔹 Se la cover selezionata è una NUOVA immagine, aggiorniamo il riferimento
      if (isCoverUpdated &&
          selectedCoverImage?.startsWith("new_web_image_") == true) {
        print("⭐ Aggiornamento cover con nuova immagine caricata...");

        if (uploadedImages.isNotEmpty) {
          selectedCoverImage = uploadedImages.last["url"];
        } else {
          print(
              "❌ Errore: la cover è nuova ma non è stata caricata correttamente.");
        }
      }

      // 🔹 Impostiamo la cover solo ora che abbiamo il vero URL
      for (var img in images) {
        img["is_cover"] = img["url"] == selectedCoverImage;
      }

      print(
          "📸 ARRAY IMMAGINI FINALE: ${images.map((img) => img.toString()).toList()}");

      // 🔹 Aggiorniamo Firestore con i dati definitivi
      updatedData["images"] = images;

      if (updatedData.isNotEmpty) {
        await ApiService.updateOffer(widget.offerId, updatedData);
        print("✅ Offerta aggiornata con successo!");
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Nessuna modifica rilevata.")));
      }

      newImages.clear();
      webImages.clear();
    }
  }

  Future<void> _setCoverImage(dynamic image) async {
    setState(() {
      isCoverUpdated = true;

      // 🔹 Se è un'URL esistente (vecchie immagini Firestore)
      if (image is String) {
        selectedCoverImage = image;
      }
      // 🔹 Se è una nuova immagine su Web (Uint8List)
      else if (image is Uint8List) {
        int index = webImages.indexOf(image);
        selectedCoverImage =
            "new_web_image_$index"; // ✅ ID univoco per nuove immagini Web
      }
      // 🔹 Se è una nuova immagine su Mobile (XFile)
      else if (image is XFile) {
        selectedCoverImage = image.path;
      }

      // 🔹 Assicuriamoci che solo la nuova immagine selezionata sia `is_cover`
      for (var img in images) {
        img["is_cover"] = img["url"] == selectedCoverImage;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Modifica Offerta")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Modifica Immagini",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),

              // 🔹 Carosello orizzontale per immagini esistenti
              // 🔹 Mostra tutte le immagini (esistenti e nuove)
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount:
                      images.length + newImages.length + webImages.length,
                  itemBuilder: (context, index) {
                    int totalCount =
                        images.length + newImages.length + webImages.length;
                    //print("📸 Numero totale immagini da mostrare: $totalCount");
                    //print("📂 newImages.length: ${newImages.length}");
                    //print("🌐 webImages.length: ${webImages.length}");
                    if (index < images.length) {
                      print("🔄 Rendering immagine index: $index");
                      var image = images[index];
                      return Stack(
                        children: [
                          CachedNetworkImage(
                            imageUrl: image["url"],
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                          ),
                          Positioned(
                            top: 5,
                            right: 5,
                            child: IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteImage(image["url"]),
                            ),
                          ),
                          Positioned(
                            bottom: 5,
                            right: 5,
                            child: IconButton(
                              icon: Icon(
                                selectedCoverImage == image["url"]
                                    ? Icons.star
                                    : Icons.star_border,
                                color: selectedCoverImage == image["url"]
                                    ? Colors.yellow
                                    : Colors.white,
                              ),
                              onPressed: () => _setCoverImage(image["url"]),
                            ),
                          ),
                        ],
                      );
                    } else {
                      bool isWebImage =
                          index - images.length < webImages.length;
                      bool isMobileImage = !isWebImage &&
                          (index - images.length - webImages.length) <
                              newImages.length;

                      if (!isWebImage && !isMobileImage) {
                        print("❌ Index fuori intervallo, non renderizzo nulla");
                        return SizedBox(); // 🔥 Non aggiungere nulla se l'indice è errato
                      }
                      var newImage;
                      if (isWebImage) {
                        newImage = webImages[index - images.length];
                      } else if (isMobileImage) {
                        newImage =
                            newImages[index - images.length - webImages.length];
                      } else {
                        return SizedBox(); // 🔥 Se non è né Web né Mobile, NON aggiungere nulla (risolve il box grigio)
                      }

                      // 🔹 Identificatore della nuova immagine
                      String newImageIdentifier = "";
                      if (isWebImage) {
                        newImageIdentifier =
                            "new_web_image_${webImages.indexOf(newImage as Uint8List)}";
                      } else if (newImage is XFile) {
                        newImageIdentifier = newImage.path;
                      }
                      return Stack(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey)),
                            child: kIsWeb
                                ? (newImage is Uint8List
                                    ? Image.memory(newImage,
                                        width: 120,
                                        height: 120,
                                        fit: BoxFit.cover)
                                    : Container(color: Colors.grey))
                                : (newImage is XFile
                                    ? Image.file(File(newImage.path),
                                        width: 120,
                                        height: 120,
                                        fit: BoxFit.cover)
                                    : Container(color: Colors.grey)),
                          ),
                          Positioned(
                            bottom: 5,
                            right: 5,
                            child: IconButton(
                              icon: Icon(
                                selectedCoverImage == newImageIdentifier
                                    ? Icons.star
                                    : Icons.star_border,
                                color: selectedCoverImage == newImageIdentifier
                                    ? Colors.yellow
                                    : Colors.white,
                              ),
                              onPressed: () => _setCoverImage(newImage),
                            ),
                          ),
                        ],
                      );
                    }
                  },
                ),
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: _pickNewImages,
                    child: Text("Aggiungi Immagini"),
                  ),
                ],
              ),
              SizedBox(height: 20),
              // 🔹 Campi di Modifica
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: "Titolo"),
              ),
              TextFormField(
                controller: _categoryController,
                decoration: InputDecoration(labelText: "Categoria"),
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: "Descrizione"),
              ),
              TextFormField(
                controller: _discountController,
                decoration: InputDecoration(labelText: "Sconto (%)"),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _startDateController,
                decoration:
                    InputDecoration(labelText: "Data inizio (YYYY-MM-DD)"),
              ),
              TextFormField(
                controller: _endDateController,
                decoration:
                    InputDecoration(labelText: "Data fine (YYYY-MM-DD)"),
              ),

              SizedBox(height: 20),

              // 🔹 Pulsanti disposti meglio

              SizedBox(height: 20),

              ElevatedButton(
                onPressed: _updateOffer,
                style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50)),
                child: Text("Salva Modifiche"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

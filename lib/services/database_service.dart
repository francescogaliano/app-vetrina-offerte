import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class Offer {
  String id;
  String title;
  String description;
  String category;
  int discount;
  String imageUrl;
  String vendor;
  DateTime? startDate; // Aggiunto campo startDate
  DateTime? endDate; // Aggiunto campo endDate

  Offer({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.discount,
    required this.imageUrl,
    required this.vendor,
    this.startDate, // Aggiunto al costruttore
    this.endDate, // Aggiunto al costruttore
  });

  Map<String, dynamic> toJson() => {
        "id": id,
        "title": title,
        "description": description,
        "category": category,
        "discount": discount,
        "imageUrl": imageUrl,
        "vendor": vendor,
        "startDate":
            startDate?.toIso8601String(), // Convertiamo la data in stringa
        "endDate": endDate?.toIso8601String(), // Convertiamo la data in stringa
      };

  factory Offer.fromJson(Map<String, dynamic> json) {
    return Offer(
      id: json["id"],
      title: json["title"],
      description: json["description"],
      category: json["category"],
      discount: json["discount"],
      imageUrl: json["imageUrl"],
      vendor: json["vendor"],
      startDate:
          json["startDate"] != null ? DateTime.parse(json["startDate"]) : null,
      endDate: json["endDate"] != null ? DateTime.parse(json["endDate"]) : null,
    );
  }
}

class DatabaseService {
  static List<Offer> _offers = [];

  // Carica le offerte da un file JSON locale
  static Future<void> loadOffers() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/offers.json');

      if (file.existsSync()) {
        String data = await file.readAsString();
        List<dynamic> jsonList = jsonDecode(data);
        _offers = jsonList.map((offer) => Offer.fromJson(offer)).toList();
      }
    } catch (e) {
      print("Errore nel caricamento delle offerte: $e");
    }
  }

  // Salva le offerte nel file JSON
  static Future<void> saveOffers() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/offers.json');
      String jsonString =
          jsonEncode(_offers.map((offer) => offer.toJson()).toList());
      await file.writeAsString(jsonString);
    } catch (e) {
      print("Errore nel salvataggio delle offerte: $e");
    }
  }

  // Aggiunge una nuova offerta
  static Future<void> addOffer(Offer offer) async {
    _offers.add(offer);
    await saveOffers();
  }

  // Modifica un'offerta esistente
  static Future<void> updateOffer(String id, Offer updatedOffer) async {
    int index = _offers.indexWhere((offer) => offer.id == id);
    if (index != -1) {
      _offers[index] = updatedOffer;
      await saveOffers();
    }
  }

  // Elimina un'offerta
  static Future<void> deleteOffer(String id) async {
    _offers.removeWhere((offer) => offer.id == id);
    await saveOffers();
  }

  // Recupera tutte le offerte
  static List<Offer> getOffers() {
    return _offers;
  }

  // Filtra le offerte per categoria
  static List<Offer> getOffersByCategory(String category) {
    return _offers.where((offer) => offer.category == category).toList();
  }

  // Filtra le offerte per sconto
  static List<Offer> getOffersByDiscount(int min, int max) {
    return _offers
        .where((offer) => offer.discount >= min && offer.discount <= max)
        .toList();
  }
}

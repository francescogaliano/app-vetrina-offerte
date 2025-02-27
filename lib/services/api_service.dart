import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

class ApiService {
  static const String baseUrl = "http://localhost:8000";
  //"https://fastapi-app-915326060787.europe-west1.run.app";

  /// 🔹 Ottiene il token JWT di Firebase
  static Future<String?> _getToken() async {
    return await FirebaseAuth.instance.currentUser?.getIdToken();
  }

  /// 🔹 API per ottenere i dettagli di un'offerta
  static Future<Map<String, dynamic>?> getOffer(String offerId) async {
    String? token = await _getToken();

    if (token == null) {
      print("❌ Utente non autenticato");
      return null;
    }

    final response = await http.get(
      Uri.parse("$baseUrl/offers/get-offer/$offerId"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print("❌ Errore nel recupero dell'offerta: ${response.body}");
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>?> getOffers({
    String? vendorId,
    List<String>? categories,
    double minDiscount = 0,
    double maxDiscount = 100,
    String? startDate,
    String? endDate,
  }) async {
    String? token = await _getToken();
    if (token == null) {
      print("❌ Utente non autenticato");
      return null;
    }

    final queryParams = {
      if (vendorId != null) "vendorId": vendorId,
      if (categories != null && categories.isNotEmpty)
        "categories": categories.join(","),
      "min_discount": minDiscount.toString(),
      "max_discount": maxDiscount.toString(),
      if (startDate != null) "startDate": startDate,
      if (endDate != null) "endDate": endDate,
    };

    final uri = Uri.parse("$baseUrl/offers/get-offers/")
        .replace(queryParameters: queryParams);

    print("🔹 GET Offers URL: $uri"); // ✅ STAMPIAMO L'URL PER DEBUG

    final response = await http.get(
      uri,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    print(
        "🔹 Risposta da FastAPI: ${response.body}"); // ✅ STAMPIAMO LA RISPOSTA

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(
          jsonDecode(response.body)["offers"]);
    } else {
      print("❌ Errore nel recupero delle offerte: ${response.body}");
      return null;
    }
  }

  /// 🔹 API per creare un'offerta (SOLO per `vendor` e `admin`)
  static Future<Map<String, dynamic>?> createOffer(
      String title,
      String description,
      String category,
      double discount,
      String imageUrl,
      String startDate,
      String endDate,
      String vendorId) async {
    String? token = await _getToken();

    if (token == null) {
      print("❌ Utente non autenticato");
      return null;
    }

    final response = await http.post(
      Uri.parse("$baseUrl/offers/create-offer/"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "title": title,
        "category": category,
        "description": description,
        "discount": discount,
        "imageUrl": imageUrl,
        "images": [], // 🔹 Inizialmente nessuna immagine
        "vendorId": vendorId,
        "startDate": startDate,
        "endDate": endDate,
      }),
    );

    if (response.statusCode == 200) {
      print("✅ Offerta creata con successo!");
      return jsonDecode(
          response.body); // 🔹 Ora restituisce i dettagli dell'offerta
    } else {
      print("❌ Errore nella creazione dell'offerta: ${response.body}");
      return null;
    }
  }

/*   /// 🔹 API per ottenere tutte le offerte
  static Future<List<dynamic>> getOffers() async {
    final response = await http.get(Uri.parse("$baseUrl/get-offers/"));

    if (response.statusCode == 200) {
      return jsonDecode(response.body)["offers"];
    } else {
      print("❌ Errore nel recupero delle offerte!");
      return [];
    }
  } */

  /// 🔹 API per aggiornare un'offerta
  static Future<void> updateOffer(
      String offerId, Map<String, dynamic> updateData) async {
    String? token = await _getToken();
    if (token == null) {
      print("❌ Utente non autenticato");
      return;
    }

    final response = await http.put(
      Uri.parse("$baseUrl/offers/update-offer/$offerId"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode(updateData),
    );

    if (response.statusCode == 200) {
      print("✅ Offerta aggiornata con successo!");
    } else {
      print("❌ Errore nell'aggiornamento dell'offerta: ${response.body}");
    }
  }

  static Future<bool> deleteOffer(String offerId) async {
    String? token = await _getToken();
    if (token == null) {
      print("❌ Utente non autenticato");
      return false;
    }

    final response = await http.delete(
      Uri.parse("$baseUrl/delete-offer/$offerId"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    if (response.statusCode == 200) {
      print("✅ Offerta eliminata con successo.");
      return true;
    } else {
      print("❌ Errore nella cancellazione dell'offerta: ${response.body}");
      return false;
    }
  }

  static Future<Map<String, dynamic>?> uploadOfferImage(
      String offerId, XFile imageFile) async {
    print("🔹 Upload immagine per offerta $offerId");
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('offers/$offerId/${imageFile.name}');

      UploadTask uploadTask;

      if (kIsWeb) {
        // **UPLOAD PER FLUTTER WEB**
        Uint8List imageBytes = await imageFile.readAsBytes();
        SettableMetadata metadata =
            SettableMetadata(contentType: "image/jpeg"); // ✅ Forza il tipo MIME
        uploadTask = ref.putData(imageBytes, metadata);
      } else {
        // **UPLOAD PER ANDROID & iOS**
        File file = File(imageFile.path);
        String fileExtension = imageFile.path.split('.').last.toLowerCase();

        // 🔹 Determiniamo il contentType in base all'estensione
        String contentType =
            (fileExtension == "png") ? "image/png" : "image/jpeg";
        SettableMetadata metadata = SettableMetadata(contentType: contentType);

        uploadTask = ref.putFile(file, metadata);
      }
      // 🔹 Aspettiamo il completamento dell'upload
      await uploadTask.whenComplete(() => print("✅ Upload completato"));

      final url = await ref.getDownloadURL(); // Ottieni URL dell'immagine
      print("✅ Immagine caricata: $url");
      return {
        "url": url,
        "is_cover": false // Inizialmente nessuna immagine è copertina
      };
    } catch (e) {
      print("❌ Errore upload immagine: $e");
      return null;
    }
  }

  static Future<void> setCoverImage(String offerId, String imageUrl) async {
    await http.put(
      Uri.parse("$baseUrl/offers/$offerId/set-cover"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"imageUrl": imageUrl}),
    );
  }

  /// **🔹 Elimina un'immagine dall'offerta**
  static Future<void> deleteOfferImage(String offerId, String imageUrl) async {
    await http.delete(
      Uri.parse("$baseUrl/offers/$offerId/delete-image"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"imageUrl": imageUrl}),
    );
  }
}

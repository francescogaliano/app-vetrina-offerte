import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';

class ApiService {
  static const String baseUrl = "http://127.0.0.1:8000";

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
  static Future<void> createOffer(
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
      return;
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
        "vendorId": vendorId,
        "startDate": startDate,
        "endDate": endDate,
      }),
    );

    if (response.statusCode == 200) {
      print("✅ Offerta creata con successo!");
    } else {
      print("❌ Errore nella creazione dell'offerta: ${response.body}");
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
}

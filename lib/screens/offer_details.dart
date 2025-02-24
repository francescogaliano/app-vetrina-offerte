import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_offer_screen.dart'; // 🔹 Importiamo la schermata di modifica
import '../services/api_service.dart';

class OfferDetailsPage extends StatefulWidget {
  final String offerId;

  const OfferDetailsPage({
    required this.offerId,
    Key? key,
  }) : super(key: key);

  @override
  _OfferDetailsPageState createState() => _OfferDetailsPageState();
}

class _OfferDetailsPageState extends State<OfferDetailsPage> {
  String? currentUserId;
  bool isVendor = false;
  Map<String, dynamic>? offerData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  /// 🔹 Inizializza `currentUserId` e recupera i dettagli dell'offerta
  Future<void> _initializeData() async {
    await _checkUserRole(); // 🔹 Recupera prima l'ID dell'utente loggato
    await _fetchOfferDetails(); // 🔹 Poi recupera i dettagli dell'offerta e verifica `isVendor`
  }

  /// 🔹 Recupera l'ID dell'utente loggato e aggiorna `isVendor`
  Future<void> _checkUserRole() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      currentUserId = user.uid;
    }
  }

  /// 🔹 Recupera i dettagli dell'offerta e aggiorna `isVendor`
  Future<void> _fetchOfferDetails() async {
    try {
      Map<String, dynamic>? offer = await ApiService.getOffer(widget.offerId);

      if (offer != null) {
        setState(() {
          offerData = offer;
          _updateVendorStatus(); // 🔹 Controlla se l'utente è il venditore
          isLoading = false;
        });
      }
    } catch (e) {
      print("❌ Errore nel recupero dell'offerta: $e");
    }
  }

  void _updateVendorStatus() {
    if (currentUserId != null &&
        offerData != null &&
        offerData?['vendorId'] is String) {
      setState(() {
        isVendor = currentUserId == offerData?['vendorId'];
      });
    }
  }

  /// 🔹 Modifica l'offerta
  void _editOffer() async {
    bool? updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditOfferScreen(
          offerId: widget.offerId,
          title: offerData?['title'] ?? '',
          category: offerData?['category'] ?? '',
          description: offerData?['description'] ?? '',
          discount: (offerData?['discount'] ?? 0).toDouble(),
          imageUrl: offerData?['imageUrl'] ?? '',
          startDate: offerData?['startDate'] ?? '',
          endDate: offerData?['endDate'] ?? '',
        ),
      ),
    );

    if (updated == true) {
      _fetchOfferDetails(); // 🔹 Ricarica i dati aggiornati dopo la modifica
    }
  }

  /// 🔹 Elimina l'offerta
  void _deleteOffer() async {
    try {
      await FirebaseFirestore.instance
          .collection('offers')
          .doc(widget.offerId)
          .delete();
      print("✅ Offerta eliminata!");
      Navigator.pop(context); // 🔹 Torna alla pagina precedente
    } catch (e) {
      print("❌ Errore nell'eliminazione: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (offerData == null) {
      return Scaffold(
        appBar: AppBar(title: Text("Dettagli Offerta")),
        body: Center(
            child: CircularProgressIndicator()), // 🔹 Mostra il caricamento
      );
    }
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(offerData?['title'],
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Immagine dell'offerta
            Hero(
              tag: widget.offerId,
              child: Image.network(
                offerData?['imageUrl'],
                width: double.infinity,
                height: 250,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Image.asset(
                    'assets/images/placeholder.png',
                    height: 250,
                    fit: BoxFit.cover),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🔹 Titolo
                  Text(
                    offerData?['title'],
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),

                  // 🔹 Prezzo
                  Text(
                    "€${offerData?['discount'].toStringAsFixed(2)}",
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.green),
                  ),
                  SizedBox(height: 15),

                  // 🔹 Categoria
                  Text(
                    "Categoria: ${offerData?['category'] ?? "N/A"}",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),

                  // 🔹 Date
                  Text(
                    "Inizio: ${offerData?['startDate'] is Timestamp ? (offerData?['startDate'] as Timestamp).toDate().toLocal().toIso8601String().split('T')[0] : (offerData?['startDate'] ?? "Nessuna data")}",
                    style: TextStyle(fontSize: 16),
                  ),
                  Text(
                    "Fine: ${offerData?['endDate'] is Timestamp ? (offerData?['endDate'] as Timestamp).toDate().toLocal().toIso8601String().split('T')[0] : (offerData?['endDate'] ?? "Nessuna data")}",
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 15),

                  // 🔹 Divider
                  Divider(thickness: 1, color: Colors.grey[400]),
                  SizedBox(height: 15),

                  // 🔹 Descrizione
                  Text(
                    offerData?['description'],
                    style: TextStyle(fontSize: 16, height: 1.5),
                  ),

                  // 🔹 SOLO IL VENDITORE VEDE QUESTI PULSANTI
                  if (isVendor) ...[
                    SizedBox(height: 30),
                    Divider(thickness: 1, color: Colors.grey[400]),
                    SizedBox(height: 15),

                    // 🔹 Pulsanti per il venditore
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _editOffer,
                          icon: Icon(Icons.edit, color: Colors.white),
                          label: Text("Modifica"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            textStyle: TextStyle(fontSize: 16),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _deleteOffer,
                          icon: Icon(Icons.delete, color: Colors.white),
                          label: Text("Elimina"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            textStyle: TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

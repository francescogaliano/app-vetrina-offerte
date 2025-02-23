import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OfferDetailsPage extends StatefulWidget {
  final String offerId;
  final String title;
  final String description;
  final String imageUrl;
  final double price;
  final String vendorId; // ID del venditore

  const OfferDetailsPage({
    required this.offerId,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.price,
    required this.vendorId,
    Key? key,
  }) : super(key: key);

  @override
  _OfferDetailsPageState createState() => _OfferDetailsPageState();
}

class _OfferDetailsPageState extends State<OfferDetailsPage> {
  String? currentUserId;
  bool isVendor = false; // 🔹 Verifica se l'utente è il venditore

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  /// 🔹 Controlla se l'utente è il venditore
  void _checkUserRole() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        currentUserId = user.uid;
        isVendor = (currentUserId == widget.vendorId);
      });
    }
  }

  /// 🔹 Modifica l'offerta (DA IMPLEMENTARE)
  void _editOffer() {
    print("📝 Modifica offerta: ${widget.offerId}");
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
    return Scaffold(
      backgroundColor: Colors.grey[100], // 🔹 Sfondo leggero
      appBar: AppBar(
        title:
            Text(widget.title, style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 Immagine dell'offerta
            Hero(
              tag: widget.offerId, // Effetto di transizione fluida
              child: Image.network(
                widget.imageUrl,
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
                  // 🔹 Titolo dell'offerta
                  Text(
                    widget.title,
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),

                  // 🔹 Prezzo dell'offerta
                  Text(
                    "€${widget.price.toStringAsFixed(2)}",
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.green),
                  ),
                  SizedBox(height: 15),

                  // 🔹 Divider
                  Divider(thickness: 1, color: Colors.grey[400]),
                  SizedBox(height: 15),

                  // 🔹 Descrizione
                  Text(
                    widget.description,
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

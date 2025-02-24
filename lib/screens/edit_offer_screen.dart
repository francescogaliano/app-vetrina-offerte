import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/api_service.dart';

class EditOfferScreen extends StatefulWidget {
  final String offerId;
  final String title;
  final String category;
  final String description;
  final double discount;
  final String imageUrl;
  final dynamic startDate;
  final dynamic endDate;

  const EditOfferScreen({
    Key? key,
    required this.offerId,
    required this.title,
    required this.category,
    required this.description,
    required this.discount,
    required this.imageUrl,
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
  late TextEditingController _imageUrlController;
  late TextEditingController _startDateController;
  late TextEditingController _endDateController;

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController(text: widget.title);
    _categoryController = TextEditingController(text: widget.category);
    _descriptionController = TextEditingController(text: widget.description);
    _discountController =
        TextEditingController(text: widget.discount.toString());
    _imageUrlController = TextEditingController(text: widget.imageUrl);

    // 🔹 Converte i valori in Stringa se sono `Timestamp`
    _startDateController =
        TextEditingController(text: _convertTimestamp(widget.startDate));
    _endDateController =
        TextEditingController(text: _convertTimestamp(widget.endDate));
  }

  /// 🔹 Converte `Timestamp` in `String` (YYYY-MM-DD)
  String _convertTimestamp(dynamic date) {
    if (date is Timestamp) {
      return date
          .toDate()
          .toLocal()
          .toIso8601String()
          .split('T')[0]; // 🔹 Converti in YYYY-MM-DD
    } else if (date is String) {
      return date.split('T')[0]; // 🔹 Se è già una stringa, rimuove l'orario
    }
    return ""; // 🔹 Se è null, restituisci una stringa vuota
  }

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    _discountController.dispose();
    _imageUrlController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

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
      if (_imageUrlController.text != widget.imageUrl)
        updatedData["image_url"] = _imageUrlController.text;
      if (_startDateController.text != widget.startDate)
        updatedData["start_date"] = _startDateController.text;
      if (_endDateController.text != widget.endDate)
        updatedData["end_date"] = _endDateController.text;

      if (updatedData.isNotEmpty) {
        await ApiService.updateOffer(widget.offerId, updatedData);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Offerta aggiornata con successo!")));
        Navigator.pop(context,
            true); // 🔹 Torniamo alla pagina precedente e aggiorniamo i dati
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Nessuna modifica rilevata.")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Modifica Offerta")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(labelText: "Titolo"),
                  validator: (value) =>
                      value!.isEmpty ? "Inserisci un titolo" : null,
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
                  controller: _imageUrlController,
                  decoration: InputDecoration(labelText: "URL Immagine"),
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
                ElevatedButton(
                  onPressed: _updateOffer,
                  child: Text("Salva Modifiche"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

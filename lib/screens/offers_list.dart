import 'package:flutter/material.dart';
import '../services/database_service.dart';

class OffersPage extends StatefulWidget {
  final Function(String) startChat;
  final int minDiscount;
  final int maxDiscount;
  final String selectedCategory;
  final DateTime? startDate;
  final DateTime? endDate;

  OffersPage({
    required this.startChat,
    required this.minDiscount,
    required this.maxDiscount,
    required this.selectedCategory,
    required this.startDate,
    required this.endDate,
  });

  @override
  _OffersPageState createState() => _OffersPageState();
}

class _OffersPageState extends State<OffersPage> {
  List<Offer> filteredOffers = [];

  @override
  void initState() {
    super.initState();
    _loadOffers();
  }

  void _loadOffers() {
    List<Offer> allOffers = DatabaseService.getOffers();

    // Applichiamo i filtri
    setState(() {
      filteredOffers = allOffers.where((offer) {
        bool matchesCategory = widget.selectedCategory.isEmpty ||
            offer.category == widget.selectedCategory;
        bool matchesDiscount = offer.discount >= widget.minDiscount &&
            offer.discount <= widget.maxDiscount;
        bool matchesDate = true;

        if (widget.startDate != null && widget.endDate != null) {
          matchesDate = DateTime.now().isAfter(widget.startDate!) &&
              DateTime.now().isBefore(widget.endDate!);
        }

        return matchesCategory && matchesDiscount && matchesDate;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Offerte Disponibili")),
      body: filteredOffers.isEmpty
          ? Center(child: Text("Nessuna offerta trovata"))
          : ListView.builder(
              itemCount: filteredOffers.length,
              itemBuilder: (context, index) {
                Offer offer = filteredOffers[index];

                return Card(
                  margin: EdgeInsets.all(10),
                  elevation: 4,
                  child: ListTile(
                    contentPadding: EdgeInsets.all(10),
                    leading: Image.network(
                      offer.imageUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                    title: Text(offer.title,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("${offer.discount}% di sconto"),
                        Text("Categoria: ${offer.category}"),
                      ],
                    ),
                    trailing: ElevatedButton(
                      onPressed: () => widget.startChat(offer.vendor),
                      child: Text("Chat"),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

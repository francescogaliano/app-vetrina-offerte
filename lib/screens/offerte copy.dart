import 'package:flutter/material.dart';

class OffersPage extends StatefulWidget {
  final Function(String) startChat;
  final double minDiscount;
  final double maxDiscount;
  final String selectedCategory;
  final DateTime? startDate;
  final DateTime? endDate;

  const OffersPage({
    super.key,
    required this.startChat,
    required this.minDiscount,
    required this.maxDiscount,
    required this.selectedCategory,
    this.startDate,
    this.endDate,
  });

  @override
  _OffersPageState createState() => _OffersPageState();
}

class _OffersPageState extends State<OffersPage> {
  final List<Map<String, dynamic>> offerte = [
    {
      'titolo': 'Sconto 50% su scarpe',
      'descrizione': 'Approfitta della promo!',
      'negozio': 'Negozio XYZ',
      'distanza': '2 km',
      'tipologia': 'Abbigliamento',
      'sconto': 50,
      'dataInizio': DateTime(2024, 2, 1),
      'dataFine': DateTime(2024, 2, 15),
      'immagine':
          'https://as2.ftcdn.net/jpg/00/56/20/69/1000_F_56206948_O3WbLqqLrrK3MMedX6E1qGBQKbDMOjRd.jpg',
    },
    {
      'titolo': '2x1 su magliette',
      'descrizione': 'Compra una, la seconda è gratis!',
      'negozio': 'Negozio ABC',
      'distanza': '5 km',
      'tipologia': 'Abbigliamento',
      'sconto': 30,
      'dataInizio': DateTime(2024, 1, 15),
      'dataFine': DateTime(2024, 2, 10),
      'immagine':
          'https://bigone-outdoor.com/wp-content/uploads/2024/04/aprile_04.jpg',
    },
    {
      'titolo': 'Sconto del 30% su giacche',
      'descrizione': 'Affrettati, offerta limitata!',
      'negozio': 'Moda Trend',
      'distanza': '3 km',
      'tipologia': 'Abbigliamento',
      'sconto': 30,
      'dataInizio': DateTime(2024, 2, 5),
      'dataFine': DateTime(2024, 3, 1),
      'immagine':
          'https://m.media-amazon.com/images/I/71LPT1djb9L._AC_UY580_.jpg',
    },
    {
      'titolo': 'Super sconto su orologi',
      'descrizione': 'Orologi di lusso a metà prezzo!',
      'negozio': 'Luxury Time',
      'distanza': '8 km',
      'tipologia': 'Gioielli',
      'sconto': 50,
      'dataInizio': DateTime(2024, 1, 20),
      'dataFine': DateTime(2024, 2, 28),
      'immagine':
          'https://www.orestetroso.it/media/catalog/product/cache/786a0d2ee25f36298d91fcf4d6f2bda8/m/0/m0a10468-2.jpg',
    },
  ];

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> offerteFiltrate = offerte.where((offerta) {
      bool scontoMatch = offerta['sconto'] >= widget.minDiscount &&
          offerta['sconto'] <= widget.maxDiscount;
      bool categoriaMatch = widget.selectedCategory.isEmpty ||
          offerta['tipologia']
              .toLowerCase()
              .contains(widget.selectedCategory.toLowerCase());
      bool dataMatch = (widget.startDate == null ||
              offerta['dataFine'].isAfter(widget.startDate!)) &&
          (widget.endDate == null ||
              offerta['dataInizio'].isBefore(widget.endDate!));

      return scontoMatch && categoriaMatch && dataMatch;
    }).toList();

    return ListView.builder(
      itemCount: offerteFiltrate.length,
      itemBuilder: (context, index) {
        return Card(
          margin: EdgeInsets.all(10),
          child: Column(
            children: [
              Container(
                width: double.infinity, // Occupa tutta la larghezza disponibile
                constraints: BoxConstraints(
                  maxHeight: 250, // Altezza massima per evitare distorsioni
                ),
                child: Image.network(
                  offerteFiltrate[index]['immagine'] ?? '',
                  fit: BoxFit.contain, // Mantiene le proporzioni senza tagliare
                  alignment: Alignment.center,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      width: double.infinity,
                      color: Colors.grey.shade300,
                      child: Icon(Icons.image_not_supported,
                          size: 50, color: Colors.grey),
                    );
                  },
                ),
              ),
              ListTile(
                title: Text(offerteFiltrate[index]['titolo'] ?? 'Senza titolo'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(offerteFiltrate[index]['descrizione'] ??
                        'Nessuna descrizione'),
                    Text('Negozio: ${offerteFiltrate[index]['negozio']}'),
                    Text('Sconto: ${offerteFiltrate[index]['sconto']}%'),
                    Text('Categoria: ${offerteFiltrate[index]['tipologia']}'),
                    Text(
                        'Validità: ${offerteFiltrate[index]['dataInizio'].toString().split(' ')[0]} - ${offerteFiltrate[index]['dataFine'].toString().split(' ')[0]}'),
                  ],
                ),
                trailing: ElevatedButton(
                  onPressed: () => widget.startChat(
                      offerteFiltrate[index]['negozio'] ?? 'Sconosciuto'),
                  child: Text('Chat'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class Vendor {
  String vendorName;
  String businessName;
  String email;
  String phone;
  List<String> chatHistory; // Lista di utenti che hanno contattato il negozio
  List<String> offers; // Lista delle offerte attive

  Vendor({
    required this.vendorName,
    required this.businessName,
    required this.email,
    required this.phone,
    required this.chatHistory,
    required this.offers,
  });

  factory Vendor.fromJson(Map<String, dynamic> json) {
    return Vendor(
      vendorName: json['vendorName'],
      businessName: json['businessName'],
      email: json['email'],
      phone: json['phone'],
      chatHistory: List<String>.from(json['chatHistory'] ?? []),
      offers: List<String>.from(json['offers'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vendorName': vendorName,
      'businessName': businessName,
      'email': email,
      'phone': phone,
      'chatHistory': chatHistory,
      'offers': offers,
    };
  }
}

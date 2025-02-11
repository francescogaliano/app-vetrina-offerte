class UserModel {
  String username;
  String name;
  String surname;
  String email;
  String phone;
  List<String> chatHistory; // Lista di negozi con cui l'utente ha chattato

  UserModel({
    required this.username,
    required this.name,
    required this.surname,
    required this.email,
    required this.phone,
    required this.chatHistory,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      username: json['username'],
      name: json['name'],
      surname: json['surname'],
      email: json['email'],
      phone: json['phone'],
      chatHistory: List<String>.from(json['chatHistory'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'name': name,
      'surname': surname,
      'email': email,
      'phone': phone,
      'chatHistory': chatHistory,
    };
  }
}

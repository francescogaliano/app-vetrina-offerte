import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/chat_service.dart';
import 'chat_page.dart';

class ChatListPage extends StatefulWidget {
  final String uid;
  ChatListPage({required this.uid});

  @override
  _ChatListPageState createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  //final ChatService _chatService = ChatService();
  Map<String, String> _userNamesCache =
      {}; // 🔹 Cache per evitare caricamenti ripetuti
  late Stream<QuerySnapshot> _chatStream;

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  /// 🔹 Recupera la lista delle chat
  void _loadChats() {
    setState(() {
      _chatStream = FirebaseFirestore.instance
          .collection('chats')
          .where('participants', arrayContains: widget.uid)
          .orderBy('lastMessageTimestamp', descending: true)
          .snapshots();
    });
  }

  /// 🔹 Recupera il nome utente o negozio da Firestore e salva nella cache
  Future<String> _getUserName(String userId) async {
    if (_userNamesCache.containsKey(userId)) {
      print("✅ Nome già in cache per $userId: ${_userNamesCache[userId]}");
      return _userNamesCache[userId]!;
    }

    print("🔄 Recupero nome per $userId da Firestore...");
    var userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    if (!userDoc.exists || userDoc.data() == null) {
      print("❌ Nessun documento trovato per $userId in Firestore!");
      return "Sconosciuto";
    }

    Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

    print(
        "📌 Dati ricevuti per $userId: $userData"); // 🔹 Debug per vedere il documento intero

    String role = userData.containsKey('role') ? userData['role'] : "user";
    String name = role == "vendor" && userData.containsKey('shopName')
        ? userData['shopName'] ?? "Negozio Sconosciuto"
        : userData.containsKey('name')
            ? userData['name'] ?? "Utente Sconosciuto"
            : "Sconosciuto";

    print("✅ Nome finale per $userId: $name");
    _userNamesCache[userId] = name;
    return name;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Le mie chat"),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh), // 🔄 Pulsante di ricarica
            onPressed: _loadChats, // 🔹 Ricarica le chat premendo il pulsante
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _chatStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("Nessuna chat attiva"));
          }

          var chats = snapshot.data!.docs;

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              var chat = chats[index];

              var participants = List<String>.from(chat['participants']);
              var chatPartnerId = participants.firstWhere(
                  (id) => id != widget.uid,
                  orElse: () => "Sconosciuto");

              return FutureBuilder<String>(
                future: _getUserName(chatPartnerId),
                builder: (context, nameSnapshot) {
                  if (nameSnapshot.connectionState == ConnectionState.waiting) {
                    return Card(
                      margin: EdgeInsets.all(8),
                      elevation: 3,
                      child: ListTile(
                        title:
                            Text("Chat con ..."), // ✅ Evitiamo "Caricamento..."
                        subtitle: Text(
                            "Ultimo messaggio: ${chat['lastMessage'] ?? 'Nessun messaggio'}"),
                        trailing: CircularProgressIndicator(),
                      ),
                    );
                  }

                  String chatPartnerName = nameSnapshot.data ?? "Sconosciuto";

                  return Card(
                    margin: EdgeInsets.all(8),
                    elevation: 3,
                    child: ListTile(
                      title:
                          Text("Chat con $chatPartnerName"), // ✅ Nome corretto
                      subtitle: Text(
                          "Ultimo messaggio: ${chat['lastMessage'] ?? 'Nessun messaggio'}"),
                      trailing: Icon(Icons.chat),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatPage(
                              currentUserId: widget.uid,
                              receiverUserId: chatPartnerId,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

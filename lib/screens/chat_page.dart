import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// Mappa globale per separare le chat tra utenti e negozianti
Map<String, Map<String, List<String>>> userChatMessages = {};
// Mappa per tracciare i messaggi non letti
Map<String, int> unreadMessages = {};
// Tiene traccia delle chat aperte
Map<String, bool> chatOpened = {};

class ChatListPage extends StatefulWidget {
  final Function(String) startChat;
  final bool isVendor;
  final String currentUser; // Nome dell'utente o negozio attuale

  ChatListPage({
    required this.startChat,
    required this.isVendor,
    required this.currentUser,
  });

  @override
  _ChatListPageState createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  void _openChat(String chatPartner) async {
    setState(() {
      unreadMessages[chatPartner] = 0;
      chatOpened[chatPartner] = true; // Segniamo la chat come "aperta"
    });

    final newMessage = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(
          vendorName: chatPartner,
          currentUser: widget.currentUser,
        ),
      ),
    );

    setState(() {
      chatOpened[chatPartner] =
          false; // Segniamo la chat come "chiusa" quando l'utente esce
    });
    if (newMessage != null) {
      setState(() {
        userChatMessages[widget.currentUser]![chatPartner]!.add(newMessage);
      });
    }
  }

  Future<void> _loadChats() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? chatsJson = prefs.getString('chat_${widget.currentUser}');
    if (chatsJson != null) {
      setState(() {
        userChatMessages[widget.currentUser] = Map<String, List<String>>.from(
          json
              .decode(chatsJson)
              .map((key, value) => MapEntry(key, List<String>.from(value))),
        );
      });
    }
  }

  Future<void> _deleteChat(String chatPartner, bool deleteForBoth) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      // ✅ Rimuoviamo la chat dall'utente attuale
      userChatMessages[widget.currentUser]?.remove(chatPartner);

      // ✅ Rimuoviamo anche le notifiche per quella chat
      unreadMessages.remove(chatPartner);
      chatOpened.remove(chatPartner);

      if (deleteForBoth) {
        // ✅ Se la chat viene eliminata per entrambi, rimuoviamola anche dal partner
        userChatMessages.remove(chatPartner);
        unreadMessages.remove(chatPartner);
        chatOpened.remove(chatPartner);
        prefs.remove('chat_$chatPartner');
      }
    });

    await prefs.setString(
      'chat_${widget.currentUser}',
      json.encode(userChatMessages[widget.currentUser]),
    );
  }

  void _showDeleteChatDialog(String chatPartner) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Elimina chat"),
          content: Text("Vuoi eliminare la chat solo per te o per entrambi?"),
          actions: [
            TextButton(
              child: Text("Solo per me"),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteChat(chatPartner, false);
              },
            ),
            TextButton(
              child: Text("Per entrambi"),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteChat(chatPartner, true);
              },
            ),
            TextButton(
              child: Text("Annulla"),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    userChatMessages.putIfAbsent(widget.currentUser, () => {});
    Map<String, List<String>> chatMessages =
        userChatMessages[widget.currentUser]!;

    return chatMessages.isEmpty
        ? Center(child: Text("Nessuna chat avviata"))
        : ListView.builder(
            itemCount: chatMessages.length,
            itemBuilder: (context, index) {
              String chatPartner = chatMessages.keys.elementAt(index);

              return Card(
                margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                elevation: 3,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  title: Text(widget.isVendor
                      ? "Chat con Cliente: ${chatPartner}"
                      : "Chat con $chatPartner"),
                  subtitle: Text(chatMessages[chatPartner]?.isNotEmpty == true
                      ? chatMessages[chatPartner]!.last
                      : "Nessun messaggio"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Mostra il numero di messaggi non letti se ci sono
                      if (unreadMessages[chatPartner] != null &&
                          unreadMessages[chatPartner]! > 0)
                        Container(
                          padding: EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            unreadMessages[chatPartner]!.toString(),
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      IconButton(
                          icon: Icon(Icons.chat_bubble),
                          onPressed: () =>
                              // Quando l'utente apre la chat, azzeriamo il contatore
                              _openChat(
                                  chatPartner) // ✅ Ora viene chiamato correttamente!,
                          ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _showDeleteChatDialog(chatPartner),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
  }
}

class ChatPage extends StatefulWidget {
  final String vendorName;
  final String currentUser;

  ChatPage({required this.vendorName, required this.currentUser}) {
    // ✅ Quando la chat viene aperta, NON aumentiamo le notifiche
    if (!chatOpened.containsKey(vendorName)) {
      chatOpened[vendorName] = true; // Segniamo la chat come "aperta"
    }
  }

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  TextEditingController _messageController = TextEditingController();

  void _sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      setState(() {
        userChatMessages.putIfAbsent(widget.currentUser, () => {});
        userChatMessages.putIfAbsent(widget.vendorName, () => {});

        userChatMessages[widget.currentUser]!
            .putIfAbsent(widget.vendorName, () => []);
        userChatMessages[widget.currentUser]![widget.vendorName]!
            .add("Tu: " + _messageController.text);

        userChatMessages[widget.vendorName]!
            .putIfAbsent(widget.currentUser, () => []);
        userChatMessages[widget.vendorName]![widget.currentUser]!
            .add("${widget.currentUser}: " + _messageController.text);

        // ✅ Assicuriamoci che `chatOpened` esista
        chatOpened.putIfAbsent(widget.vendorName, () => false);
        chatOpened.putIfAbsent(widget.currentUser, () => false);

        // ✅ Aggiungiamo la notifica SOLO se il messaggio proviene dall'altro utente
        if (!chatOpened[widget.vendorName]! &&
            widget.currentUser != widget.vendorName) {
          unreadMessages[widget.vendorName] =
              (unreadMessages[widget.vendorName] ?? 0) + 1;
        }
        // ✅ Aggiungiamo la notifica SOLO SE ci sono più di 1 messaggio (quindi il venditore ha risposto)
        if (userChatMessages[widget.vendorName]![widget.currentUser]!.length >
            1) {
          if (!chatOpened[widget.vendorName]!) {
            unreadMessages[widget.vendorName] =
                (unreadMessages[widget.vendorName] ?? 0) + 1;
          }
        }

        if (!chatOpened.containsKey(widget.currentUser)) {
          chatOpened[widget.currentUser] =
              false; // Inizializza per il venditore
        }

        // ✅ Se la chat non è aperta, aumenta il contatore dei messaggi non letti
        if (!chatOpened[widget.vendorName]!) {
          unreadMessages[widget.vendorName] =
              (unreadMessages[widget.vendorName] ?? 0) + 1;
        }
        if (!chatOpened[widget.currentUser]!) {
          unreadMessages[widget.currentUser] =
              (unreadMessages[widget.currentUser] ?? 0) + 1;
        }
      });
      _saveChat();
      _messageController.clear();
    }
  }

  Future<void> _saveChat() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'chat_${widget.currentUser}',
      json.encode(userChatMessages[widget.currentUser]),
    );
    await prefs.setString(
      'chat_${widget.vendorName}',
      json.encode(userChatMessages[widget.vendorName]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chat con ${widget.vendorName}"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            setState(() {
              chatOpened[widget.vendorName] =
                  false; // Segniamo la chat come chiusa
            });
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: userChatMessages[widget.currentUser]
                          ?[widget.vendorName]
                      ?.length ??
                  0,
              itemBuilder: (context, index) {
                return Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: EdgeInsets.all(8),
                    margin: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(userChatMessages[widget.currentUser]![
                        widget.vendorName]![index]),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Scrivi un messaggio...',
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

// Questa variabile globale deve essere definita nel file principale dell'app
// e utilizzata sia in ChatListPage che in ChatPage
Map<String, Map<String, List<String>>> userChatMessages =
    {}; // Mappa che separa le chat per utente/negozio

class ChatListPage extends StatefulWidget {
  final Function(String) startChat;
  final bool isVendor;
  final String currentUser; // Nome dell'utente o negozio attuale

  ChatListPage(
      {required this.startChat,
      required this.isVendor,
      required this.currentUser});

  @override
  _ChatListPageState createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
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
                  trailing: Icon(Icons.chat_bubble),
                  onTap: () async {
                    final newMessage = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatPage(
                            vendorName: chatPartner,
                            currentUser: widget.currentUser),
                      ),
                    );
                    if (newMessage != null) {
                      setState(() {
                        chatMessages[chatPartner]?.add(newMessage);
                      });
                    }
                  },
                ),
              );
            },
          );
  }
}

class ChatPage extends StatefulWidget {
  final String vendorName;
  final String currentUser;

  ChatPage({required this.vendorName, required this.currentUser});

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  TextEditingController _messageController = TextEditingController();

  void _sendMessage() {
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
      });
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chat con ${widget.vendorName}"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
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

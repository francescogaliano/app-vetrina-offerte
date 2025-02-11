import 'package:flutter/material.dart';

class ChatListPage extends StatelessWidget {
  final Map<String, List<String>> chatMessages;
  final Function(String) startChat;

  ChatListPage({required this.chatMessages, required this.startChat});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(8.0),
      child: ListView.builder(
        itemCount: chatMessages.length,
        itemBuilder: (context, index) {
          String negozio = chatMessages.keys.elementAt(index);
          String lastMessage = chatMessages[negozio]?.isNotEmpty == true
              ? chatMessages[negozio]!.last
              : "Nessun messaggio";

          return Container(
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 5),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade100, Colors.blue.shade300],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade400,
                  blurRadius: 5,
                  spreadRadius: 2,
                  offset: Offset(2, 4),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: EdgeInsets.all(10),
              leading: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.store, color: Colors.blue),
              ),
              title: Text(
                'Chat con $negozio',
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              subtitle: Text(
                lastMessage,
                style: TextStyle(color: Colors.white70),
              ),
              trailing: Text(
                "Ora",
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              onTap: () => startChat(negozio),
            ),
          );
        },
      ),
    );
  }
}

class ChatDetailPage extends StatefulWidget {
  final Map<String, List<String>> chatMessages;
  final String selectedChat;

  ChatDetailPage({required this.chatMessages, required this.selectedChat});

  @override
  _ChatDetailPageState createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  TextEditingController _messageController = TextEditingController();

  void _sendMessage() {
    if (_messageController.text.isNotEmpty) {
      setState(() {
        widget.chatMessages[widget.selectedChat]
            ?.add("Utente: " + _messageController.text);
        _messageController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: widget.chatMessages[widget.selectedChat]?.length ?? 0,
            itemBuilder: (context, index) {
              return Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: EdgeInsets.all(8),
                  margin: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(widget.chatMessages[widget.selectedChat]![index]),
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
    );
  }
}

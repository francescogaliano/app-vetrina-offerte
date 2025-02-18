import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatPage extends StatefulWidget {
  final String uid; // L'UID dell'utente o del venditore

  ChatPage({required this.uid});

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? selectedChatId;
  String? selectedChatPartner;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(selectedChatId == null
            ? "Le tue Chat"
            : "Chat con $selectedChatPartner"),
        leading: selectedChatId != null
            ? IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    selectedChatId = null;
                    selectedChatPartner = null;
                  });
                },
              )
            : null,
      ),
      body: selectedChatId == null ? _buildChatList() : _buildChatDetail(),
    );
  }

  /// ✅ Mostra la lista delle chat per l'utente corrente
  Widget _buildChatList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('chats')
          .where('participants', arrayContains: widget.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text("Nessuna chat avviata"));
        }

        var chatDocs = snapshot.data!.docs;

        return ListView.builder(
          itemCount: chatDocs.length,
          itemBuilder: (context, index) {
            var chat = chatDocs[index];
            var participants = List<String>.from(chat['participants']);
            var chatPartner = participants.firstWhere((p) => p != widget.uid);

            return Card(
              margin: EdgeInsets.all(8),
              child: ListTile(
                title: Text("Chat con $chatPartner"),
                subtitle: Text(chat['lastMessage']),
                trailing: Icon(Icons.chat),
                onTap: () {
                  setState(() {
                    selectedChatId = chat.id;
                    selectedChatPartner = chatPartner;
                  });
                },
              ),
            );
          },
        );
      },
    );
  }

  /// ✅ Mostra i dettagli di una chat specifica
  Widget _buildChatDetail() {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('chats')
                .doc(selectedChatId)
                .collection('messages')
                .orderBy('timestamp', descending: false)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(child: Text("Nessun messaggio ancora"));
              }

              var messages = snapshot.data!.docs;

              return ListView.builder(
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  var message = messages[index];
                  bool isMe = message['sender'] == widget.uid;

                  return Align(
                    alignment:
                        isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isMe ? Colors.blue[300] : Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(message['text']),
                    ),
                  );
                },
              );
            },
          ),
        ),
        _buildMessageInput(),
      ],
    );
  }

  /// ✅ Campo di input per inviare nuovi messaggi
  Widget _buildMessageInput() {
    TextEditingController _messageController = TextEditingController();

    void _sendMessage() {
      if (_messageController.text.isEmpty) return;

      _firestore
          .collection('chats')
          .doc(selectedChatId)
          .collection('messages')
          .add({
        'text': _messageController.text,
        'sender': widget.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Aggiorniamo l'ultimo messaggio per la lista chat
      _firestore.collection('chats').doc(selectedChatId).update({
        'lastMessage': _messageController.text,
        'timestamp': FieldValue.serverTimestamp(),
      });

      _messageController.clear();
    }

    return Padding(
      padding: EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(hintText: "Scrivi un messaggio..."),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }
}

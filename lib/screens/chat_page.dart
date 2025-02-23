import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/chat_service.dart';

class ChatPage extends StatefulWidget {
  final String currentUserId; // L'utente loggato (può essere user o vendor)
  final String receiverUserId; // Il destinatario della chat

  const ChatPage(
      {required this.currentUserId, required this.receiverUserId, Key? key})
      : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();
  bool _chatInitialized = false; // ✅ Controllo per il primo avvio della chat

/* @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  /// 🔹 Inizializza la chat forzando il refresh dei messaggi
  void _initializeChat() async {
    print("🔄 Inizializzazione della chat...");
    
    // Controlla se la chat esiste già e forza il refresh
    await _chatService.createChatIfNotExists(widget.currentUserId, widget.receiverUserId);
    
    setState(() {
      _chatInitialized = true;
    });

    print("✅ Chat inizializzata correttamente!");
  }
 */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Chat")),
      body: Column(
        children: [
          Expanded(
              child: StreamBuilder<QuerySnapshot>(
            stream: _chatService.getMessages(
                widget.currentUserId, widget.receiverUserId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(child: Text("Nessun messaggio"));
              }

              var messages = snapshot.data!.docs;

              return ListView.builder(
                reverse: false,
                controller: _scrollController,
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  var message = messages[index];
                  bool isMe = message['senderId'] == widget.currentUserId;

                  // ✅ Convert message.data() to a Map<String, dynamic> safely
                  Map<String, dynamic> messageData =
                      message.data() as Map<String, dynamic>;

                  // ✅ Safe check: Only use 'edited' if it exists, same for 'deleted'
                  bool isEdited = messageData.containsKey('edited')
                      ? messageData['edited']
                      : false;
                  bool isDeleted = messageData.containsKey('deleted')
                      ? messageData['deleted']
                      : false;

                  return GestureDetector(
                    onLongPress: () {
                      if (isMe)
                        _showMessageOptions(
                            context, message.id, message['message'], isDeleted);
                    },
                    child: Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin:
                            EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDeleted
                              ? Colors.grey[400]
                              : (isMe
                                  ? Colors.blue[300]
                                  : Colors.grey[
                                      300]), // ✅ Colore per messaggi eliminati
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message['message'],
                              style: TextStyle(
                                fontStyle: isDeleted
                                    ? FontStyle.italic
                                    : FontStyle
                                        .normal, // ✅ Corsivo per messaggi eliminati
                                color:
                                    isDeleted ? Colors.black54 : Colors.black,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              "${_formatTimestamp(message['timestamp'])}${isEdited ? " [Edited]" : ""}", // ✅ Mostriamo [Edited] solo se modificato
                              style: TextStyle(
                                  fontSize: 10, color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          )),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration:
                        InputDecoration(hintText: "Scrivi un messaggio..."),
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

  /// 🔹 Mostra il menu per modificare o eliminare un messaggio
  void _showMessageOptions(BuildContext context, String messageId,
      String currentMessage, bool isDeleted) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Wrap(
        children: [
          if (!isDeleted) // ✅ Rimuoviamo l'opzione Modifica se il messaggio è stato eliminato
            ListTile(
              leading: Icon(Icons.edit),
              title: Text("Modifica"),
              onTap: () {
                Navigator.pop(context);
                _editMessage(messageId, currentMessage);
              },
            ),
          ListTile(
            leading: Icon(Icons.delete),
            title: Text(isDeleted ? "Elimina definitivamente" : "Elimina"),
            onTap: () {
              Navigator.pop(context);
              isDeleted
                  ? _chatService.permanentDeleteMessage(_getChatId(), messageId)
                  : _deleteMessage(messageId);
            },
          ),
        ],
      ),
    );
  }

  /// 🔹 Modifica un messaggio
  void _editMessage(String messageId, String currentMessage) {
    TextEditingController _editController =
        TextEditingController(text: currentMessage);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Modifica Messaggio"),
        content: TextField(controller: _editController),
        actions: [
          TextButton(
            child: Text("Annulla"),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text("Salva"),
            onPressed: () {
              _chatService.editMessage(
                  _getChatId(), messageId, _editController.text);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  /// 🔹 Elimina un messaggio
  void _deleteMessage(String messageId) {
    _chatService.deleteMessage(_getChatId(), messageId);
  }

  /*  /// 🔹 Invia un messaggio
  void _sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      await _chatService.sendMessage(
          widget.currentUserId, widget.receiverUserId, _messageController.text);
      _messageController.clear();

      Future.delayed(Duration(milliseconds: 300), () {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      });
    }
  } */

  /// 🔹 Invia un messaggio e aggiorna la UI
  void _sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      print("📨 Tentativo di invio messaggio...");

      await _chatService.sendMessage(
          widget.currentUserId, widget.receiverUserId, _messageController.text);

      _messageController.clear();

      // 🔹 Evitiamo il crash controllando se il controller è ancora valido
      if (mounted) {
        Future.delayed(Duration(milliseconds: 300), () {
          if (_scrollController.hasClients) {
            _scrollController
                .jumpTo(_scrollController.position.maxScrollExtent);
          }
        });
      }
      // 🔹 Forza l’aggiornamento della UI dopo l’invio del messaggio
      setState(() {});
    }
  }

  /// 🔹 Genera un ID univoco per la chat
  String _getChatId() {
    List<String> ids = [widget.currentUserId, widget.receiverUserId];
    ids.sort();
    return ids.join('_');
  }

  /// 🔹 Formatta data e ora dei messaggi
  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return "";
    DateTime date = timestamp.toDate();
    return "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }
}

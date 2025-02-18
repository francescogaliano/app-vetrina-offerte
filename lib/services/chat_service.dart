import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🔹 Metodo per ottenere l'ID univoco della chat
  String _getChatId(String userId, String vendorId) {
    List<String> ids = [userId, vendorId];
    ids.sort();
    return ids.join('_');
  }

  Future<void> sendMessage(
      String senderId, String receiverId, String message) async {
    String chatId = _getChatId(senderId, receiverId);
    DocumentReference chatRef =
        FirebaseFirestore.instance.collection('chats').doc(chatId);

    try {
      var currentUser = FirebaseAuth.instance.currentUser;
      print("✅ Utente autenticato: ${currentUser?.uid}");
      print("🔍 Tentativo di scrivere in chat: $chatId");
      print("🔍 Mittente: $senderId, Destinatario: $receiverId");

      // Verifica se il documento della chat esiste
      DocumentSnapshot chatSnapshot = await chatRef.get();
      if (!chatSnapshot.exists) {
        print("⚠️ Chat non esistente, la creiamo...");
        await chatRef.set({
          'participants': [senderId, receiverId],
          'lastMessage': message,
          'lastMessageTimestamp': FieldValue.serverTimestamp(),
        });
      } else {
        print("✅ Chat esistente, aggiornamento ultimo messaggio...");
        await chatRef.update({
          'lastMessage': message,
          'lastMessageTimestamp': FieldValue.serverTimestamp(),
        });
      }

      // Aggiungiamo il messaggio alla sottocollezione
      print("✉️ Tentativo di scrivere in messages...");
      await chatRef.collection('messages').add({
        'senderId': senderId,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'edited': false,
        'deleted': false,
      }).then((value) {
        print("✅ Messaggio salvato con ID: ${value.id}");
      }).catchError((error) {
        print("❌ Errore nell'aggiunta a messages: $error");
      });
    } catch (e) {
      print("❌ Errore durante l'invio del messaggio: $e");
    }
  }

  /// 🔹 Recupera i messaggi di una chat
  Stream<QuerySnapshot> getMessages(String userId, String vendorId) {
    String chatId = _getChatId(userId, vendorId);
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  /// 🔹 Recupera la lista delle chat per un utente
  Stream<QuerySnapshot> getUserChats(String uid) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: uid)
        .orderBy('lastMessageTimestamp', descending: true)
        .snapshots();
  }

  /// 🔹 Modifica un messaggio esistente
  Future<void> editMessage(
      String chatId, String messageId, String newMessage) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({
      'message': newMessage, // 🔹 Manteniamo solo il testo originale
      'edited': true, // 🔹 Impostiamo il flag di modifica
    });
  }

  /// 🔹 Segna un messaggio come eliminato (invece di cancellarlo)
  Future<void> deleteMessage(String chatId, String messageId) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({
      'message': "Message deleted",
      'deleted': true,
    });
  }

  /// 🔹 Elimina un messaggio
  Future<void> permanentDeleteMessage(String chatId, String messageId) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .delete();
  }
}

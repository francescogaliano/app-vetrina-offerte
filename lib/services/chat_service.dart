import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  //final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  /// 🔹 Metodo per ottenere l'ID univoco della chat
  String _getChatId(String userId, String vendorId) {
    List<String> ids = [userId, vendorId];
    ids.sort();
    return ids.join('_');
  }

  /// 🔹 Crea la chat se non esiste
  Future<void> createChatIfNotExists(String senderId, String receiverId) async {
    String chatId = _getChatId(senderId, receiverId);
    DocumentReference chatRef = _firestore.collection('chats').doc(chatId);

    DocumentSnapshot chatSnapshot = await chatRef.get();

    if (!chatSnapshot.exists) {
      print("⚠️ Chat non esistente, creazione...");
      await chatRef.set({
        'participants': [senderId, receiverId],
        'lastMessage': "",
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
      });
      print("✅ Chat creata con successo!");
    }
  }

  /// 🔹 Invia un messaggio e crea la chat se non esiste
  Future<void> sendMessage(
      String senderId, String receiverId, String message) async {
    String chatId = _getChatId(senderId, receiverId);
    DocumentReference chatRef = _firestore.collection('chats').doc(chatId);

    //try {
    var currentUser = FirebaseAuth.instance.currentUser;
    print("✅ Utente autenticato: ${currentUser?.uid}");
    print("🔍 Tentativo di scrivere in chat: $chatId");
    print("🔍 Mittente: $senderId, Destinatario: $receiverId");

    // Controllo se la chat esiste
    DocumentSnapshot chatSnapshot = await chatRef.get();
    print("🔍 L'ERRORE E' DOPO IL DOCUMENT SNAPSHOT");

    if (!chatSnapshot.exists) {
      print("⚠️ Chat non esistente, creazione...");
      await chatRef.set({
        'participants': [senderId, receiverId],
        'lastMessage': message,
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
      });
      print("✅ Chat creata con successo!");
    } else {
      print("✅ Chat esistente, controllo partecipanti...");
      List<dynamic>? participants = chatSnapshot.get('participants');

      if (participants == null || !participants.contains(senderId)) {
        print("❌ ERRORE: L'utente $senderId NON è un partecipante della chat!");
        return;
      }
      print("✅ Utente $senderId è un partecipante della chat.");

      await chatRef.update({
        'lastMessage': message,
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
      });
    }

    // 🔹 Tentiamo di scrivere un messaggio
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
      print("❌ ERRORE FIRESTORE: $error");
    });
    //} catch (e) {
    //  print("❌ Errore durante l'invio del messaggio: $e");
    //}
/*     // 🔹 Recuperiamo il token di FCM del destinatario

    DocumentSnapshot receiverSnapshot =
        await _firestore.collection('users').doc(receiverId).get();

    if (receiverSnapshot.exists) {
      // ✅ Convertiamo esplicitamente il documento in `Map<String, dynamic>`
      Map<String, dynamic>? userData =
          receiverSnapshot.data() as Map<String, dynamic>?;

      // ✅ Controlliamo se il campo `fcmToken` esiste nella mappa
      String? token = userData != null && userData.containsKey('fcmToken')
          ? userData['fcmToken']
          : null;

      if (token != null) {
        sendPushNotification(token, "Nuovo messaggio", message);
      } else {
        print("⚠️ Nessun token FCM trovato per l'utente $receiverId");
      }
    } */
  }
/* 
  /// 🔹 Funzione per inviare una notifica push
  Future<void> sendPushNotification(
      String token, String title, String body) async {
    await _firebaseMessaging.sendMessage(
      to: token,
      data: {
        'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        'title': title,
        'body': body,
      },
    );
  } */

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

class AuthService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> requestNotificationPermission() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print("✅ Notifiche autorizzate!");
    } else {
      print("❌ L'utente ha negato le notifiche.");
    }
  }
}

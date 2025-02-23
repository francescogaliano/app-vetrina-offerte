import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/login_screen.dart';
import '../screens/user_home.dart';
import '../screens/vendor_home.dart';
import 'firebase_options.dart';
//import 'package:firebase_messaging/firebase_messaging.dart';
//import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'services/auth_service.dart';
import 'dart:html' as html;

/* Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("📩 Notifica ricevuta in background: ${message.notification?.title}");
} */

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

/*   // 🔹 Registriamo il Service Worker solo su Web
  if (html.window.navigator.serviceWorker != null) {
    try {
      await html.window.navigator.serviceWorker!
          .register('/firebase-messaging-sw.js');
      print("✅ Service Worker registrato con successo!");
    } catch (e) {
      print("❌ Errore nella registrazione del Service Worker: $e");
    }
  }

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  FirebaseAuth.instance.authStateChanges().listen((User? user) {
    if (user != null) {
      AuthService().saveUserToken(user.uid);
    }
  }); */
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Vetrina Offerte',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: AuthWrapper(), // ✅ Controlla se l'utente è loggato e lo reindirizza
    );
  }
}

/// ✅ Controlla se l'utente è loggato e lo manda alla pagina corretta
class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasData && snapshot.data != null) {
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(snapshot.data!.uid)
                .get(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return Scaffold(
                    body: Center(child: CircularProgressIndicator()));
              }

              if (userSnapshot.hasData &&
                  userSnapshot.data != null &&
                  userSnapshot.data!.exists) {
                var userData =
                    userSnapshot.data!.data() as Map<String, dynamic>;
                bool isVendor = userData['role'] == 'vendor';

                return isVendor
                    ? VendorHome(
                        uid: snapshot.data!
                            .uid) // ✅ Mostra prima le offerte per il venditore
                    : UserHome(
                        uid: snapshot.data!
                            .uid); // ✅ Mostra prima le offerte per l'utente
              } else {
                return LoginScreen();
              }
            },
          );
        } else {
          return LoginScreen();
        }
      },
    );
  }
}

/* final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void setupFlutterNotifications() {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  final InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);

  flutterLocalNotificationsPlugin.initialize(initializationSettings);
}

void showNotification(RemoteMessage message) {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails('channel_id', 'Chat Notifiche',
          importance: Importance.max, priority: Priority.high);

  const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);

  flutterLocalNotificationsPlugin.show(0, message.notification?.title,
      message.notification?.body, platformChannelSpecifics);
}
 */

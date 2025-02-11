import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ChatDatabase {
  static Future<void> saveChat(
      String user, String vendor, List<String> messages) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String chatKey = 'chat_${user}_$vendor';
    await prefs.setString(chatKey, json.encode(messages));
  }

  static Future<List<String>> loadChat(String user, String vendor) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String chatKey = 'chat_${user}_$vendor';
    String? messages = prefs.getString(chatKey);
    if (messages != null) {
      return List<String>.from(json.decode(messages));
    }
    return [];
  }
}

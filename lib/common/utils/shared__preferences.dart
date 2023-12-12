import 'dart:convert';

import 'package:face_recognition_demo/model/User.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'file_utils.dart';

class PreferenceManager {
  PreferenceManager._();

  static final PreferenceManager instance = PreferenceManager._();
  static const KEY_USER = 'user';

  Future<bool> saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    final status = await prefs.setString(KEY_USER, jsonEncode(user.toJson()));
    return status;
    //  FileUtils.saveFile(user);
  }

  Future<User?> getUser() async {
    final prefs = await SharedPreferences.getInstance();

    String? userString = prefs.getString(KEY_USER);

    if (userString == null) return null;
    Map<String, dynamic> userMap = jsonDecode(userString);

    final user = User.fromJson(userMap);

    return user;
  }
  Future<bool> removeUser() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.remove(KEY_USER);
  }
}

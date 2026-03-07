import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {

  static const String baseUrl = "http://192.168.1.11:8000/api";

  /// ================= LOGIN =================
  static Future<Map<String, dynamic>> login(
      String nisnNip,
      String password,
      ) async {

    final response = await http.post(
      Uri.parse("$baseUrl/login"),
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
      body: jsonEncode({
        "nisn_nip": nisnNip,
        "password": password,
      }),
    );

    final data = jsonDecode(response.body);

    print("LOGIN STATUS : ${response.statusCode}");
    print("LOGIN BODY : ${response.body}");

    if (response.statusCode == 200) {

      SharedPreferences prefs = await SharedPreferences.getInstance();

      await prefs.setString("token", data["token"]);
      await prefs.setString("name", data["user"]["name"]);
      await prefs.setString("role", data["user"]["role"]);

      print("TOKEN TERSIMPAN : ${data["token"]}");

      return {
        "success": true,
        "data": data
      };

    } else {

      return {
        "success": false,
        "message": data["message"]
      };

    }
  }

  /// ================= LOGOUT =================
  static Future<bool> logout() async {

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");

    print("TOKEN SAAT LOGOUT : $token");

    try {

      if (token != null) {

        final response = await http.post(
          Uri.parse("$baseUrl/logout"),
          headers: {
            "Content-Type": "application/json",
            "Accept": "application/json",
            "Authorization": "Bearer $token"
          },
        );

        print("LOGOUT STATUS : ${response.statusCode}");
        print("LOGOUT BODY : ${response.body}");
      }

      /// hapus semua session
      await prefs.clear();

      return true;

    } catch (e) {

      print("ERROR LOGOUT : $e");

      await prefs.clear();

      return true;

    }

  }

  static Future<String?> getToken() async {

    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");

  }

  static Future<String?> getName() async {

    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString("name");

  }

  static Future<String?> getRole() async {

    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString("role");

  }

  static Future<bool> isLoggedIn() async {

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("token");

    if (token != null) {
      return true;
    }

    return false;

  }

}
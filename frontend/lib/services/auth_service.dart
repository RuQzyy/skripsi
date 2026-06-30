import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = "http://192.168.1.14:8000/api";

  /// ================= LOGIN =================
  static Future<Map<String, dynamic>> login(
    String nisnNip,
    String password,
  ) async {
    try {
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

      print("LOGIN STATUS: ${response.statusCode}");
      print("LOGIN BODY: ${response.body}");

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        SharedPreferences prefs = await SharedPreferences.getInstance();

        /// HAPUS CACHE LAMA
        await prefs.clear();

        /// SIMPAN TOKEN
        await prefs.setString(
          "token",
          data["token"].toString(),
        );

        /// SIMPAN USER FULL
        await prefs.setString(
          "user",
          jsonEncode(data["user"]),
        );

        /// SIMPAN DATA PENTING
        await prefs.setString(
          "name",
          (data["user"]["name"] ?? "").toString(),
        );

        await prefs.setString(
          "role",
          (data["user"]["role"] ?? "").toString(),
        );

        return {
          "success": true,
          "data": data,
        };
      } else {
        return {
          "success": false,
          "message": data["message"] ?? "Login gagal",
        };
      }
    } catch (e) {
      print("LOGIN ERROR: $e");

      return {
        "success": false,
        "message": "Error: $e",
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
            "Authorization": "Bearer $token",
          },
        );

        print("LOGOUT STATUS : ${response.statusCode}");
        print("LOGOUT BODY : ${response.body}");
      }

      /// HAPUS SESSION
      await prefs.clear();

      return true;
    } catch (e) {
      print("ERROR LOGOUT : $e");

      await prefs.clear();

      return true;
    }
  }

  /// ================= GET TOKEN =================
  static Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    return prefs.getString("token");
  }

  /// ================= GET NAME =================
  static Future<String?> getName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    return prefs.getString("name");
  }

  /// ================= GET ROLE =================
  static Future<String?> getRole() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    return prefs.getString("role");
  }

  /// ================= GET USER =================
  static Future<Map<String, dynamic>?> getUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    final userString = prefs.getString("user");

    print("USER STRING : $userString");

    if (userString == null || userString.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(userString);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      return null;
    } catch (e) {
      print("GET USER ERROR : $e");
      return null;
    }
  }

  static Future<Map<String, dynamic>?> fetchUser() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();

  String? token = prefs.getString("token");

  try {
    final response = await http.get(
      Uri.parse("$baseUrl/me"),
      headers: {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      final user = jsonDecode(response.body);

      // Update cache
      await prefs.setString(
        "user",
        jsonEncode(user),
      );

      return user;
    }

    return null;
  } catch (e) {
    print("FETCH USER ERROR : $e");
    return null;
  }
}

  /// ================= CHECK LOGIN =================
  static Future<bool> isLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String? token = prefs.getString("token");

    return token != null;
  }

  /// ================= UPDATE PASSWORD =================
  static Future<bool> updatePassword(
    String password,
  ) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String? token = prefs.getString("token");

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/update-password"),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "password": password,
        }),
      );

      print(
        "UPDATE PASSWORD STATUS : ${response.statusCode}",
      );

      print(
        "UPDATE PASSWORD BODY : ${response.body}",
      );

      if (response.statusCode == 200) {
        return true;
      }

      return false;
    } catch (e) {
      print("UPDATE PASSWORD ERROR : $e");

      return false;
    }
  }
}
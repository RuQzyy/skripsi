import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class GoogleService {

  static const String baseUrl = "http://192.168.1.14:8000/api";
  // static const String baseUrl = "http://10.143.208.37:8000/api";

  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  static Future<bool> connectGoogle() async {

    try {

      final GoogleSignInAccount? account =
          await _googleSignIn.signIn();

      if (account == null) {
        return false;
      }

      SharedPreferences prefs =
          await SharedPreferences.getInstance();

      String? token = prefs.getString("token");

      final response = await http.post(
        Uri.parse("$baseUrl/connect-google"),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "google_id": account.id,
          "email": account.email,
        }),
      );

      return response.statusCode == 200;

    } catch (e) {

      print(e);
      return false;

    }
  }
}
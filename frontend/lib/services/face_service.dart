import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class FaceService {
  // Ganti sesuai IP Laravel
static const String baseUrl = "http://192.168.1.12:8000/api";
  // static const String baseUrl = "http://10.170.1.37:8000/api";

  static Future<Map<String, dynamic>> registerFace(File image) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final token = prefs.getString("token");

      var request = http.MultipartRequest(
        "POST",
        Uri.parse("$baseUrl/register-face"),
      );

      request.headers.addAll({
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      });

      request.files.add(
        await http.MultipartFile.fromPath(
          "photo",
          image.path,
        ),
      );

      final response = await request.send();

      final body = await response.stream.bytesToString();

      return jsonDecode(body);
    } catch (e) {
      return {
        "success": false,
        "message": e.toString(),
      };
    }
  }
}
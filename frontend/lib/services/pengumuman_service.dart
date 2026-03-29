import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/pengumuman_model.dart';

class PengumumanService {

  static const String baseUrl = "http://192.168.1.12:8000/api";

  static Future<Map<String, dynamic>> getPengumuman({
    int? limit,
    int page = 1,
  }) async {

    String url = "$baseUrl/pengumuman";

    if (limit != null) {
      url += "?limit=$limit";
    } else {
      url += "?page=$page";
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {
        "Accept": "application/json"
      },
    );

    if (response.statusCode == 200) {

      final data = jsonDecode(response.body);

      List list = data["data"];

      return {
        "data": list.map((item) => Pengumuman.fromJson(item)).toList(),
        "last_page": data["last_page"] ?? 1,
      };

    } else {

      throw Exception("Gagal mengambil pengumuman");

    }
  }
}
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/attendance_setting.dart';

class AttendanceService {
  static const String baseUrl = "http://192.168.1.14:8000/api";
  // static const String baseUrl = "http://10.170.1.37:8000/api";

  // ==========================
  // Ambil Pengaturan Absensi
  // ==========================
  Future<AttendanceSetting> getSetting() async {
    final response = await http.get(
      Uri.parse("$baseUrl/absensi-setting"),
    );

    debugPrint(response.body);

    if (response.statusCode != 200) {
      throw Exception("Gagal mengambil data pengaturan");
    }

    final data = jsonDecode(response.body);

    return AttendanceSetting.fromJson(
      data["data"],
    );
  }

  // ==========================
  // Cek Status Absensi Hari Ini
  // ==========================
  Future<Map<String, dynamic>?> getTodayAttendance() async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString("token");

    final response = await http.get(
      Uri.parse("$baseUrl/attendance/today"),
      headers: {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode != 200) {
      throw Exception("Gagal mengambil status absensi");
    }

    final data = jsonDecode(response.body);

    return data["data"]; // null kalau belum absen, atau Map kalau sudah
  }

  // ==========================
  // Ambil Riwayat Absensi
  // ==========================
  Future<List<dynamic>> getRiwayatAttendance() async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString("token");

    final response = await http.get(
      Uri.parse("$baseUrl/attendance/riwayat"),
      headers: {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode != 200) {
      throw Exception("Gagal mengambil riwayat absensi");
    }

    final data = jsonDecode(response.body);

    return data["data"] ?? [];
  }

  // ==========================
  // Kirim Absensi
  // ==========================
  Future<Map<String, dynamic>> attendance(
    File image,
    double latitude,
    double longitude,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final token = prefs.getString("token");

      var request = http.MultipartRequest(
        "POST",
        Uri.parse("$baseUrl/attendance"),
      );

      request.headers.addAll({
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      });

      request.fields["latitude"] = latitude.toString();
      request.fields["longitude"] = longitude.toString();

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

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class GuruService {
  static const String baseUrl = "http://192.168.1.14:8000/api";

  static Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token") ?? "";
    return {
      "Accept": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  static Future<Map<String, dynamic>> getKelasSaya() async {
    final response = await http.get(
      Uri.parse("$baseUrl/guru/kelas"),
      headers: await _headers(),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getKehadiranHariIni() async {
    final response = await http.get(
      Uri.parse("$baseUrl/guru/kehadiran-hari-ini"),
      headers: await _headers(),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getRiwayatSiswa(int siswaId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/guru/riwayat-siswa/$siswaId"),
      headers: await _headers(),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getKehadiranPerTanggal() async {
    final response = await http.get(
      Uri.parse("$baseUrl/guru/kehadiran-per-tanggal"),
      headers: await _headers(),
    );
    return jsonDecode(response.body);
  }
}
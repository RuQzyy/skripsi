import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

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

  static Future<Map<String, dynamic>> downloadLaporanAbsensi({
    required String bulanAwal,  // format: yyyy-MM
    required String bulanAkhir, // format: yyyy-MM
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          "$baseUrl/guru/laporan-absensi?bulan_awal=$bulanAwal&bulan_akhir=$bulanAkhir",
        ),
        headers: await _headers(),
      );

      if (response.statusCode == 200) {
        final dir = await getApplicationDocumentsDirectory();
        final fileName = "Rekap-Absensi-$bulanAwal-sd-$bulanAkhir.xlsx";
        final filePath = "${dir.path}/$fileName";
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        return {"success": true, "path": filePath};
      } else {
        // Response error dari Laravel biasanya JSON, coba parse untuk dapat pesan
        String message = "Gagal mengunduh laporan (${response.statusCode})";
        try {
          final data = jsonDecode(response.body);
          message = data["message"] ?? message;
        } catch (_) {}

        return {"success": false, "message": message};
      }
    } catch (e) {
      return {"success": false, "message": "Terjadi kesalahan: $e"};
    }
  }

}
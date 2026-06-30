import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/attendance_setting.dart';

class AttendanceService {

  static const String baseUrl =
      'http://192.168.1.14:8000/api';

  Future<AttendanceSetting> getSetting() async {

    final response = await http.get(
      Uri.parse(
        '$baseUrl/absensi-setting'
      ),
    );

    debugPrint(
      response.body,
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Gagal mengambil data pengaturan',
      );
    }

    final data = jsonDecode(
      response.body,
    );

    return AttendanceSetting.fromJson(
      data['data'],
    );
  }
}
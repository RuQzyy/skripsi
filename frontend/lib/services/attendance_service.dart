import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/attendance_setting.dart';
import 'local_db_service.dart';

class AttendanceService {
  static const String baseUrl = "http://192.168.1.48:8000/api";
  static const Uuid _uuid = Uuid();

  // Timeout untuk request absensi (upload foto + verifikasi wajah di
  // server). Dinaikkan dari 30 -> 60 detik karena proses face-matching
  // di server kadang butuh waktu lebih lama dari 30 detik, dan kalau
  // timeout terlalu ketat, request yang sebenarnya masih diproses server
  // bisa keliru dianggap "gagal total" di sisi Flutter.
  static const Duration _attendanceTimeout = Duration(seconds: 60);

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  /// Ambil id user yang sedang login dari SharedPreferences.
  ///
  /// PENTING: key "user_id" ini HARUS disimpan di AuthService saat login
  /// berhasil (bersamaan dengan "token"), misal:
  ///   await prefs.setInt("user_id", user["id"]);
  ///
  /// Kalau belum ada, sesuaikan key-nya dengan yang dipakai di project
  /// kamu. Ini wajib ada supaya antrian offline bisa dikaitkan ke user
  /// yang benar (lihat AttendanceQueueItem.userId).
  Future<int> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt("user_id");

    if (userId == null) {
      throw Exception(
          "user_id tidak ditemukan di SharedPreferences. Pastikan AuthService "
          "menyimpan user_id saat login berhasil.");
    }

    return userId;
  }

  /// ✅ tambahan: umur verifikasi waktu terakhir dalam detik, dikirim
  /// ke server di setiap request absensi. -1 berarti device belum
  /// pernah verifikasi NTP sama sekali sejak install (server boleh
  /// perlakukan ini sebagai kondisi paling tidak dipercaya).
  Future<String> _timeOffsetAgeField() async {
    final age = await LocalDbService.instance.getTimeOffsetAge();
    return (age?.inSeconds ?? -1).toString();
  }

  Future<AttendanceSetting> getSetting() async {
    try {
      final response = await http
          .get(Uri.parse("$baseUrl/absensi-setting"))
          .timeout(const Duration(seconds: 10));

      debugPrint(response.body);

      if (response.statusCode != 200) {
        throw Exception("Gagal mengambil data pengaturan");
      }

      final data = jsonDecode(response.body);
      final settingJson = data["data"] as Map<String, dynamic>;

      await LocalDbService.instance.saveCachedSetting(settingJson);
      await _maybeSaveServerTimeOffset(data, settingJson);

      return AttendanceSetting.fromJson(settingJson);
    } on SocketException catch (_) {
      return _fallbackToCachedSetting("Tidak ada koneksi internet");
    } on TimeoutException catch (_) {
      return _fallbackToCachedSetting("Waktu koneksi habis (timeout)");
    }
  }

  Future<void> _maybeSaveServerTimeOffset(
    Map<String, dynamic> data,
    Map<String, dynamic> settingJson,
  ) async {
    final serverTimeRaw = data["server_time"] ?? settingJson["server_time"];
    if (serverTimeRaw == null) return;

    final serverTime = DateTime.tryParse(serverTimeRaw.toString());
    if (serverTime == null) return;

    final offsetMs = serverTime.millisecondsSinceEpoch -
        DateTime.now().millisecondsSinceEpoch;
    await LocalDbService.instance.saveTimeOffset(offsetMs);
    debugPrint("[AttendanceService] Offset waktu server diperbarui: ${offsetMs}ms");
  }

  Future<AttendanceSetting> _fallbackToCachedSetting(String reason) async {
    final cached = await LocalDbService.instance.getCachedSetting();
    if (cached == null) {
      throw Exception(
          "$reason, dan belum ada data pengaturan tersimpan di HP ini.");
    }
    debugPrint("[AttendanceService] $reason, memakai cached setting.");
    return AttendanceSetting.fromJson(cached);
  }

  // ==========================
  // Cek Status Absensi Hari Ini
  // ==========================
  Future<Map<String, dynamic>?> getTodayAttendance() async {
    final token = await _getToken();

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
    final token = await _getToken();

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
  // Kirim Absensi Masuk
  // ==========================
  Future<Map<String, dynamic>> attendance(
    File image,
    double latitude,
    double longitude,
    double accuracy,
    String? wifiBssid, {
    bool isMocked = false,
  }) async {
    try {
      final token = await _getToken();

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
      request.fields["accuracy"] = accuracy.toString();
      request.fields["is_mocked"] = isMocked ? "1" : "0";
      request.fields["time_offset_age_seconds"] = await _timeOffsetAgeField(); // ✅ tambahan

      if (wifiBssid != null) {
        request.fields["wifi_bssid"] = wifiBssid;
      }

      request.files.add(
        await http.MultipartFile.fromPath("photo", image.path),
      );

      final response = await request.send().timeout(_attendanceTimeout);
      final body = await response.stream.bytesToString();
      return jsonDecode(body);
    } on SocketException catch (e) {
      // Beneran tidak ada koneksi internet -> aman disimpan ke antrian
      // offline, karena request ini dipastikan belum pernah sampai ke
      // server sama sekali.
      debugPrint("[AttendanceService] SocketException (masuk): $e");
      return _queueAndReport("masuk", image, latitude, longitude, accuracy,
          wifiBssid, isMocked);
    } on TimeoutException catch (e) {
      // Koneksi kemungkinan masih ada, tapi server terlalu lama merespons
      // (misal proses verifikasi wajah berat). JANGAN otomatis dimasukkan
      // ke antrian offline, karena request bisa saja sudah diterima dan
      // sedang diproses server -> kalau diqueue dan dikirim ulang lewat
      // sync, berisiko menghasilkan absensi dobel.
      debugPrint("[AttendanceService] TimeoutException (masuk): $e");
      return _timeoutResult();
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  // ==========================
  // Kirim Absensi Pulang
  // ==========================
  Future<Map<String, dynamic>> attendancePulang(
    File image,
    double latitude,
    double longitude,
    double accuracy,
    String? wifiBssid, {
    bool isMocked = false,
  }) async {
    try {
      final token = await _getToken();

      var request = http.MultipartRequest(
        "POST",
        Uri.parse("$baseUrl/attendance/pulang"),
      );

      request.headers.addAll({
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      });

      request.fields["latitude"] = latitude.toString();
      request.fields["longitude"] = longitude.toString();
      request.fields["accuracy"] = accuracy.toString();
      request.fields["is_mocked"] = isMocked ? "1" : "0";
      request.fields["time_offset_age_seconds"] = await _timeOffsetAgeField(); // ✅ tambahan

      if (wifiBssid != null) {
        request.fields["wifi_bssid"] = wifiBssid;
      }

      request.files.add(
        await http.MultipartFile.fromPath("photo", image.path),
      );

      final response = await request.send().timeout(_attendanceTimeout);
      final body = await response.stream.bytesToString();
      return jsonDecode(body);
    } on SocketException catch (e) {
      debugPrint("[AttendanceService] SocketException (pulang): $e");
      return _queueAndReport("pulang", image, latitude, longitude, accuracy,
          wifiBssid, isMocked);
    } on TimeoutException catch (e) {
      debugPrint("[AttendanceService] TimeoutException (pulang): $e");
      return _timeoutResult();
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  /// Hasil standar yang dikembalikan ketika request absensi timeout
  /// (bukan SocketException). UI (AttendancePage) bisa mengecek flag
  /// "timeout" untuk menampilkan pesan/perilaku yang berbeda dari
  /// kegagalan biasa, misalnya menawarkan "Coba Lagi" tanpa perlu foto
  /// ulang, alih-alih langsung menganggapnya sebagai data offline.
  Map<String, dynamic> _timeoutResult() {
    return {
      "success": false,
      "timeout": true,
      "message":
          "Server sedang lambat merespons (proses verifikasi wajah "
              "memakan waktu lama). Absensi BELUM tentu gagal sepenuhnya, "
              "silakan cek status absensi hari ini atau coba lagi.",
    };
  }

  Future<Map<String, dynamic>> _queueAndReport(
    String mode,
    File image,
    double latitude,
    double longitude,
    double accuracy,
    String? wifiBssid,
    bool isMocked,
  ) async {
    final item = await queueAttendance(
      mode: mode,
      image: image,
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      wifiBssid: wifiBssid,
      isMocked: isMocked,
    );
    return {
      "success": true,
      "queued": true,
      "message":
          "Tidak ada koneksi internet. Absensi disimpan dan akan otomatis "
              "terkirim saat HP kembali online.",
      "client_uuid": item.clientUuid,
      "captured_at": item.capturedAt.toIso8601String(),
    };
  }

  Future<AttendanceQueueItem> queueAttendance({
    required String mode, // "masuk" atau "pulang"
    required File image,
    required double latitude,
    required double longitude,
    required double accuracy,
    String? wifiBssid,
    bool isMocked = false,
  }) async {
    // WAJIB: setiap item antrian offline harus terikat ke user yang
    // sedang login, supaya tidak "nyasar" ke akun lain kalau device
    // dipakai bergantian (lihat local_db_service.dart -> user_id).
    final userId = await _getUserId();

    final savedPhotoPath = await _persistPhotoForQueue(image);
    final capturedAt = await LocalDbService.instance.getCorrectedNow();

    final item = AttendanceQueueItem(
      userId: userId,
      clientUuid: _uuid.v4(),
      mode: mode,
      photoPath: savedPhotoPath,
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      wifiBssid: wifiBssid,
      isMocked: isMocked,
      capturedAt: capturedAt,
    );

    final id = await LocalDbService.instance.insertQueueItem(item);
    debugPrint(
        "[AttendanceService] Absensi '$mode' disimpan ke antrian offline "
        "(id=$id, userId=$userId, uuid=${item.clientUuid}, capturedAt=$capturedAt).");

    return item;
  }

  Future<String> _persistPhotoForQueue(File image) async {
    final appDir = await getApplicationDocumentsDirectory();
    final queueDir = Directory(p.join(appDir.path, "attendance_queue_photos"));

    if (!await queueDir.exists()) {
      await queueDir.create(recursive: true);
    }

    final fileName =
        "${DateTime.now().millisecondsSinceEpoch}_${p.basename(image.path)}";
    final newPath = p.join(queueDir.path, fileName);

    final savedFile = await image.copy(newPath);
    return savedFile.path;
  }

  /// Kirim satu item antrian offline ke endpoint /attendance/sync.
  ///
  /// PENTING (fix): sebelumnya method ini HANYA meneruskan
  /// "success", "message", "sync_status" dari respons server -- field
  /// "rejected" (dan "spoof_detected") yang dikirim oleh
  /// AttendanceController::sync() saat data ditolak FINAL (jam
  /// absen/GPS/radius/WiFi/wajah tidak sesuai) TIDAK ikut diteruskan.
  /// Akibatnya SyncService tidak pernah bisa membedakan "ditolak
  /// final" dari "gagal teknis", dan semua kegagalan selalu jatuh ke
  /// status `failed` (di-retry terus-menerus).
  ///
  /// Sekarang field "rejected" & "spoof_detected" diteruskan apa
  /// adanya dari server, supaya SyncService bisa menandai item
  /// sebagai `rejected` (final, tidak di-retry) saat server memang
  /// menolaknya, dan `failed` (boleh di-retry) untuk kegagalan teknis
  /// biasa.
  Future<Map<String, dynamic>> syncAttendance(AttendanceQueueItem item) async {
    final token = await _getToken();

    final photoFile = File(item.photoPath);
    if (!await photoFile.exists()) {
      return {
        "success": false,
        "message":
            "File foto sudah tidak ditemukan di HP, tidak bisa disinkronkan.",
      };
    }

    var request = http.MultipartRequest(
      "POST",
      Uri.parse("$baseUrl/attendance/sync"),
    );

    request.headers.addAll({
      "Accept": "application/json",
      "Authorization": "Bearer $token",
    });

    request.fields["client_uuid"] = item.clientUuid;
    request.fields["type"] = item.mode;

    request.fields["tanggal"] =
        item.capturedAt.toIso8601String().split("T").first;

    request.fields["latitude"] = item.latitude.toString();
    request.fields["longitude"] = item.longitude.toString();

    request.fields["accuracy"] =
        item.accuracy.toString();

    request.fields["client_captured_at"] =
        item.capturedAt.toIso8601String();

    request.fields["is_mocked"] =
        item.isMocked ? "1" : "0";

    request.fields["time_offset_age_seconds"] = await _timeOffsetAgeField(); // ✅ tambahan

    if (item.wifiBssid != null) {
      request.fields["wifi_bssid"] = item.wifiBssid!;
    }

    request.files.add(
      await http.MultipartFile.fromPath("photo", item.photoPath),
    );

    // Pakai timeout yang sama dengan attendance biasa, karena proses
    // verifikasi wajah di server sama beratnya untuk request sync.
    final response = await request.send().timeout(_attendanceTimeout);
    final body = await response.stream.bytesToString();

    Map<String, dynamic> data;
    try {
      data = jsonDecode(body) as Map<String, dynamic>;
    } catch (e) {
      // Body bukan JSON valid (mis. HTML error page dari server/proxy,
      // 502/504, dsb) -> perlakukan sebagai kegagalan TEKNIS, boleh
      // di-retry, BUKAN sebagai penolakan data.
      debugPrint(
          "[AttendanceService] Gagal parse response sync "
          "(status ${response.statusCode}): $body");
      return {
        "success": false,
        "message":
            "Respons server tidak valid (status ${response.statusCode}).",
      };
    }

    return {
      "success": data["success"] == true,
      "message": data["message"],
      "sync_status": data["sync_status"] ?? "synced",
      // Diteruskan apa adanya dari server -> dipakai SyncService untuk
      // membedakan penolakan FINAL dari kegagalan teknis biasa.
      "rejected": data["rejected"] == true,
      "spoof_detected": data["spoof_detected"] == true,
    };
  }
}
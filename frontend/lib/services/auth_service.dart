import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = "http://192.168.1.48:8000/api";
  // static const String baseUrl = "http://10.170.1.37:8000/api";

  static String hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  /// Ambil user id dari payload user hasil login, dengan aman.
  ///
  /// Ditulis fleksibel karena field id dari API kadang berupa int,
  /// kadang berupa String tergantung serialisasi backend -> dua-duanya
  /// tetap bisa dikonversi jadi int di sini.
  static int? _extractUserId(Map<String, dynamic>? user) {
    if (user == null) return null;
    final rawId = user["id"];
    if (rawId == null) return null;

    if (rawId is int) return rawId;
    if (rawId is String) return int.tryParse(rawId);

    return null;
  }

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

        /// Hapus HANYA key sesi lama, bukan seluruh SharedPreferences.
        /// Kalau nanti aplikasi menyimpan data lain (tema, bahasa, cache
        /// absensi offline, dll), data itu TIDAK ikut hilang saat login.
        await prefs.remove("token");
        await prefs.remove("user");
        await prefs.remove("name");
        await prefs.remove("role");
        await prefs.remove("user_id");

        /// SIMPAN TOKEN
        await prefs.setString(
          "token",
          data["token"].toString(),
        );

        /// SIMPAN USER FULL
        final userJson = data["user"] as Map<String, dynamic>?;

        await prefs.setString(
          "user",
          jsonEncode(userJson),
        );

        /// SIMPAN DATA PENTING
        await prefs.setString(
          "name",
          (userJson?["name"] ?? "").toString(),
        );

        await prefs.setString(
          "role",
          (userJson?["role"] ?? "").toString(),
        );

        /// SIMPAN USER_ID
        ///
        /// WAJIB ada supaya AttendanceService, SyncService, dan
        /// DashboardPage bisa mengaitkan antrian absensi offline ke
        /// akun yang benar (lihat local_db_service.dart -> user_id).
        /// Tanpa ini, antrian offline tidak akan pernah tersimpan atau
        /// terbaca dengan benar.
        final userId = _extractUserId(userJson);

        if (userId == null) {
          print(
              "LOGIN WARNING: user.id tidak ditemukan/tidak valid pada response. "
              "Fitur absensi offline tidak akan berfungsi dengan benar sampai "
              "user login ulang dengan response yang menyertakan user.id.");
        } else {
          await prefs.setInt("user_id", userId);
        }

        await prefs.setString(
          "nisn_nip",
          nisnNip,
        );

        await prefs.setString(
          "password_hash",
          hashPassword(password),
        );

        await prefs.setBool(
          "offline_login",
          true,
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
    } on SocketException catch (_) {
      // Tidak ada koneksi internet sama sekali -> baru dianggap layak
      // dicoba login offline.
      SharedPreferences prefs = await SharedPreferences.getInstance();

      bool pernahLogin = prefs.getBool("offline_login") ?? false;

      String? savedNisn = prefs.getString("nisn_nip");

      String? savedHash = prefs.getString("password_hash");

      // Catatan: user_id TIDAK perlu di-set ulang di sini. Karena login
      // offline hanya diizinkan untuk akun yang SAMA dengan login online
      // terakhir (dicek lewat savedNisn & savedHash di bawah), user_id
      // hasil login online sebelumnya sudah tersimpan dan tetap valid
      // dipakai selama sesi offline ini.
      if (pernahLogin &&
          savedNisn == nisnNip &&
          savedHash == hashPassword(password)) {
        return {
          "success": true,
          "offline": true,
          "message": "Login Offline",
        };
      }

      return {
        "success": false,
        "message":
            "Tidak ada koneksi internet atau akun belum pernah login.",
      };
    } catch (e) {
      // Error selain masalah koneksi (server error 500, JSON tidak valid,
      // format response berubah, dll) -> JANGAN otomatis dianggap offline,
      // tampilkan sebagai error biasa supaya tidak menyesatkan user.
      print("LOGIN ERROR (bukan SocketException): $e");

      return {
        "success": false,
        "message": "Terjadi kesalahan saat login: ${e.toString()}",
      };
    }
  }

  /// ================= LOGOUT =================
  /// PENTING: logout TIDAK boleh menghapus seluruh SharedPreferences,
  /// karena akan menghilangkan kemampuan login offline (password_hash,
  /// nisn_nip, offline_login, user, user_id). Cukup hapus token & role
  /// saja, supaya sesi server dianggap berakhir tapi login offline tetap
  /// bisa dipakai berikutnya.
  ///
  /// user_id SENGAJA TIDAK dihapus di sini (sama seperti "user" dan
  /// "nisn_nip") karena:
  /// 1. Semua query antrian absensi di LocalDbService sudah difilter
  ///    berdasarkan user_id, jadi menyimpannya tetap aman walau user
  ///    sedang logged out.
  /// 2. Kalau dihapus, login offline berikutnya (yang tidak mendapat
  ///    response server baru) tidak akan punya user_id untuk dipakai
  ///    AttendanceService/SyncService/DashboardPage, sehingga fitur
  ///    absensi offline langsung rusak setelah logout+login offline.
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

      /// Hapus hanya sesi aktif (token & role), JANGAN clear() semuanya.
      /// password_hash, nisn_nip, offline_login, user, user_id tetap
      /// disimpan supaya login offline masih bisa dipakai setelah logout.
      await prefs.remove("token");
      await prefs.remove("role");

      return true;
    } catch (e) {
      print("ERROR LOGOUT : $e");

      // Tetap hapus token & role saja walau request logout ke server gagal
      // (misal karena offline), bukan clear() semuanya.
      await prefs.remove("token");
      await prefs.remove("role");

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

  /// ================= GET USER ID =================
  /// Dipakai AttendanceService, SyncService, dan DashboardPage untuk
  /// mengaitkan/menyaring antrian absensi offline milik user yang
  /// sedang aktif (baik login online maupun login offline).
  static Future<int?> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    return prefs.getInt("user_id");
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

        // Jaga-jaga: kalau id user berubah/baru pertama kali tersedia
        // lewat endpoint /me, ikut sinkronkan user_id supaya antrian
        // offline tetap konsisten.
        final userMap = user is Map<String, dynamic> ? user : null;
        final userId = _extractUserId(userMap);
        if (userId != null) {
          await prefs.setInt("user_id", userId);
        }

        return user;
      }

      return null;
    } catch (e) {
      print("FETCH USER ERROR : $e");
      return null;
    }
  }

  /// ================= CHECK LOGIN =================
  /// Dipakai untuk menentukan apakah user boleh masuk tanpa perlu
  /// koneksi ke server. Cukup cek flag offline_login yang diset saat
  /// login online pertama kali berhasil — bukan cek keberadaan token,
  /// karena token bisa saja sudah tidak valid / tidak bisa diverifikasi
  /// saat offline.
  static Future<bool> isLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    return prefs.getBool("offline_login") ?? false;
  }

  /// ================= SEND OTP =================
  static Future<Map<String, dynamic>> sendOtp(String email) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/forgot-password/send-otp"),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({"email": email}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  /// ================= VERIFY OTP =================
  static Future<Map<String, dynamic>> verifyOtp(
    String email,
    String otp,
  ) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/forgot-password/verify-otp"),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({"email": email, "otp": otp}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  /// ================= RESET PASSWORD =================
  static Future<Map<String, dynamic>> resetPassword(
    String email,
    String otp,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/forgot-password/reset"),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({
          "email": email,
          "otp": otp,
          "password": password,
        }),
      );

      final data = jsonDecode(response.body);

      // Kalau reset berhasil, hash lokal juga harus ikut diperbarui,
      // karena reset password juga bisa dilakukan oleh user yang sudah
      // pernah login offline sebelumnya.
      if (response.statusCode == 200 && (data["success"] == true)) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        final savedNisn = prefs.getString("nisn_nip");

        if (savedNisn != null) {
          await prefs.setString(
            "password_hash",
            hashPassword(password),
          );
        }
      }

      return data;
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }

  /// ================= UPDATE PHOTO =================
  static Future<Map<String, dynamic>> updatePhoto(String imagePath) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String? token = prefs.getString("token");

    try {
      var request = http.MultipartRequest(
        "POST",
        Uri.parse("$baseUrl/update-photo"),
      );

      request.headers.addAll({
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      });

      request.files.add(
        await http.MultipartFile.fromPath("photo", imagePath),
      );

      final response = await request.send();
      final body = await response.stream.bytesToString();
      final data = jsonDecode(body);

      return data;
    } catch (e) {
      return {
        "success": false,
        "message": e.toString(),
      };
    }
  }

  /// ================= UPDATE PASSWORD =================
  /// PENTING: setelah password berhasil diganti di server, hash lokal
  /// (password_hash) WAJIB ikut diperbarui. Kalau tidak, login offline
  /// akan tetap mencocokkan ke password LAMA dan selalu gagal setelah
  /// user mengganti password lalu offline.
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
        await prefs.setString(
          "password_hash",
          hashPassword(password),
        );

        return true;
      }

      return false;
    } catch (e) {
      print("UPDATE PASSWORD ERROR : $e");

      return false;
    }
  }
}
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:safe_device/safe_device.dart';
import 'package:ntp/ntp.dart'; // ✅ tambahan: untuk ambil waktu server (NTP) guna deteksi manipulasi tanggal/jam perangkat
import '../services/auth_service.dart';
import '../pages/login_page.dart';
import '../models/pengumuman_model.dart';
import '../services/pengumuman_service.dart';
import '../pages/pengumuman_page.dart';
import '../pages/detail_pengumuman_page.dart';
import '../models/attendance_setting.dart';
import '../services/attendance_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../pages/attendance_page.dart';
import '../services/sync_service.dart';
import '../services/local_db_service.dart';
import 'sync_progress_overlay.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import '../utils/page_transition.dart';
import 'profile_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  double? userLatitude;
  double? userLongitude;
  double? userAccuracy;
  double distance = 0;
  bool canAttendance = false;
  Map<String, dynamic>? todayAttendance;
  bool isLoadingTodayAttendance = true;
  List<dynamic> riwayatList = [];
  bool isLoadingRiwayat = true;
  String formattedDate = "";
  String name = "";
  AttendanceSetting? setting;
  bool isLoadingSetting = true;
  bool isLoadingLocation = true;
  List<Pengumuman> pengumumanList = [];
  AttendanceQueueItem? queueMasukHariIni;
  AttendanceQueueItem? queuePulangHariIni;

  // ✅ tambahan: item antrian yang FINAL DITOLAK server hari ini.
  // Dipakai untuk menampilkan banner "Absensi Ditolak" beserta alasannya,
  // TERPISAH dari queueMasukHariIni/queuePulangHariIni (yang sekarang
  // sudah tidak lagi berisi item rejected, lihat local_db_service.dart).
  AttendanceQueueItem? rejectedMasukHariIni;
  AttendanceQueueItem? rejectedPulangHariIni;

  bool isLoadingPengumuman = true;

  // ✅ tambahan
  Timer? _clockTimer;
  bool isFakeGpsDetected = false;

  // ✅ tambahan: guard supaya dialog "Akses Ditolak" (developer mode /
  // fake GPS / tanggal dimanipulasi) tidak muncul berkali-kali kalau ada
  // beberapa pemicu yang mendeteksi hal yang sama secara bersamaan.
  bool _securityDialogShown = false;

  // ✅ tambahan: status & timer untuk pengecekan manipulasi tanggal/jam
  // perangkat (lihat _checkDeviceDateTime()).
  bool isDateTimeManipulated = false;
  Timer? _dateCheckTimer;

  // Toleransi selisih antara jam perangkat dan jam server (NTP).
  // Diberi sedikit ruang untuk latensi jaringan / jam server yang tidak
  // 100% presisi, tapi cukup ketat untuk menangkap user yang sengaja
  // mengubah tanggal/jam HP.
  static const Duration _maxAllowedTimeDrift = Duration(minutes: 3);

  // ==========================================================
  // USER ID (dipakai untuk filter antrian offline milik user ini saja)
  // ==========================================================
  /// Ambil id user yang sedang login dari SharedPreferences.
  ///
  /// PENTING: key "user_id" ini harus sudah disimpan oleh AuthService
  /// saat login berhasil (sejajar dengan "token"). Kalau null berarti
  /// belum ada user login / sesi bermasalah -> fungsi pemanggil harus
  /// menangani dengan aman (skip filter antrian, bukan pakai id 0).
  Future<int?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt("user_id");
  }

  // ==========================================================
  // ✅ tambahan: KEAMANAN PERANGKAT
  // Cek Developer Mode & Fake GPS. Kalau salah satu aktif, tampilkan
  // dialog peringatan yang tidak bisa ditutup lalu paksa keluar dari
  // aplikasi. Dipanggil sekali saat dashboard dibuka (initState), dan
  // hasil deteksi fake GPS dari getCurrentLocation() juga memicu jalur
  // yang sama supaya perilakunya konsisten di seluruh halaman.
  // ==========================================================
  Future<void> _checkDeviceSecurity() async {
    // Deteksi ini spesifik Android (Developer Options & Mock Location
    // provider adalah konsep Android). Di iOS, safe_device akan
    // otomatis mengembalikan false untuk isDevelopmentModeEnable, jadi
    // tetap aman dipanggil di semua platform.
    try {
      final bool devMode = await SafeDevice.isDevelopmentModeEnable;
      final bool mockLocation = await SafeDevice.isMockLocation;

      if (!mounted) return;

      if (devMode || mockLocation) {
        _showSecurityViolationDialog(
          devMode: devMode,
          mockLocation: mockLocation,
        );
      }
    } catch (e) {
      // Kalau plugin gagal mendeteksi (mis. platform tidak didukung),
      // jangan blokir user karena kesalahan deteksi bukan pelanggaran.
      print("Gagal cek keamanan perangkat: $e");
    }
  }

  // ==========================================================
  // ✅ tambahan: KEAMANAN TANGGAL / JAM PERANGKAT
  // Bandingkan jam perangkat dengan waktu server asli (via NTP, bukan
  // jam perangkat itu sendiri) untuk mendeteksi user yang sengaja
  // mengubah tanggal/jam HP -- misalnya memundurkan tanggal supaya jam
  // absen belum dianggap "terlambat"/"expired", atau mengubah tanggal
  // untuk mengelabui validasi jendela waktu absen lainnya.
  //
  // Kalau selisihnya melebihi toleransi (_maxAllowedTimeDrift),
  // perlakukan PERSIS seperti Developer Mode / Fake GPS: tampilkan
  // dialog "Akses Ditolak" yang tidak bisa ditutup lalu paksa keluar
  // dari aplikasi (lewat _showSecurityViolationDialog & _exitApp).
  //
  // Dipanggil sekali saat dashboard dibuka (initState) DAN diulang
  // secara periodik (_dateCheckTimer) supaya kalau user mengubah
  // tanggal SETELAH dashboard terbuka, tetap ketahuan tanpa harus
  // menutup-buka ulang aplikasi.
  // ==========================================================
  Future<void> _checkDeviceDateTime() async {
    try {
      final DateTime networkTime = await NTP.now(
        lookUpAddress: "pool.ntp.org",
      ).timeout(const Duration(seconds: 6));

      final DateTime deviceTime = DateTime.now();
      final Duration drift = deviceTime.difference(networkTime).abs();

      print(
          "Cek waktu perangkat vs server (NTP) -> selisih: ${drift.inSeconds} detik");

      if (!mounted) return;

      if (drift > _maxAllowedTimeDrift) {
        setState(() => isDateTimeManipulated = true);

        _showSecurityViolationDialog(
          devMode: false,
          mockLocation: false,
          dateMismatch: true,
        );
      } else {
        // ✅ tambahan: setiap kali NTP berhasil DAN driftnya wajar,
        // simpan offset + timestamp verifikasi ini ke LocalDbService.
        // Ini jadi acuan getCorrectedNow() untuk antrian offline, dan
        // acuan time_offset_age_seconds yang dikirim ke server saat
        // sync nanti.
        final offsetMs = networkTime.difference(deviceTime).inMilliseconds;
        await LocalDbService.instance.saveTimeOffset(offsetMs);

        if (isDateTimeManipulated) {
          setState(() => isDateTimeManipulated = false);
        }
      }
    } catch (e) {
      // Kalau gagal ambil waktu server (mis. tidak ada koneksi
      // internet / NTP server tidak terjangkau), JANGAN blokir user,
      // karena kegagalan pengecekan bukan berarti tanggal dimanipulasi.
      print("Gagal cek tanggal/jam perangkat: $e");
    }
  }

  void _showSecurityViolationDialog({
    required bool devMode,
    required bool mockLocation,
    bool dateMismatch = false, // ✅ tambahan
  }) {
    if (_securityDialogShown || !mounted) return;
    _securityDialogShown = true;

    // ✅ tambahan: kumpulkan semua pelanggaran yang terdeteksi supaya
    // kalau kebetulan lebih dari satu terjadi bersamaan, semua alasan
    // tetap ditampilkan ke user dalam satu dialog yang sama.
    final List<String> reasons = [];
    if (devMode) {
      reasons.add(
          "Mode Pengembang (Developer Mode) terdeteksi aktif di perangkat Anda.");
    }
    if (mockLocation) {
      reasons.add("Lokasi palsu (Fake GPS) terdeteksi aktif di perangkat Anda.");
    }
    if (dateMismatch) {
      reasons.add(
          "Tanggal/jam perangkat Anda tidak sesuai dengan waktu server.");
    }

    final String message = reasons.isEmpty
        ? "Pelanggaran keamanan terdeteksi di perangkat Anda."
        : reasons.join("\n\n");

    // ✅ tambahan: instruksi penyelesaian disesuaikan kasusnya. Kalau
    // yang bermasalah HANYA tanggal/jam, arahkan user untuk membetulkan
    // tanggal & jam (bukan disuruh "nonaktifkan pengaturan" yang
    // membingungkan untuk kasus ini).
    final String instruction = (dateMismatch && !devMode && !mockLocation)
        ? "Untuk alasan keamanan, aplikasi tidak dapat digunakan. "
            "Silahkan atur tanggal & jam perangkat Anda secara otomatis "
            "(sesuai zona waktu jaringan), lalu buka ulang aplikasi."
        : "Untuk alasan keamanan, aplikasi tidak dapat digunakan. "
            "Nonaktifkan pengaturan tersebut dan/atau betulkan tanggal & jam "
            "perangkat Anda, lalu buka ulang aplikasi.";

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return PopScope(
          // Blokir tombol back Android supaya dialog tidak bisa
          // ditutup tanpa menekan "Keluar Aplikasi".
          canPop: false,
          child: AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.gpp_bad, color: Colors.red),
                SizedBox(width: 8),
                Expanded(child: Text("Akses Ditolak")),
              ],
            ),
            content: Text("$message\n\n$instruction"),
            actions: [
              ElevatedButton(
                onPressed: _exitApp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.mediumDark,
                  foregroundColor: Colors.white,
                ),
                child: const Text("Keluar Aplikasi"),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Menutup aplikasi sepenuhnya.
  ///
  /// SystemNavigator.pop() adalah cara yang direkomendasikan Flutter
  /// (menghapus app dari task stack, setara menekan tombol back di
  /// halaman root). exit(0) dipakai sebagai fallback paksa kalau
  /// SystemNavigator.pop() tidak cukup (mis. di sebagian device Android
  /// custom ROM aplikasi kadang masih hidup di background).
  void _exitApp() {
    SystemNavigator.pop();

    // Fallback: paksa hentikan proses setelah jeda singkat kalau
    // SystemNavigator.pop() saja tidak benar-benar menutup aplikasi.
    Future.delayed(const Duration(milliseconds: 500), () {
      exit(0);
    });
  }

  // ==========================================================
  // LOKASI
  // ==========================================================
  Future getCurrentLocation() async {
    print("1. Mulai ambil lokasi");

    setState(() => isLoadingLocation = true);

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    print("2. Service : $serviceEnabled");

    if (!serviceEnabled) {
      print("Service mati");
      if (mounted) setState(() => isLoadingLocation = false);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    print("3. Permission awal : $permission");

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      print("4. Permission setelah request : $permission");

      if (permission == LocationPermission.denied) {
        print("Permission tetap ditolak setelah diminta");
        if (mounted) setState(() => isLoadingLocation = false);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print("Permission ditolak permanen");
      setState(() => isLoadingLocation = false);
      return;
    }

    // Tampilkan posisi terakhir dulu (instan) sambil menunggu posisi presisi
    try {
      Position? lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null && mounted) {
        setState(() {
          userLatitude = lastKnown.latitude;
          userLongitude = lastKnown.longitude;
          userAccuracy = lastKnown.accuracy;
        });
        calculateDistance();
      }
    } catch (_) {}

    Position position;
    try {
      position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 8),
      );
    } catch (e) {
      print("Timeout/error ambil lokasi presisi: $e");
      setState(() => isLoadingLocation = false);
      calculateDistance(); // tetap pakai lastKnown sebagai fallback
      return;
    }

    print("5. Latitude : ${position.latitude}");
    print("6. Longitude : ${position.longitude}");
    print("7. Is Mocked : ${position.isMocked}");

    if (position.isMocked) {
      setState(() {
        canAttendance = false;
        isLoadingLocation = false;
        isFakeGpsDetected = true;
      });

      // ✅ tambahan: fake GPS yang terdeteksi langsung dari posisi GPS
      // (position.isMocked) sekarang diarahkan ke jalur yang sama
      // dengan pengecekan awal (dialog "Akses Ditolak" + keluar app),
      // bukan cuma snackbar seperti sebelumnya.
      if (mounted) {
        _showSecurityViolationDialog(devMode: false, mockLocation: true);
      }
      return;
    }

    setState(() {
      userLatitude = position.latitude;
      userLongitude = position.longitude;
      userAccuracy = position.accuracy;
      isLoadingLocation = false;
      isFakeGpsDetected = false;
    });

    calculateDistance();
  }

  void calculateDistance() {
    if (setting == null || userLatitude == null || userLongitude == null) {
      return;
    }

    double meter = Geolocator.distanceBetween(
      userLatitude!,
      userLongitude!,
      setting!.latitude,
      setting!.longitude,
    );

    const double maxAccuracyBuffer = 10;
    final double buffer = (userAccuracy ?? 0).clamp(0, maxAccuracyBuffer);
    bool allowed = (meter - buffer) <= setting!.radius;

    print("===== ABSENSI =====");
    print("Latitude User : $userLatitude");
    print("Longitude User : $userLongitude");
    print("Jarak : $meter");
    print("Radius : ${setting!.radius}");
    print("Boleh Absen : $allowed");

    setState(() {
      distance = meter;
      canAttendance = allowed;
    });
  }

  // ==========================================================
  // Helper cek waktu (dibanding jam sekarang)
  // ==========================================================
  bool _isTimeAfter(String settingTime) {
    final now = DateTime.now();
    final p = settingTime.split(":");
    final target = DateTime(
      now.year, now.month, now.day,
      int.parse(p[0]), int.parse(p[1]), p.length > 2 ? int.parse(p[2]) : 0,
    );
    return now.isAfter(target);
  }

  bool _isTimeBefore(String settingTime) {
    final now = DateTime.now();
    final p = settingTime.split(":");
    final target = DateTime(
      now.year, now.month, now.day,
      int.parse(p[0]), int.parse(p[1]), p.length > 2 ? int.parse(p[2]) : 0,
    );
    return now.isBefore(target);
  }

  bool get isAbsenMasukExpired =>
      setting != null &&
      todayAttendance == null &&
      _isTimeAfter(setting!.jamSelesai);

  bool get isPulangWindowOpen =>
      setting != null &&
      _isTimeAfter(setting!.jamPulangMulai) &&
      _isTimeBefore(setting!.jamPulangSelesai);

  Future<void> loadSetting() async {
    final result = await AttendanceService().getSetting();

    setState(() {
      setting = result;
      isLoadingSetting = false;
    });

    getCurrentLocation();
  }

  Future<void> getUser() async {
    final user = await AuthService.getUser();

    setState(() {
      name = user?["name"] ?? "";
    });
  }

  // ==========================================================
  // TODAY ATTENDANCE (gabungan server + antrian lokal)
  // ==========================================================
  Future<void> getTodayAttendance() async {
    try {
      final result = await AttendanceService().getTodayAttendance();
      setState(() {
        todayAttendance = result;
        isLoadingTodayAttendance = false;
      });
    } catch (e) {
      setState(() {
        isLoadingTodayAttendance = false;
      });
    }

    // Selalu cek antrian lokal juga, terlepas server berhasil atau tidak.
    // WAJIB difilter per user_id supaya antrian offline milik akun lain
    // (misal sisa dari device yang dipakai bergantian) tidak pernah
    // ikut tampil di sini.
    final userId = await _getUserId();

    if (userId == null) {
      // Tidak ada user login yang valid -> jangan tampilkan antrian
      // apa pun daripada salah menampilkan milik orang lain.
      if (!mounted) return;
      setState(() {
        queueMasukHariIni = null;
        queuePulangHariIni = null;
        rejectedMasukHariIni = null;
        rejectedPulangHariIni = null;
      });
      return;
    }

    // qMasuk/qPulang sekarang sudah TIDAK berisi item berstatus
    // "rejected" (lihat fix di LocalDbService.getTodayQueueItem), jadi
    // begitu server menolak absensi offline, item ini otomatis
    // menghilang dari sini -> todayAttendance tidak lagi "terkunci" ke
    // status Hadir, dan tombol "Lakukan Absensi" bisa muncul lagi
    // selama jam absensi masih berlaku.
    final qMasuk =
        await LocalDbService.instance.getTodayQueueItem(userId, "masuk");
    final qPulang =
        await LocalDbService.instance.getTodayQueueItem(userId, "pulang");

    // Ambil terpisah item yang FINAL DITOLAK hari ini, khusus untuk
    // ditampilkan sebagai banner "Absensi Ditolak" + alasannya.
    final rMasuk =
        await LocalDbService.instance.getTodayRejectedItem(userId, "masuk");
    final rPulang =
        await LocalDbService.instance.getTodayRejectedItem(userId, "pulang");

    if (!mounted) return;
    setState(() {
      queueMasukHariIni = qMasuk;
      queuePulangHariIni = qPulang;
      rejectedMasukHariIni = rMasuk;
      rejectedPulangHariIni = rPulang;

      if (qMasuk != null) {
        todayAttendance ??= {
          "jam_masuk": qMasuk.capturedAt.toIso8601String().substring(11, 19),
          "status": "Hadir",
        };

        // Selalu timpa jam_keluar dari queue kalau ada, supaya absen
        // pulang offline tidak hilang walau server sudah punya jam_masuk.
        if (qPulang != null) {
          todayAttendance!["jam_keluar"] =
              qPulang.capturedAt.toIso8601String().substring(11, 19);
        }
      }
    });
  }

  Future<void> getRiwayatAttendance() async {
    try {
      final result = await AttendanceService().getRiwayatAttendance();

      setState(() {
        riwayatList = result;
        isLoadingRiwayat = false;
      });
    } catch (e) {
      setState(() {
        isLoadingRiwayat = false;
      });
    }
  }

  Future<void> getPengumuman() async {
    try {
      final result = await PengumumanService.getPengumuman(limit: 3);

      List<Pengumuman> data = result["data"];

      setState(() {
        pengumumanList = data;
        isLoadingPengumuman = false;
      });
    } catch (e) {
      setState(() {
        isLoadingPengumuman = false;
      });
    }
  }

  Future getAttendanceSetting() async {
    getCurrentLocation();

    try {
      final result = await AttendanceService().getSetting();

      setState(() {
        setting = result;
        isLoadingSetting = false;
      });

      calculateDistance();
    } catch (e) {
      setState(() {
        isLoadingSetting = false;
      });
    }
  }

  void logout() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Konfirmasi"),
          content: const Text("Apakah anda ingin keluar?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text("Batal"),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);

                bool success = await AuthService.logout();

                if (!mounted) return;

                if (success) {
                  // Pastikan badge sinkronisasi ikut ter-reset ke 0
                  // begitu user ini logout, bukan menunggu timer
                  // periodik berikutnya.
                  await SyncService.instance.refreshPendingCount();

                  if (!mounted) return;

                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                    (route) => false,
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Logout gagal")));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.mediumDark,
                foregroundColor: Colors.white,
              ),
              child: const Text("Keluar"),
            ),
          ],
        );
      },
    );
  }

  // ==========================================================
  // LIFECYCLE
  // ==========================================================
  @override
  void initState() {
    super.initState();

    SyncService.instance.pendingCount.addListener(_onSyncCountChanged);

    // Pastikan badge & antrian langsung mencerminkan user yang baru
    // login saat dashboard ini pertama kali dibuka.
    SyncService.instance.refreshPendingCount();
    SyncService.instance.syncNow();

    // ✅ tambahan: cek Developer Mode / Fake GPS begitu dashboard dibuka.
    _checkDeviceSecurity();

    // ✅ tambahan: cek manipulasi tanggal/jam perangkat begitu dashboard
    // dibuka, lalu ulangi secara periodik supaya perubahan tanggal yang
    // dilakukan SETELAH dashboard terbuka tetap terdeteksi.
    _checkDeviceDateTime();
    _dateCheckTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      _checkDeviceDateTime();
    });

    initializeDate();
    getUser();
    getPengumuman();
    getAttendanceSetting();
    getTodayAttendance();
    getRiwayatAttendance();

    _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted) return;
      setState(() {
        formattedDate = DateFormat(
          "EEEE, dd MMMM yyyy\nHH:mm",
          "id_ID",
        ).format(DateTime.now());
      });
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _dateCheckTimer?.cancel(); // ✅ tambahan
    SyncService.instance.pendingCount.removeListener(_onSyncCountChanged);
    super.dispose();
  }

  void _onSyncCountChanged() {
    getTodayAttendance();
    getRiwayatAttendance();
  }

  Future<void> initializeDate() async {
    await initializeDateFormatting('id_ID', null);
    setState(() {
      formattedDate = DateFormat(
        "EEEE, dd MMMM yyyy\nHH:mm",
        "id_ID",
      ).format(DateTime.now());
    });
  }

  bool isAbsensi = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightest,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
              // ================= BANNER ONLINE/OFFLINE (tambahan) =================
              ValueListenableBuilder<bool>(
                valueListenable: SyncService.instance.isOnline,
                builder: (_, online, __) {
                  return Container(
                    width: double.infinity,
                    color: online ? Colors.green.shade600 : Colors.red.shade600,
                    padding:
                        const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                    child: Row(
                      children: [
                        Icon(online ? Icons.wifi : Icons.wifi_off,
                            color: Colors.white, size: 14),
                        const SizedBox(width: 8),
                        Text(
                          online
                              ? "Online"
                              : "Offline — absensi disimpan sementara",
                          style:
                              const TextStyle(color: Colors.white, fontSize: 11),
                        ),
                      ],
                    ),
                  );
                },
              ),

              // ================= BANNER SINKRONISASI (tambahan) =================
              ValueListenableBuilder<int>(
                valueListenable: SyncService.instance.pendingCount,
                builder: (_, count, __) {
                  if (count == 0) return const SizedBox();
                  return Container(
                    width: double.infinity,
                    color: Colors.orange.shade600,
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: Row(
                      children: [
                        const Icon(Icons.cloud_upload_outlined,
                            color: Colors.white, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "$count absensi menunggu sinkronisasi",
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => SyncService.instance.syncNow(),
                          child: const Text(
                            "Sync",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              // ================= BANNER ABSENSI DITOLAK (tambahan) =================
              // Tampil kalau ada item absen masuk dan/atau pulang hari ini
              // yang FINAL ditolak server (fake GPS, di luar radius, wajah
              // tidak cocok, dsb). Menampilkan alasan penolakan supaya user
              // tahu apa yang perlu diperbaiki sebelum absen ulang.
              if (rejectedMasukHariIni != null || rejectedPulangHariIni != null)
                Container(
                  width: double.infinity,
                  color: Colors.red.shade700,
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (rejectedMasukHariIni != null)
                        _rejectedBannerLine(
                          label: "Absen Masuk Ditolak",
                          item: rejectedMasukHariIni!,
                        ),
                      if (rejectedMasukHariIni != null &&
                          rejectedPulangHariIni != null)
                        const SizedBox(height: 6),
                      if (rejectedPulangHariIni != null)
                        _rejectedBannerLine(
                          label: "Absen Pulang Ditolak",
                          item: rejectedPulangHariIni!,
                        ),
                    ],
                  ),
                ),

              // ================= WAKTU SINKRONISASI TERAKHIR (tambahan) =================
              ValueListenableBuilder<DateTime?>(
                valueListenable: SyncService.instance.lastSyncedAt,
                builder: (_, last, __) {
                  if (last == null) return const SizedBox();
                  final diff = DateTime.now().difference(last);
                  String text;
                  if (diff.inSeconds < 60) {
                    text = "Baru saja";
                  } else if (diff.inMinutes < 60) {
                    text = "${diff.inMinutes} menit lalu";
                  } else {
                    text = DateFormat("HH:mm").format(last);
                  }
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Sinkronisasi terakhir: $text",
                        style:
                            const TextStyle(color: Colors.black45, fontSize: 10),
                      ),
                    ),
                  );
                },
              ),

              /// ================= HEADER + CARD ABSENSI =================
              Column(
                children: [
                  /// ================= HEADER HIJAU =================
                  Container(
                    height: 230,
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.darkest,
                          AppColors.mediumDark,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Hallo $name",
                              style: const TextStyle(color: Colors.white70),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.notifications_none,
                                      color: Colors.white),
                                  onPressed: () {},
                                ),
                                IconButton(
                                  icon: const Icon(Icons.logout,
                                      color: Colors.white),
                                  onPressed: () {
                                    logout();
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Silahkan Melakukan Absensi",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),

                  /// ================= CARD PUTIH =================
                  Transform.translate(
                    offset: const Offset(0, -100),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.darkest.withOpacity(0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          /// ================= TAB =================
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    isAbsensi = true;
                                  });
                                },
                                child: Column(
                                  children: [
                                    Text(
                                      "Absensi",
                                      style: TextStyle(
                                        fontWeight: isAbsensi
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                    if (isAbsensi)
                                      const SizedBox(
                                        width: 40,
                                        child: Divider(
                                          thickness: 2,
                                          color: AppColors.darkest,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    isAbsensi = false;
                                  });
                                },
                                child: Column(
                                  children: [
                                    Text(
                                      "Riwayat Absensi",
                                      style: TextStyle(
                                        fontWeight: !isAbsensi
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                    if (!isAbsensi)
                                      const SizedBox(
                                        width: 70,
                                        child: Divider(
                                          thickness: 2,
                                          color: AppColors.darkest,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),
                          const Divider(),

                          /// ================= ISI CARD (DINAMIS) =================
                          if (isLoadingSetting)
                            const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.mediumDark,
                              ),
                            )
                          else if (setting == null)
                            const Center(
                              child: Text(
                                "Gagal memuat data absensi",
                              ),
                            )
                          else
                            isAbsensi
                                ? _absensiView(
                                    context,
                                    setting!,
                                    canAttendance,
                                    todayAttendance,
                                    isLoadingLocation,
                                    isAbsenMasukExpired,
                                    isPulangWindowOpen,
                                    queueMasukHariIni,
                                    queuePulangHariIni,
                                    () {
                                      getTodayAttendance();
                                      getRiwayatAttendance();
                                    },
                                  )
                                : _riwayatView(
                                    riwayatList, isLoadingRiwayat, context)
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              /// ================= DATE CARD =================
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.mediumDark,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    formattedDate.isEmpty ? "Loading..." : formattedDate,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              /// ================= PENGUMUMAN =================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Pengumuman",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.darkest,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PengumumanPage(),
                          ),
                        );
                      },
                      child: const Text(
                        "Lihat Semua",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                height: 210,
                child: isLoadingPengumuman
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.mediumDark,
                        ),
                      )
                    : pengumumanList.isEmpty
                        ? const Center(
                            child: Text("Belum ada pengumuman"),
                          )
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.only(left: 20),
                            itemCount: pengumumanList.length,
                            itemBuilder: (context, index) {
                              final pengumuman = pengumumanList[index];

                              return Container(
                                width: 260,
                                margin: const EdgeInsets.only(right: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          AppColors.darkest.withOpacity(0.05),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    /// ================= GAMBAR =================
                                    ClipRRect(
                                      borderRadius:
                                          const BorderRadius.vertical(
                                        top: Radius.circular(18),
                                      ),
                                      child: Image.network(
                                        pengumuman.foto,
                                        height: 120,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        loadingBuilder:
                                            (context, child, loadingProgress) {
                                          if (loadingProgress == null)
                                            return child;

                                          return Container(
                                            height: 120,
                                            alignment: Alignment.center,
                                            child:
                                                const CircularProgressIndicator(
                                              color: AppColors.mediumDark,
                                            ),
                                          );
                                        },
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Container(
                                            height: 120,
                                            color: AppColors.light
                                                .withOpacity(0.3),
                                            alignment: Alignment.center,
                                            child: Icon(
                                              Icons.image_not_supported,
                                              color: AppColors.medium,
                                            ),
                                          );
                                        },
                                      ),
                                    ),

                                    Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          /// ================= JUDUL =================
                                          Text(
                                            pengumuman.judul,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.darkest,
                                            ),
                                          ),

                                          const SizedBox(height: 8),

                                          /// ================= BUTTON =================
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: SizedBox(
                                              height: 26,
                                              child: ElevatedButton(
                                                onPressed: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          DetailPengumumanPage(
                                                        pengumuman:
                                                            pengumuman,
                                                      ),
                                                    ),
                                                  );
                                                },
                                                style: ElevatedButton
                                                    .styleFrom(
                                                  backgroundColor:
                                                      AppColors.mediumDark,
                                                  foregroundColor:
                                                      Colors.white,
                                                  elevation: 0,
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 12),
                                                  shape:
                                                      RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20),
                                                  ),
                                                ),
                                                child: const Text(
                                                  "Lihat Selengkapnya",
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight:
                                                        FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
              ),

              const SizedBox(height: 20),

              /// ================= AREA ABSENSI =================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Area Absensi",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkest,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              if (isLoadingSetting)
                const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.mediumDark,
                  ),
                )
              else if (setting != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      /// GOOGLE MAP
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: SizedBox(
                          height: 280,
                          child: GoogleMap(
                            zoomControlsEnabled: true,
                            myLocationButtonEnabled: true,
                            myLocationEnabled: true,
                            zoomGesturesEnabled: true,
                            scrollGesturesEnabled: true,
                            rotateGesturesEnabled: true,
                            tiltGesturesEnabled: false,
                            initialCameraPosition: CameraPosition(
                              target: LatLng(
                                setting!.latitude,
                                setting!.longitude,
                              ),
                              zoom: setting!.radius < 100
                                  ? 18
                                  : setting!.radius < 500
                                      ? 16
                                      : 14,
                            ),
                            markers: {
                              Marker(
                                markerId: const MarkerId("sekolah"),
                                position: LatLng(
                                  setting!.latitude,
                                  setting!.longitude,
                                ),
                                infoWindow: InfoWindow(
                                  title: setting!.namaLokasi,
                                ),
                              ),
                            },
                            circles: {
                              Circle(
                                circleId: const CircleId("radius"),
                                center: LatLng(
                                  setting!.latitude,
                                  setting!.longitude,
                                ),
                                radius: setting!.radius.toDouble(),
                                fillColor:
                                    AppColors.mediumDark.withOpacity(0.15),
                                strokeColor: AppColors.darkest,
                                strokeWidth: 3,
                              ),
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      /// CARD
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.darkest,
                              AppColors.mediumDark,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ================= FAKE GPS BADGE (tambahan) =================
                            if (isFakeGpsDetected)
                              Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade700,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.warning_amber_rounded,
                                        color: Colors.white, size: 16),
                                    SizedBox(width: 6),
                                    Text(
                                      "Fake GPS terdeteksi",
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),

                            const Text(
                              "Pastikan Anda Melakukan Absensi Pada Area Yang Sudah Ditentukan",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    setting!.namaLokasi,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.access_time,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Lakukan Absensi Sebelum ${setting!.jamTerlambat.substring(0, 5)}",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.social_distance,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "${distance.toStringAsFixed(0)} meter",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  canAttendance
                                      ? "Di dalam area absensi"
                                      : "Di luar area absensi",
                                  style: TextStyle(
                                    color: canAttendance
                                        ? Colors.greenAccent.shade100
                                        : Colors.red.shade200,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.radio_button_checked,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Radius ${setting!.radius} meter",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),

                            // ================= AKURASI GPS (tambahan) =================
                            const SizedBox(height: 8),
                            if (userAccuracy != null)
                              Row(
                                children: [
                                  const Icon(Icons.gps_fixed,
                                      color: Colors.white, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Akurasi GPS: ±${userAccuracy!.toStringAsFixed(0)} m"
                                    "${userAccuracy! > 50 ? " (kurang akurat)" : ""}",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),

                            // ================= REFRESH LOKASI (tambahan) =================
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: isLoadingLocation
                                  ? null
                                  : getCurrentLocation,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.refresh,
                                    color: Colors.white
                                        .withOpacity(isLoadingLocation ? 0.4 : 1),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "Refresh Lokasi",
                                    style: TextStyle(
                                      color: Colors.white
                                          .withOpacity(isLoadingLocation ? 0.4 : 1),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 15),
                            _buildAttendanceButton(
                              context: context,
                              setting: setting!,
                              canAttendance: canAttendance,
                              todayAttendance: todayAttendance,
                              isLoadingLocation: isLoadingLocation,
                              isAbsenMasukExpired: isAbsenMasukExpired,
                              isPulangWindowOpen: isPulangWindowOpen,
                              queuePulangPending: queuePulangHariIni != null,
                              onSuccess: () {
                                getTodayAttendance();
                                getRiwayatAttendance();
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          const SyncProgressOverlay(),
        ],
      ),

           /// ================= BOTTOM NAV =================
      bottomNavigationBar: CurvedNavigationBar(
        index: 0, // HOME AKTIF
        height: 60,
        backgroundColor: AppColors.lightest,
        color: AppColors.darkest,
        buttonBackgroundColor: AppColors.mediumDark,
        animationDuration: const Duration(milliseconds: 400),
        animationCurve: Curves.easeInOut,
        items: [
          _navItem(icon: Icons.home, label: "Home", isActive: true),
          _navItem(icon: Icons.campaign, label: "Pengumuman", isActive: false),
          _navItem(icon: Icons.person, label: "Profile", isActive: false),
        ],
                onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              fadePageRoute(const PengumumanPage()),
            );
          }

          if (index == 2) {
            Navigator.push(
              context,
              fadePageRoute(const ProfilePage()),
            );
          }
        },
      ),
    );
  }

  // ==========================================================
  // Baris pesan di dalam banner "Absensi Ditolak" (tambahan)
  // ==========================================================
  Widget _rejectedBannerLine({
    required String label,
    required AttendanceQueueItem item,
  }) {
    final String reason = (item.serverMessage?.isNotEmpty == true)
        ? item.serverMessage!
        : (item.lastError?.isNotEmpty == true)
            ? item.lastError!
            : "Data absensi tidak memenuhi ketentuan.";

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.cancel_outlined, color: Colors.white, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 12, color: Colors.white),
              children: [
                TextSpan(
                  text: "$label. ",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: reason),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ↓↓↓ TAMBAHKAN METHOD BARU INI ↓↓↓
  Widget _navItem({
    required IconData icon,
    required String label,
    required bool isActive,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: Colors.white,
          size: 22,
        ),
        if (!isActive) ...[
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
  // ↑↑↑ SAMPAI SINI ↑↑↑


Widget _buildAttendanceButton({
  required BuildContext context,
  required AttendanceSetting setting,
  required bool canAttendance,
  required Map<String, dynamic>? todayAttendance,
  required bool isLoadingLocation,
  required bool isAbsenMasukExpired,
  required bool isPulangWindowOpen,
  required bool queuePulangPending,
  required VoidCallback onSuccess,
}) {
  final bool sudahAbsenMasuk = todayAttendance != null;
  final bool sudahAbsenPulang = sudahAbsenMasuk &&
      (todayAttendance["jam_keluar"] ?? "").toString().isNotEmpty;

  String label;
  Color bgColor;
  Color fgColor;
  VoidCallback? onTap;

  Future<void> goToAttendancePage(String mode, String successMessage) async {
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AttendancePage(setting: setting, mode: mode),
        ),
      );

      if (result == true && context.mounted) {
        onSuccess();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e, stack) {
      print(">>> ERROR NAVIGASI: $e");
      print(stack);
    }
  }

  if (sudahAbsenPulang) {
    label = "Absensi Hari Ini Selesai";
    bgColor = Colors.white;
    fgColor = AppColors.darkest;
    onTap = null;
  } else if (sudahAbsenMasuk) {
    if (queuePulangPending) {
      label = "Absen Pulang (Menunggu Sinkronisasi)";
      bgColor = Colors.white;
      fgColor = AppColors.darkest;
      onTap = null;
    } else if (isLoadingLocation) {
      label = "Mendeteksi lokasi...";
      bgColor = Colors.grey;
      fgColor = Colors.black;
      onTap = null;
    } else if (!isPulangWindowOpen) {
      label = "Menunggu Jam Pulang";
      bgColor = Colors.grey;
      fgColor = Colors.black;
      onTap = null;
    } else if (!canAttendance) {
      label = "Di Luar Area Absensi";
      bgColor = Colors.grey;
      fgColor = Colors.black;
      onTap = null;
    } else {
      label = "Absen Pulang";
      bgColor = Colors.white;
      fgColor = AppColors.darkest;
      onTap = () => goToAttendancePage("pulang", "Absen pulang berhasil");
    }
  } else {
    if (isAbsenMasukExpired) {
      label = "Alpha - Jam Absen Berakhir";
      bgColor = Colors.grey;
      fgColor = Colors.black;
      onTap = null;
    } else if (isLoadingLocation) {
      label = "Mendeteksi lokasi...";
      bgColor = Colors.grey;
      fgColor = Colors.black;
      onTap = null;
    } else if (!canAttendance) {
      label = "Di Luar Area Absensi";
      bgColor = Colors.grey;
      fgColor = Colors.black;
      onTap = null;
    } else {
      label = "Lakukan Absensi";
      bgColor = AppColors.darkest;
      fgColor = Colors.white;
      onTap = () => goToAttendancePage("masuk", "Absensi berhasil");
    }
  }

  return SizedBox(
    width: double.infinity,
    height: 42,
    child: ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: fgColor,
        disabledBackgroundColor: Colors.grey.shade400,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    ),
  );
}

Widget _absensiView(
  BuildContext context,
  AttendanceSetting setting,
  bool canAttendance,
  Map<String, dynamic>? todayAttendance,
  bool isLoadingLocation,
  bool isAbsenMasukExpired,
  bool isPulangWindowOpen,
  AttendanceQueueItem? queueMasukHariIni,
  AttendanceQueueItem? queuePulangHariIni,
  VoidCallback onAbsensiBerhasil,
) {
  final bool sudahAbsen = todayAttendance != null;
  final bool masihAntriMasuk = queueMasukHariIni != null;

  final String statusText = sudahAbsen
      ? (masihAntriMasuk
          ? "${todayAttendance["status"] ?? "Hadir"} (Menunggu Sinkronisasi)"
          : (todayAttendance["status"] ?? "Hadir"))
      : (isAbsenMasukExpired ? "Alpha" : "-");

  final String jamMasukText = sudahAbsen
      ? ((todayAttendance["jam_masuk"] ?? "").toString().length >= 5
          ? todayAttendance["jam_masuk"].toString().substring(0, 5)
          : "-")
      : "-";

  final bool sudahAbsenPulang = sudahAbsen &&
      (todayAttendance["jam_keluar"] ?? "").toString().isNotEmpty;

  final String jamPulangText =
      (sudahAbsen && (todayAttendance["jam_keluar"] ?? "").toString().length >= 5)
          ? todayAttendance["jam_keluar"].toString().substring(0, 5)
          : "-";

  // ==========================================================
  // Kalimat keterangan batas waktu:
  // - Selama jendela absen MASUK masih berjalan (belum expired &
  //   belum absen) -> tampilkan batas waktu absen masuk.
  // - Setelah jendela absen masuk berakhir (baik karena sudah absen
  //   masuk, maupun karena Alpha/terlewat) -> tampilkan batas waktu
  //   absen pulang, sesuai permintaan agar kalimat berganti otomatis.
  // - Kalau absen pulang sudah selesai -> tampilkan info selesai.
  // ==========================================================
  final String deadlineText;
  if (sudahAbsenPulang) {
    deadlineText = "Absensi Hari Ini Telah Selesai";
  } else if (!sudahAbsen && !isAbsenMasukExpired) {
    deadlineText =
        "Pastikan Anda Melakukan Absensi Datang\nSebelum ${setting.jamTerlambat.substring(0, 5)}";
  } else {
    deadlineText =
        "Waktu Absensi Pulang Berakhir\nPukul ${setting.jamPulangSelesai.substring(0, 5)}";
  }

  return Column(
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          Row(
            children: [
              Icon(Icons.person, size: 18),
              SizedBox(width: 6),
              Text("Status"),
            ],
          ),
          Row(
            children: [
              Icon(Icons.access_time, size: 18),
              SizedBox(width: 6),
              Text("Datang"),
            ],
          ),
          Row(
            children: [
              Icon(Icons.access_time, size: 18),
              SizedBox(width: 6),
              Text("Pulang"),
            ],
          ),
        ],
      ),
      const SizedBox(height: 8),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            statusText,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _statusColor(statusText),
            ),
          ),
          Text(jamMasukText,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(jamPulangText,
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
      const SizedBox(height: 14),
      Text(
        deadlineText,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 12,
        ),
      ),
      const SizedBox(height: 16),
      _buildAttendanceButton(
        context: context,
        setting: setting,
        canAttendance: canAttendance,
        todayAttendance: todayAttendance,
        isLoadingLocation: isLoadingLocation,
        isAbsenMasukExpired: isAbsenMasukExpired,
        isPulangWindowOpen: isPulangWindowOpen,
        queuePulangPending: queuePulangHariIni != null,
        onSuccess: onAbsensiBerhasil,
      ),
    ],
  );
}

Widget _riwayatView(
    List<dynamic> riwayatList, bool isLoading, BuildContext context) {
  if (isLoading) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: CircularProgressIndicator(color: AppColors.mediumDark),
      ),
    );
  }

  if (riwayatList.isEmpty) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Center(child: Text("Belum ada riwayat absensi")),
    );
  }

  final latest = riwayatList.first;

  String tanggal = "-";
  try {
    final parsedDate = DateTime.parse(latest["tanggal"]);
    tanggal = DateFormat("EEEE dd-MM-yyyy", "id_ID").format(parsedDate);
  } catch (_) {}

  final String jamMasuk = (latest["jam_masuk"] ?? "").toString().length >= 5
      ? latest["jam_masuk"].toString().substring(0, 5)
      : "-";
  final String status = latest["status"] ?? "-";

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        "Status Kehadiran",
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.darkest,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        status,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: _statusColor(status),
        ),
      ),

      const SizedBox(height: 18),

      Row(
        children: [
          _dot(),
          Expanded(child: _dashedLine()),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: AppColors.darkest,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.badge, size: 16, color: Colors.white),
          ),
          Expanded(child: _dashedLine()),
          _dot(),
        ],
      ),

      const SizedBox(height: 18),

      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Tanggal",
                  style: TextStyle(fontSize: 12, color: Colors.black54)),
              const SizedBox(height: 4),
              Text(tanggal,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text("Waktu Absensi",
                  style: TextStyle(fontSize: 12, color: Colors.black54)),
              const SizedBox(height: 4),
              Text(jamMasuk,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),

      const SizedBox(height: 20),

      SizedBox(
        width: double.infinity,
        height: 44,
        child: ElevatedButton(
          onPressed: () => _showRiwayatSheet(context, riwayatList),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.mediumDark,
            foregroundColor: Colors.white,
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          child: const Text("Lihat Semua",
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
    ],
  );
}

Widget _dot() {
  return Container(
    width: 12,
    height: 12,
    decoration: const BoxDecoration(
      color: AppColors.darkest,
      shape: BoxShape.circle,
    ),
  );
}

Color _statusColor(String status) {
  switch (status.toLowerCase().trim()) {
    case "hadir":
      return AppColors.darkest;
    case "terlambat":
      return Colors.orange;
    case "alpha":
      return Colors.red.shade400;
    case "izin":
      return Colors.blue;
    case "sakit":
      return Colors.purple;
    default:
      return Colors.black54;
  }
}

Widget _dashedLine() {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: CustomPaint(
      size: const Size(double.infinity, 2),
      painter: _DashedLinePainter(),
    ),
  );
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.darkest
      ..strokeWidth = 2;
    const dashWidth = 4.0;
    const dashSpace = 4.0;
    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

void _showRiwayatSheet(BuildContext context, List<dynamic> riwayatList) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _RiwayatSheet(riwayatList: riwayatList),
  );
}

class _RiwayatSheet extends StatefulWidget {
  final List<dynamic> riwayatList;

  const _RiwayatSheet({required this.riwayatList});

  @override
  State<_RiwayatSheet> createState() => _RiwayatSheetState();
}

class _RiwayatSheetState extends State<_RiwayatSheet> {
  String filterStatus = "Semua";
  DateTime? filterTanggal;

  List<dynamic> get filtered {
    return widget.riwayatList.where((item) {
      if (filterStatus != "Semua") {
        final itemStatus =
            (item["status"] ?? "").toString().trim().toLowerCase();
        final selectedStatus = filterStatus.trim().toLowerCase();
        if (itemStatus != selectedStatus) return false;
      }

      if (filterTanggal != null) {
        try {
          final parsed = DateTime.parse(item["tanggal"]);
          if (parsed.year != filterTanggal!.year ||
              parsed.month != filterTanggal!.month ||
              parsed.day != filterTanggal!.day) {
            return false;
          }
        } catch (_) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: filterTanggal ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.darkest,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => filterTanggal = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.85,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          const SizedBox(height: 16),

          const Text(
            "Riwayat Absensi",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.darkest,
            ),
          ),

          const SizedBox(height: 16),

          const Text(
            "Filter Status",
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                "Semua",
                "Hadir",
                "Terlambat",
                "Alpha",
                "Izin",
                "Sakit"
              ].map((status) {
                final isActive = filterStatus == status;
                return GestureDetector(
                  onTap: () => setState(() => filterStatus = status),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.darkest
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isActive
                            ? AppColors.darkest
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isActive ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          const Text(
            "Filter Tanggal",
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              GestureDetector(
                onTap: pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: filterTanggal != null
                        ? AppColors.darkest
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: filterTanggal != null
                          ? AppColors.darkest
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: filterTanggal != null
                            ? Colors.white
                            : Colors.black54,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        filterTanggal != null
                            ? DateFormat("dd-MM-yyyy").format(filterTanggal!)
                            : "Pilih Tanggal",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: filterTanggal != null
                              ? Colors.white
                              : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (filterTanggal != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => setState(() => filterTanggal = null),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Icon(
                      Icons.close,
                      size: 14,
                      color: Colors.red.shade400,
                    ),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),

          Text(
            "${filtered.length} data ditemukan",
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 48,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Tidak ada data",
                          style: TextStyle(color: Colors.black45),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];

                      String tanggal = "-";
                      try {
                        final parsedDate = DateTime.parse(item["tanggal"]);
                        tanggal = DateFormat("dd-MM-yyyy", "id_ID")
                            .format(parsedDate);
                      } catch (_) {}

                      final String jamMasuk =
                          (item["jam_masuk"] ?? "").toString().length >= 5
                              ? item["jam_masuk"].toString().substring(0, 5)
                              : "-";
                      final String jamPulang =
                          (item["jam_keluar"] ?? "").toString().length >= 5
                              ? item["jam_keluar"].toString().substring(0, 5)
                              : "-";
                      final String status = item["status"] ?? "-";
                      final Color statusColor = _statusColor(status);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xffF7F7F7),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: statusColor.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 4,
                              height: 44,
                              decoration: BoxDecoration(
                                color: statusColor,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    status,
                                    style: TextStyle(
                                      color: statusColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    tanggal,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if ((item["keterangan"] ?? "")
                                      .toString()
                                      .isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      item["keterangan"].toString(),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.black45,
                                        fontStyle: FontStyle.italic,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  "Jam Masuk",
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.black45,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  jamMasuk,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  "Jam Pulang",
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.black45,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  jamPulang,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
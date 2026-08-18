import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:network_info_plus/network_info_plus.dart';

import '../models/attendance_setting.dart';
import '../services/attendance_service.dart';

class AttendancePage extends StatefulWidget {
  final AttendanceSetting setting;
  final String mode; // "masuk" atau "pulang"

  const AttendancePage({
    super.key,
    required this.setting,
    required this.mode,
  });

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage>
    with WidgetsBindingObserver {
  CameraController? controller;

  File? image;

  bool loadingCamera = true;
  bool takingPicture = false;
  bool verifying = false;
  bool fetchingLocation = false;

  // Menyimpan hasil terakhir kalau request sempat timeout, supaya
  // tombol "Coba Lagi" bisa langsung mengirim ulang tanpa foto ulang.
  bool lastAttemptTimedOut = false;

  final AttendanceService attendanceService = AttendanceService();

  static const Color primaryColor = Color(0xFF2F6FED);
  static const Color successColor = Color(0xFF22C55E);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color bgDark = Color(0xFF0B0F17);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final cam = controller;

    if (cam == null || !cam.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      cam.dispose();
    } else if (state == AppLifecycleState.resumed) {
      initCamera();
    }
  }

  Future<void> initCamera() async {
    setState(() {
      loadingCamera = true;
    });

    final cameras = await availableCameras();

    final frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    controller = CameraController(
      frontCamera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await controller!.initialize();
    } catch (e) {
      debugPrint("Camera init error: $e");
      return;
    }

    if (!mounted) return;

    setState(() {
      loadingCamera = false;
    });
  }

  Future<void> takePicture() async {
    if (controller == null) return;
    if (!controller!.value.isInitialized) return;
    if (takingPicture) return;

    setState(() {
      takingPicture = true;
    });

    try {
      final XFile file = await controller!.takePicture();

      if (controller!.value.isInitialized) {
        try {
          await controller!.resumePreview();
        } catch (_) {
          // beberapa platform tidak mendukung resumePreview, aman diabaikan
        }
      }

      if (!mounted) return;
      setState(() {
        image = File(file.path);
        lastAttemptTimedOut = false;
      });
    } catch (e) {
      debugPrint("Take picture error: $e");
    } finally {
      if (mounted) setState(() => takingPicture = false);
    }
  }

  Future<void> retake() async {
    setState(() {
      image = null;
      lastAttemptTimedOut = false;
    });

    try {
      await controller?.resumePreview();
    } catch (_) {}
  }

  Future<Position?> _getReliablePosition({
    int maxAttempts = 3,
    double goodEnoughAccuracy = 20,
  }) async {
    Position? best;

    for (int i = 0; i < maxAttempts; i++) {
      try {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best,
          timeLimit: const Duration(seconds: 6),
        );

        if (best == null || pos.accuracy < best.accuracy) {
          best = pos;
        }

        if (pos.accuracy <= goodEnoughAccuracy) break;
      } catch (_) {
        // lanjut ke percobaan berikutnya
      }
    }

    return best;
  }

  Future<void> verifyAttendance() async {
    if (image == null) return;

    setState(() {
      verifying = true;
      fetchingLocation = true;
      lastAttemptTimedOut = false;
    });

    final Position? position = await _getReliablePosition();

    if (position == null) {
      if (!mounted) return;
      setState(() {
        verifying = false;
        fetchingLocation = false;
      });
      _showSnack(
        "Gagal mengambil lokasi. Pastikan GPS aktif.",
        isError: true,
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      fetchingLocation = false;
    });

    String? wifiBssid;

    if (widget.setting.wifiRequired) {
      try {
        wifiBssid = await NetworkInfo().getWifiBSSID();
      } catch (_) {}
    }

    final response = widget.mode == "pulang"
        ? await attendanceService.attendancePulang(
            image!,
            position.latitude,
            position.longitude,
            position.accuracy,
            wifiBssid,
            isMocked: position.isMocked,
          )
        : await attendanceService.attendance(
            image!,
            position.latitude,
            position.longitude,
            position.accuracy,
            wifiBssid,
            isMocked: position.isMocked,
          );

    if (!mounted) return;

    setState(() {
      verifying = false;
    });

    final bool isTimeout = response["timeout"] == true;

    if (response["success"] == true) {
      final bool queued = response["queued"] == true;

      await _showResultDialog(
        success: true,
        queued: queued,
        message: response["message"] ??
            (queued
                ? "Absensi disimpan dan akan otomatis dikirim saat internet tersedia."
                : (widget.mode == "pulang"
                    ? "Absen pulang berhasil"
                    : "Absensi berhasil")),
        status: response["status"],
        similarity: response["similarity"],
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } else if (isTimeout) {
      // Kasus khusus: server lambat merespons, TAPI request mungkin
      // saja sudah diterima dan sedang diproses. Jangan langsung
      // retake foto -> biarkan user memilih "Coba Lagi" (kirim ulang
      // foto & lokasi yang sama) atau cek status absensi dulu secara
      // manual, supaya tidak berisiko mengirim foto dobel tanpa sadar.
      setState(() {
        lastAttemptTimedOut = true;
      });
      _showSnack(
        response["message"] ??
            "Server sedang lambat merespons. Silakan coba lagi.",
        isError: false,
        isWarning: true,
      );
    } else {
      setState(() {
        lastAttemptTimedOut = false;
      });
      _showSnack(
        response["message"] ?? "Absensi gagal",
        isError: true,
      );
      // Kembali ke mode kamera supaya user bisa coba lagi dari awal.
      await retake();
    }
  }

  Future<void> _showResultDialog({
    required bool success,
    required bool queued,
    required String message,
    String? status,
    dynamic similarity,
  }) async {
    final isTerlambat = status == "terlambat";

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFF141B2A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: queued
                      ? primaryColor
                      : (isTerlambat ? warningColor : successColor)
                          .withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  queued
                      ? Icons.cloud_upload_outlined
                      : isTerlambat
                          ? Icons.schedule_rounded
                          : Icons.check_rounded,
                  color: queued
                      ? primaryColor
                      : (isTerlambat ? warningColor : successColor),
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                queued
                    ? "Absensi Disimpan"
                    : isTerlambat
                        ? "Absen Berhasil (Terlambat)"
                        : (widget.mode == "pulang"
                            ? "Absen Pulang Berhasil"
                            : "Absen Masuk Berhasil"),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              if (!queued && similarity != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified_rounded,
                        color: primaryColor,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Kecocokan wajah: "
                        "${((similarity is num ? similarity : 0) * 100).toStringAsFixed(1)}%",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    "Selesai",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnack(
    String message, {
    bool isError = false,
    bool isWarning = false,
  }) {
    final Color bg =
        isError ? errorColor : (isWarning ? warningColor : successColor);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ==========================================================
  // CAMERA VIEW
  // ==========================================================
  Widget buildCamera() {
    return Stack(
      fit: StackFit.expand,
      children: [
        CameraPreview(controller!),

        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.75),
                Colors.transparent,
                Colors.transparent,
                Colors.black.withOpacity(0.75),
              ],
              stops: const [0.0, 0.3, 0.6, 1.0],
            ),
          ),
        ),

        const Center(
          child: _FaceGuide(),
        ),

        // Top bar
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.fiber_manual_record,
                          color: successColor,
                          size: 10,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          "Live",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ),
        ),

        // Instruksi
        Positioned(
          top: 120,
          left: 24,
          right: 24,
          child: Column(
            children: [
              Text(
                widget.mode == "pulang" ? "Absen Pulang" : "Absen Masuk",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Posisikan wajah tepat di dalam bingkai\nlalu tekan tombol kamera",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.75),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),

        // Tombol shutter
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Center(
            child: GestureDetector(
              onTap: takePicture,
              child: Container(
                width: 76,
                height: 76,
                decoration: const BoxDecoration(
                  color: Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.fromBorderSide(
                    BorderSide(color: Colors.white, width: 3),
                  ),
                ),
                padding: const EdgeInsets.all(6),
                child: Container(
                  decoration: BoxDecoration(
                    color: takingPicture
                        ? Colors.white.withOpacity(0.5)
                        : Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: takingPicture
                      ? const Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: primaryColor,
                          ),
                        )
                      : null,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // PREVIEW
  // ==========================================================
  Widget buildPreview() {
    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 12),
          const Text(
            "Konfirmasi Absensi",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Pastikan wajah terlihat jelas sebelum mengirim",
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.file(
                  image!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            ),
          ),

          // Status pengambilan lokasi / verifikasi
          if (verifying)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      fetchingLocation
                          ? "Mengambil lokasi GPS..."
                          : "Memverifikasi wajah...",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Peringatan kalau percobaan sebelumnya timeout (server lambat,
          // bukan pasti gagal) -> beri konteks supaya user tidak bingung
          // kenapa masih di layar konfirmasi yang sama.
          if (!verifying && lastAttemptTimedOut)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: warningColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: warningColor.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        color: warningColor, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Server lambat merespons. Absensi belum tentu "
                        "gagal — tekan \"Coba Lagi\" atau cek status "
                        "absensi hari ini terlebih dahulu.",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: verifying ? null : verifyAttendance,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          lastAttemptTimedOut ? warningColor : successColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: verifying
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            lastAttemptTimedOut
                                ? "Coba Lagi"
                                : "Absen Sekarang",
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: verifying ? null : retake,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withOpacity(0.4)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      "Ambil Ulang",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
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
  }

  @override
  Widget build(BuildContext context) {
    if (loadingCamera ||
        controller == null ||
        !controller!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: bgDark,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bgDark,
      extendBodyBehindAppBar: true,
      body: image == null ? buildCamera() : buildPreview(),
    );
  }
}

class _FaceGuide extends StatelessWidget {
  const _FaceGuide();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      height: 320,
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.white.withOpacity(0.9),
          width: 2.5,
        ),
        borderRadius: BorderRadius.circular(150),
      ),
    );
  }
}
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../services/attendance_service.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

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

  final AttendanceService attendanceService = AttendanceService();

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

    await controller!.initialize();

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

      image = File(file.path);

      if (mounted) {
        setState(() {});
      }
    } finally {
      takingPicture = false;

      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> retake() async {
    image = null;

    if (mounted) {
      setState(() {});
    }

    try {
      await controller?.resumePreview();
    } catch (_) {}
  }

  Future<void> verifyAttendance() async {
    if (image == null) return;

    setState(() {
      verifying = true;
    });

    // Ambil lokasi terbaru sebelum kirim absensi
    Position position;
    try {
      position = await Geolocator.getCurrentPosition();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        verifying = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text("Gagal mengambil lokasi. Pastikan GPS aktif."),
        ),
      );
      return;
    }

    if (position.isMocked) {
      if (!mounted) return;
      setState(() {
        verifying = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text("Lokasi palsu (fake GPS) terdeteksi. Absensi ditolak."),
        ),
      );
      return;
    }

    final response = await attendanceService.attendance(
      image!,
      position.latitude,
      position.longitude,
    );

    if (!mounted) return;

    setState(() {
      verifying = false;
    });

    if (response["success"] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          content: Text(
            response["message"],
          ),
        ),
      );

      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            response["message"] ?? "Absensi gagal",
          ),
        ),
      );
    }
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
                Colors.black.withOpacity(.55),
                Colors.transparent,
                Colors.transparent,
                Colors.black.withOpacity(.70),
              ],
              stops: const [
                0,
                .25,
                .65,
                1,
              ],
            ),
          ),
        ),
        const Center(
          child: _FaceGuide(),
        ),
        Positioned(
          top: 40,
          left: 24,
          right: 24,
          child: Column(
            children: [
              const Text(
                "Absensi Wajah",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Posisikan wajah tepat di dalam lingkaran\nkemudian tekan tombol kamera",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(.85),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 45,
          left: 0,
          right: 0,
          child: Center(
            child: GestureDetector(
              onTap: takePicture,
              child: Container(
                width: 80,
                height: 80,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 3,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: takingPicture ? Colors.white54 : Colors.white,
                  ),
                  child: takingPicture
                      ? const Padding(
                          padding: EdgeInsets.all(18),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
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
          const SizedBox(height: 15),
          const Text(
            "Konfirmasi Foto",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            "Pastikan wajah terlihat jelas",
            style: TextStyle(
              color: Colors.white.withOpacity(.75),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.file(
                  image!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: verifying ? null : verifyAttendance,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff1E5631),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
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
                        : const Text(
                            "Absen Sekarang",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: retake,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(
                        color: Colors.white.withOpacity(.5),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text(
                      "Ambil Ulang",
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
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: image == null
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              centerTitle: true,
              iconTheme: const IconThemeData(color: Colors.white),
              title: const Text(
                "Absensi Masuk",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : null,
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
          color: Colors.white.withOpacity(.9),
          width: 2.5,
        ),
        borderRadius: BorderRadius.circular(150),
      ),
    );
  }
}

import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../services/face_service.dart';

class RegisterFacePage extends StatefulWidget {
  const RegisterFacePage({super.key});

  @override
  State<RegisterFacePage> createState() => _RegisterFacePageState();
}

class _RegisterFacePageState extends State<RegisterFacePage>
    with WidgetsBindingObserver {
  CameraController? controller;

  File? image;

  bool loading = true;
  bool capturing = false;
  bool uploading = false;

  static const Color primaryColor = Color(0xFF2F6FED);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initCamera();
  }

  // ---------------------------------------------------------------------
  // LIFECYCLE: pause/resume kamera agar tidak freeze/crash saat
  // app diminimize lalu dibuka kembali
  // ---------------------------------------------------------------------
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final cam = controller;
    if (cam == null || !cam.value.isInitialized) return;

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      cam.dispose();
    } else if (state == AppLifecycleState.resumed) {
      initCamera();
    }
  }

  Future<void> initCamera() async {
    final cameras = await availableCameras();

    final frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    final cam = CameraController(
      frontCamera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await cam.initialize();
    } catch (e) {
      debugPrint("Camera init error: $e");
      return;
    }

    if (!mounted) {
      cam.dispose();
      return;
    }

    setState(() {
      controller = cam;
      loading = false;
    });
  }

  Future<void> takePicture() async {
    final cam = controller;
    if (cam == null || !cam.value.isInitialized) return;
    if (capturing) return;

    setState(() => capturing = true);

    try {
      final XFile file = await cam.takePicture();

      // Beberapa device/emulator tidak auto-resume preview setelah capture
      if (cam.value.isInitialized) {
        try {
          await cam.resumePreview();
        } catch (_) {
          // beberapa platform tidak mendukung resumePreview, aman diabaikan
        }
      }

      if (!mounted) return;
      setState(() {
        image = File(file.path);
      });
    } catch (e) {
      debugPrint("Take picture error: $e");
    } finally {
      if (mounted) setState(() => capturing = false);
    }
  }

  Future<void> retake() async {
    setState(() {
      image = null;
    });

    final cam = controller;

    if (cam != null && cam.value.isInitialized) {
      try {
        await cam.resumePreview();
      } catch (_) {}
    }
  }

  Future<void> registerFace() async {
    if (image == null) return;

    setState(() {
      uploading = true;
    });

    try {
      final response = await FaceService.registerFace(image!);

      if (!mounted) return;

      if (response["success"] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Face ID berhasil didaftarkan"),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response["message"] ?? "Gagal mendaftarkan Face ID",
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    }

    if (mounted) {
      setState(() {
        uploading = false;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller?.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------
  // CAMERA VIEW
  // ---------------------------------------------------------------------
  Widget buildCamera() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // RotatedBox jauh lebih ringan dibanding Transform.rotate
        // karena tidak memaksa offscreen GPU layer per-frame
        CameraPreview(controller!),

        // Gradient overlay atas & bawah agar elemen UI lebih kontras
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.55),
                Colors.transparent,
                Colors.transparent,
                Colors.black.withOpacity(0.65),
              ],
              stops: const [0.0, 0.25, 0.6, 1.0],
            ),
          ),
        ),

        // Face guide
        const Center(
          child: _FaceGuide(),
        ),

        // Instruksi
        Positioned(
          top: 24,
          left: 24,
          right: 24,
          child: Column(
            children: [
              const Text(
                "Posisikan wajah Anda",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Pastikan wajah berada di dalam bingkai dan\npencahayaan cukup terang",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),

        // Tombol shutter
        Positioned(
          bottom: 36,
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
                    color: capturing
                        ? Colors.white.withOpacity(0.5)
                        : Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: capturing
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

  // ---------------------------------------------------------------------
  // PREVIEW VIEW
  // ---------------------------------------------------------------------
  Widget buildPreview() {
    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 8),
          const Text(
            "Tinjau Foto Anda",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Pastikan wajah terlihat jelas sebelum melanjutkan",
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: uploading ? null : registerFace,
                    child: uploading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            "Daftarkan Face ID",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withOpacity(0.4)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: retake,
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
    if (loading || controller == null || !controller!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
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
              title: const Text(
                "Daftar Face ID",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              centerTitle: true,
              iconTheme: const IconThemeData(color: Colors.white),
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
          color: Colors.white.withOpacity(0.9),
          width: 2.5,
        ),
        borderRadius: BorderRadius.circular(150),
      ),
    );
  }
}

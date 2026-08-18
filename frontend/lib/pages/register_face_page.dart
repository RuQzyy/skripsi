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

  // ---------------------------------------------------------------------
  // MULTI-STEP ENROLLMENT
  // Mengambil beberapa foto dengan variasi pose agar hasil pengenalan
  // wajah lebih toleran terhadap sudut & ekspresi natural pengguna.
  // ---------------------------------------------------------------------
  int currentStep = 0;
  final int totalSteps = 5;

  static const List<_StepInfo> steps = [
    _StepInfo(
      title: "Hadap lurus ke depan",
      subtitle: "Lihat langsung ke kamera dengan ekspresi netral",
      icon: Icons.face_outlined,
    ),
    _StepInfo(
      title: "Lihat sedikit ke kiri",
      subtitle: "Cukup 15-20°, wajah masih terlihat penuh",
      icon: Icons.rotate_left_rounded,
    ),
    _StepInfo(
      title: "Lihat sedikit ke kanan",
      subtitle: "Putar wajah perlahan ke arah kanan",
      icon: Icons.rotate_right_rounded,
    ),
    _StepInfo(
      title: "Dongakkan sedikit ke atas",
      subtitle: "Angkat dagu sedikit ke atas",
      icon: Icons.keyboard_arrow_up_rounded,
    ),
    _StepInfo(
      title: "Tundukkan sedikit ke bawah",
      subtitle: "Turunkan dagu sedikit ke bawah",
      icon: Icons.keyboard_arrow_down_rounded,
    ),
  ];

  static const Color primaryColor = Color(0xFF2F6FED);
  static const Color successColor = Color(0xFF22C55E);
  static const Color bgDark = Color(0xFF0B0F17);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initCamera();
  }

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
        if (currentStep < totalSteps - 1) {
          // Masih ada pose berikutnya
          setState(() {
            currentStep++;
            image = null;
            uploading = false;
          });
          await controller?.resumePreview();
        } else {
          // Semua pose selesai
          setState(() => uploading = false);
          if (!mounted) return;
          await _showSuccessAndExit();
        }
      } else {
        setState(() => uploading = false);
        _showSnack(
          response["message"] ?? "Gagal mendaftarkan Face ID",
          isError: true,
        );
      }
    } catch (e) {
      setState(() => uploading = false);
      _showSnack(e.toString(), isError: true);
    }
  }

  Future<void> _showSuccessAndExit() async {
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
                  color: successColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: successColor,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Face ID Berhasil Didaftarkan",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Semua pose wajah telah tersimpan dengan baik",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
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

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFEF4444) : successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller?.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------
  // PROGRESS INDICATOR
  // ---------------------------------------------------------------------
  Widget buildProgress() {
    return Row(
      children: List.generate(totalSteps, (index) {
        final isDone = index < currentStep;
        final isActive = index == currentStep;

        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index == totalSteps - 1 ? 0 : 6),
            height: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: isDone || isActive
                  ? primaryColor
                  : Colors.white.withOpacity(0.15),
            ),
          ),
        );
      }),
    );
  }

  // ---------------------------------------------------------------------
  // CAMERA VIEW
  // ---------------------------------------------------------------------
  Widget buildCamera() {
    final step = steps[currentStep];

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

        // Face guide dengan highlight step aktif
        Center(
          child: _FaceGuide(icon: step.icon),
        ),

        // Top bar: progress + step counter
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded,
                            color: Colors.white),
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
                        child: Text(
                          "${currentStep + 1} / $totalSteps",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 48), // seimbangkan tombol close
                    ],
                  ),
                  const SizedBox(height: 14),
                  buildProgress(),
                ],
              ),
            ),
          ),
        ),

        // Instruksi pose
        Positioned(
          top: 130,
          left: 24,
          right: 24,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Column(
              key: ValueKey(currentStep),
              children: [
                Text(
                  step.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  step.subtitle,
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
    final step = steps[currentStep];
    final isLastStep = currentStep == totalSteps - 1;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: buildProgress(),
          ),
          const SizedBox(height: 20),
          Text(
            "Tinjau Foto — ${step.title}",
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Pastikan wajah terlihat jelas sebelum melanjutkan",
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
                        : Text(
                            isLastStep ? "Selesaikan Pendaftaran" : "Lanjutkan",
                            style: const TextStyle(
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
                    onPressed: uploading ? null : retake,
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

class _StepInfo {
  final String title;
  final String subtitle;
  final IconData icon;

  const _StepInfo({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

class _FaceGuide extends StatelessWidget {
  final IconData icon;

  const _FaceGuide({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 260,
          height: 320,
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.white.withOpacity(0.9),
              width: 2.5,
            ),
            borderRadius: BorderRadius.circular(150),
          ),
        ),
        Positioned(
          top: -14,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2F6FED),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
        ),
      ],
    );
  }
}
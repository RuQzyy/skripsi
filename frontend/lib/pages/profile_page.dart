import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dashboard_page.dart';
import 'pengumuman_page.dart';
import '../services/auth_service.dart';
import 'register_face_page.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import '../utils/page_transition.dart';
import 'login_page.dart'; // sumber AppColors

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? user;
  File? _selectedImage;
  bool _uploadingPhoto = false;

  String getPhotoUrl() {
    if (user == null || user?["photo"] == null) {
      return "";
    }

    String role = user?["role"]?.toString() ?? "siswa";

    return "http://192.168.1.48:8000/storage/$role/${user?["photo"]}";
  }

  final TextEditingController namaController = TextEditingController();
  final TextEditingController nimController = TextEditingController();
  final TextEditingController kelasController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  Future<void> getUser() async {
    final dataUser = await AuthService.fetchUser();

    if (!mounted) return;

    setState(() {
      user = dataUser;

      namaController.text = user?["name"]?.toString() ?? "";

      nimController.text = (user?["nisn"] ?? user?["nip"] ?? "").toString();

      kelasController.text = user?["kelas"] != null
          ? (user?["kelas"]["nama_kelas"] ?? "").toString()
          : "";

      emailController.text = user?["email"]?.toString() ?? "";

      phoneController.text = user?["phone"]?.toString() ?? "";
    });
  }

  Future<void> pickAndUploadPhoto() async {
    final picker = ImagePicker();

    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (picked == null) return;

    setState(() {
      _selectedImage = File(picked.path);
      _uploadingPhoto = true;
    });

    final result = await AuthService.updatePhoto(picked.path);

    if (!mounted) return;

    setState(() {
      _uploadingPhoto = false;
    });

    if (result["success"] == true) {
      await getUser(); // refresh data user

      setState(() {
        _selectedImage = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Foto berhasil diperbarui"),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      setState(() {
        _selectedImage = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result["message"] ?? "Gagal upload foto"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    getUser();
  }

  Widget buildTextField(
    String label,
    TextEditingController controller, {
    bool obscure = false,
    bool readOnly = false,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        readOnly: readOnly,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null ? Icon(icon, color: AppColors.medium) : null,
          filled: true,
          fillColor: AppColors.lightest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.mediumDark, width: 1.5),
          ),
        ),
      ),
    );
  }

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

  @override
  void dispose() {
    namaController.dispose();
    nimController.dispose();
    kelasController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightest,
      body: SafeArea(
        child: user == null
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.mediumDark,
                ),
              )
            : SingleChildScrollView(
                child: Column(
                  children: [
                    /// HEADER
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.only(
                        top: 25,
                        bottom: 80,
                      ),
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
                      child: const Center(
                        child: Text(
                          "Profile Saya",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    Transform.translate(
                      offset: const Offset(0, -50),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            /// CARD PROFILE
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.darkest.withOpacity(0.08),
                                    blurRadius: 15,
                                    offset: const Offset(0, 6),
                                  )
                                ],
                              ),
                              child: Column(
                                children: [
                                  Stack(
                                    children: [
                                      CircleAvatar(
                                        radius: 50,
                                        backgroundColor: AppColors.mediumDark,
                                        backgroundImage: _selectedImage != null
                                            ? FileImage(_selectedImage!)
                                            : (user?["photo"] != null &&
                                                    user!["photo"]
                                                        .toString()
                                                        .isNotEmpty
                                                ? NetworkImage(getPhotoUrl())
                                                : null) as ImageProvider?,
                                        child: _selectedImage == null &&
                                                (user?["photo"] == null ||
                                                    user!["photo"]
                                                        .toString()
                                                        .isEmpty)
                                            ? Text(
                                                user?["name"]
                                                        ?.toString()
                                                        .substring(0, 1)
                                                        .toUpperCase() ??
                                                    "U",
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 30,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              )
                                            : null,
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: GestureDetector(
                                          onTap: _uploadingPhoto
                                              ? null
                                              : pickAndUploadPhoto,
                                          child: Container(
                                            width: 30,
                                            height: 30,
                                            decoration: BoxDecoration(
                                              color: _uploadingPhoto
                                                  ? Colors.grey
                                                  : AppColors.darkest,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white,
                                                width: 2,
                                              ),
                                            ),
                                            child: _uploadingPhoto
                                                ? const Padding(
                                                    padding: EdgeInsets.all(6),
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Colors.white,
                                                    ),
                                                  )
                                                : const Icon(
                                                    Icons.camera_alt,
                                                    size: 16,
                                                    color: Colors.white,
                                                  ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 15),
                                  Text(
                                    user?["name"]?.toString() ?? "",
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                      color: AppColors.darkest,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    (user?["nisn"] ?? user?["nip"] ?? "")
                                        .toString(),
                                    style: const TextStyle(
                                      color: Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    user?["kelas"] != null
                                        ? (user?["kelas"]["nama_kelas"] ?? "")
                                            .toString()
                                        : "",
                                    style: const TextStyle(
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 25),

                            /// INFORMASI AKUN
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.darkest.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Informasi Akun",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.darkest,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  buildTextField(
                                    "Nama",
                                    namaController,
                                    readOnly: true,
                                    icon: Icons.person,
                                  ),
                                  buildTextField(
                                    "NISN / NIP",
                                    nimController,
                                    readOnly: true,
                                    icon: Icons.badge,
                                  ),
                                  buildTextField(
                                    "Kelas",
                                    kelasController,
                                    readOnly: true,
                                    icon: Icons.school,
                                  ),
                                  buildTextField(
                                    "Email",
                                    emailController,
                                    readOnly: true,
                                    icon: Icons.email,
                                  ),
                                  buildTextField(
                                    "Nomor Telepon",
                                    phoneController,
                                    readOnly: true,
                                    icon: Icons.phone,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 25),

                            /// PASSWORD
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.darkest.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Keamanan Akun",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.darkest,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  buildTextField(
                                    "Password Baru",
                                    passwordController,
                                    obscure: true,
                                    icon: Icons.lock,
                                  ),
                                  buildTextField(
                                    "Konfirmasi Password",
                                    confirmPasswordController,
                                    obscure: true,
                                    icon: Icons.lock_outline,
                                  ),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        if (passwordController.text.isEmpty ||
                                            confirmPasswordController
                                                .text.isEmpty) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                "Password tidak boleh kosong",
                                              ),
                                            ),
                                          );
                                          return;
                                        }

                                        if (passwordController.text !=
                                            confirmPasswordController.text) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                "Konfirmasi password tidak sama",
                                              ),
                                            ),
                                          );
                                          return;
                                        }

                                        bool success =
                                            await AuthService.updatePassword(
                                          passwordController.text,
                                        );

                                        if (!mounted) return;

                                        if (success) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                "Password berhasil diubah",
                                              ),
                                            ),
                                          );

                                          passwordController.clear();
                                          confirmPasswordController.clear();
                                        } else {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                "Gagal update password",
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.mediumDark,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                      ),
                                      child: const Text(
                                        "Simpan Password",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 25),

                            /// FACE ID
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.darkest.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Face ID",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.darkest,
                                    ),
                                  ),

                                  const SizedBox(height: 15),

                                  Row(
                                    children: [
                                      Icon(
                                        user?["face_id"] == null
                                            ? Icons.face_retouching_off
                                            : Icons.verified,
                                        color: user?["face_id"] == null
                                            ? Colors.red
                                            : AppColors.mediumDark,
                                      ),

                                      const SizedBox(width: 10),

                                      Expanded(
                                        child: Text(
                                          user?["face_id"] == null
                                              ? "Face ID belum terdaftar"
                                              : "Face ID sudah terdaftar",
                                          style: const TextStyle(
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  // ===============================
                                  // Tombol hanya muncul jika belum daftar
                                  // ===============================

                                  if (user?["face_id"] == null) ...[
                                    const SizedBox(height: 20),

                                    SizedBox(
                                      width: double.infinity,
                                      height: 50,
                                      child: ElevatedButton.icon(
                                        onPressed: () async {
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const RegisterFacePage(),
                                            ),
                                          );

                                          // Refresh data user setelah kembali
                                          await getUser();
                                        },
                                        icon: const Icon(Icons.face),
                                        label: const Text("Daftarkan Face ID"),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.darkest,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),

            /// ================= BOTTOM NAV =================
      bottomNavigationBar: CurvedNavigationBar(
        index: 2, // PROFILE AKTIF
        height: 60,
        backgroundColor: AppColors.lightest,
        color: AppColors.darkest,
        buttonBackgroundColor: AppColors.mediumDark,
        animationDuration: const Duration(milliseconds: 400),
        animationCurve: Curves.easeInOut,
        items: [
          _navItem(icon: Icons.home, label: "Home", isActive: false),
          _navItem(icon: Icons.campaign, label: "Pengumuman", isActive: false),
          _navItem(icon: Icons.person, label: "Profile", isActive: true),
        ],
                onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              fadePageRoute(const DashboardPage()),
            );
          }

          if (index == 1) {
            Navigator.pushReplacement(
              context,
              fadePageRoute(const PengumumanPage()),
            );
          }
        },
      ),
    );
  }
}
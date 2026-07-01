import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dashboard_page.dart';
import 'pengumuman_page.dart';
import '../services/auth_service.dart';
import 'register_face_page.dart';

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

    return "http://192.168.1.14:8000/storage/$role/${user?["photo"]}";
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
          prefixIcon: icon != null ? Icon(icon) : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
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
      backgroundColor: const Color(0xffEDEDED),
      body: SafeArea(
        child: user == null
            ? const Center(
                child: CircularProgressIndicator(),
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
                            Color(0xff1E5631),
                            Color(0xff2E7D32),
                          ],
                        ),
                        borderRadius: BorderRadius.only(
                          bottomRight: Radius.circular(60),
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          "Profile Saya",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
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
                                    color: Colors.black.withOpacity(0.08),
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
                                        backgroundColor:
                                            const Color(0xff1E5631),
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
                                                  : const Color(0xffF4D03F),
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
                                                    color: Colors.black,
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
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    (user?["nisn"] ?? user?["nip"] ?? "")
                                        .toString(),
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    user?["kelas"] != null
                                        ? (user?["kelas"]["nama_kelas"] ?? "")
                                            .toString()
                                        : "",
                                    style: TextStyle(
                                      color: Colors.grey[600],
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
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Informasi Akun",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
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
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Keamanan Akun",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
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
                                        backgroundColor:
                                            const Color(0xffF4D03F),
                                        foregroundColor: Colors.black,
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

                            const SizedBox(height: 40),

                          Container(
  padding: const EdgeInsets.all(20),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(24),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [

      const Text(
        "Face ID",
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
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
                : Colors.green,
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
                  builder: (_) => const RegisterFacePage(),
                ),
              );

              // Refresh data user setelah kembali
              await getUser();
            },
            icon: const Icon(Icons.face),
            label: const Text("Daftarkan Face ID"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff1E5631),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],

    ],
  ),
)
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),

      /// ================= BOTTOM NAV =================
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xff1E5631),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          selectedItemColor: const Color(0xffF4D03F),
          unselectedItemColor: Colors.white70,

          currentIndex: 2, // PROFILE aktif

          onTap: (index) {
            if (index == 0) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const DashboardPage(),
                ),
              );
            }

            if (index == 1) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const PengumumanPage(),
                ),
              );
            }
          },

          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: "Home",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.campaign),
              label: "Pengumuman",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: "Profile",
            ),
          ],
        ),
      ),
    );
  }
}

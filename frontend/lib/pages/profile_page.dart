import 'package:flutter/material.dart';
import 'dashboard_page.dart';
import 'pengumuman_page.dart';
import '../services/auth_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {

  Map<String, dynamic>? user;

  Future<void> getUser() async {

  final dataUser = await AuthService.getUser();

  setState(() {
    user = dataUser;

    namaController.text = user?["name"] ?? "";
    nimController.text = user?["nisn"] ?? user?["nip"] ?? "";
    kelasController.text = user?["kelas"] ?? "";
  });

}

@override
void initState() {
  super.initState();
  getUser();
}

  final TextEditingController namaController = TextEditingController();
  final TextEditingController nimController = TextEditingController();
  final TextEditingController kelasController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

 Widget buildTextField(
  String hint,
  TextEditingController controller, {
  bool obscure = false,
  bool readOnly = false,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: controller,
      obscureText: obscure,
      readOnly: readOnly,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: readOnly ? Colors.grey[200] : Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffEDEDED),

      body: SafeArea(
        child: Column(
          children: [

          /// ================= HEADER + PROFILE =================
Stack(
  clipBehavior: Clip.none,
  children: [

    /// HEADER
    Container(
      height: 180,
      decoration: const BoxDecoration(
        color: Color(0xff1E5631),
        borderRadius: BorderRadius.only(
          bottomRight: Radius.circular(60),
        ),
      ),
      child: const Center(
        child: Padding(
          padding: EdgeInsets.only(bottom: 40),
          child: Text(
            "Profile",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    ),

    /// PROFILE
    Positioned(
      bottom: -110,
      left: 0,
      right: 0,
      child: Column(
        children: [

          /// FOTO
          const CircleAvatar(
            radius: 45,
            backgroundImage: NetworkImage(
              "https://i.pravatar.cc/300",
            ),
          ),

          const SizedBox(height: 10),

          /// NAMA
          Text(
          user?["name"] ?? "",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),

          /// NIM
          Text(
          user?["nisn"] ?? user?["nip"] ?? "",
            style: TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),

          /// KELAS
          Text(
          user?["kelas"] ?? "",
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    )
  ],
),

const SizedBox(height: 120),
           

            /// ================= FORM =================
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    const Text(
                      "Ubah Profile Anda",
                      style:
                          TextStyle(fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 10),

                    buildTextField("Nama", namaController, readOnly: true),
                    buildTextField("NIM / NIP", nimController, readOnly: true),
                    buildTextField("Kelas", kelasController, readOnly: true),

                    buildTextField("Password Baru", passwordController, obscure: true),
                    buildTextField(
                      "Konfirmasi Password",
                      confirmPasswordController,
                      obscure: true,
                    ),

                    const SizedBox(height: 10),

                    /// BUTTON SIMPAN
ElevatedButton(
  onPressed: () async {

    // VALIDASI PASSWORD KOSONG
    if (passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Password tidak boleh kosong"),
        ),
      );
      return;
    }

    // VALIDASI PASSWORD SAMA ATAU TIDAK
    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Konfirmasi password tidak sama"),
        ),
      );
      return;
    }

    try {

      await AuthService.updatePassword(passwordController.text);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Password berhasil diubah"),
        ),
      );

      // kosongkan field password
      passwordController.clear();
      confirmPasswordController.clear();

    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal mengubah password: $e"),
        ),
      );

    }
  },

  style: ElevatedButton.styleFrom(
    backgroundColor: const Color(0xffF4D03F),
    foregroundColor: Colors.black,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    ),
    padding: const EdgeInsets.symmetric(
      horizontal: 30,
      vertical: 12,
    ),
  ),

  child: const Text(
    "Simpan",
    style: TextStyle(
      fontWeight: FontWeight.bold,
    ),
  ),
),

                    const SizedBox(height: 20),

                    /// GOOGLE BUTTON
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white,
                      ),
                      child: const Center(
                        child: Text(
                          "Hubungkan Akun Anda ke Google",
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// FACE ID
                    const Center(
                      child: Column(
                        children: [
                          Text(
                            "Face ID",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 10),
                          Icon(Icons.face, size: 50),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
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

          currentIndex: 2,

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
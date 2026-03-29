import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../services/auth_service.dart';
import '../pages/login_page.dart';
import '../models/pengumuman_model.dart';
import '../services/pengumuman_service.dart';
import '../pages/pengumuman_page.dart';
import '../pages/detail_pengumuman_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String formattedDate = "";
  String name = "";
  List<Pengumuman> pengumumanList = [];

  bool isLoadingPengumuman = true;

 Future<void> getUser() async {

  final user = await AuthService.getUser();

  setState(() {
    name = user?["name"] ?? "";
  });

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
              child: const Text("Keluar"),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();

    initializeDate();
    getUser();
    getPengumuman();
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

  @override
  bool isAbsensi = true;
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffEDEDED),

      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              /// ================= HEADER + CARD ABSENSI =================
              Stack(
                clipBehavior: Clip.none,
                children: [
                  /// ================= HEADER HIJAU =================
                  Container(
                    height: 230,
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Color(0xff1E5631),
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
                  Positioned(
                    top: 130,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
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
                                          color: Color(0xff1E5631),
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
                                          color: Color(0xff1E5631),
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
                          isAbsensi ? _absensiView() : _riwayatView(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              /// ================= SPACING =================
              const SizedBox(height: 220),

              /// ================= DATE CARD =================
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xff2E7D32),
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
                        child: CircularProgressIndicator(),
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
                                      color: Colors.black.withOpacity(0.05),
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
                                      borderRadius: const BorderRadius.vertical(
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
                                                const CircularProgressIndicator(),
                                          );
                                        },
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Container(
                                            height: 120,
                                            color: Colors.grey[300],
                                            alignment: Alignment.center,
                                            child: const Icon(
                                              Icons.image_not_supported,
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
                                                        pengumuman: pengumuman,
                                                      ),
                                                    ),
                                                  );
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      const Color(0xffF4D03F),
                                                  foregroundColor: Colors.black,
                                                  elevation: 0,
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 12),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20),
                                                  ),
                                                ),
                                                child: const Text(
                                                  "Lihat Selengkapnya",
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
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
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // ================= MAP =================
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        "assets/images/4.jpg",
                        height: 230,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),

                    // ================= CARD (OVERLAP ±5%) =================
                    Positioned(
                      bottom: -125, // ⬅️ INI YANG NGATUR OVERLAP (±5%)
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xff1E5631),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                              children: const [
                                Icon(Icons.location_on,
                                    color: Colors.white, size: 18),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "Madrasah Aliyah Negeri 1 Ambon",
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: const [
                                Icon(Icons.access_time,
                                    color: Colors.white, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  "Lakukan Absensi Sebelum 06:30",
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 12),
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xffF4D03F),
                                  foregroundColor: Colors.black,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: const Text(
                                  "Lakukan Absensi",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                  height: 150), // ⬅️ WAJIB biar tidak ketimpa konten bawah
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
          onTap: (index) {
            if (index == 1) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PengumumanPage(),
                ),
              );
            }

            if (index == 2) {
              Navigator.pushNamed(context, "/profile");
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

Widget _absensiView() {
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
              Text("Waktu Absensi"),
            ],
          ),
        ],
      ),
      const SizedBox(height: 8),
      const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("Hadir", style: TextStyle(fontWeight: FontWeight.bold)),
          Text("06:36", style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
      const SizedBox(height: 14),
      const Text(
        "Pastikan Anda Melakukan Absensi\nSebelum 07:30",
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12),
      ),
      const SizedBox(height: 16),
      SizedBox(
        width: double.infinity,
        height: 42,
        child: ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xffF4D03F),
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: const Text(
            "Lakukan Absensi",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    ],
  );
}

Widget _riwayatView() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        "Status Kehadiran",
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 4),
      const Text(
        "Hadir",
        style: TextStyle(
          color: Color(0xff2E7D32),
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 16),
      Row(
        children: const [
          Icon(Icons.circle, size: 8, color: Color(0xff2E7D32)),
          Expanded(child: Divider()),
          Icon(Icons.person),
          Expanded(child: Divider()),
          Icon(Icons.circle, size: 8, color: Color(0xff2E7D32)),
        ],
      ),
      const SizedBox(height: 16),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Tanggal", style: TextStyle(fontSize: 12)),
              SizedBox(height: 4),
              Text("Senin 01-08-2026",
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("Waktu Absensi", style: TextStyle(fontSize: 12)),
              SizedBox(height: 4),
              Text("06:30", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
      const SizedBox(height: 20),
      SizedBox(
        width: double.infinity,
        height: 42,
        child: ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xffF4D03F),
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: const Text(
            "Lihat Semua",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    ],
  );
}

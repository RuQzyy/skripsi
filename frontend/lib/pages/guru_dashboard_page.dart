import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/guru_service.dart';
import '../pages/login_page.dart'; // sumber AppColors
import 'guru_riwayat_siswa_page.dart';
import 'guru_riwayat_kelas_page.dart';

class GuruDashboardPage extends StatefulWidget {
  const GuruDashboardPage({super.key});

  @override
  State<GuruDashboardPage> createState() => _GuruDashboardPageState();
}

class _GuruDashboardPageState extends State<GuruDashboardPage> {
  String name = "";
  Map<String, dynamic>? kehadiranData;
  bool isLoading = true;

  // Filter status
  String filterStatus = "Semua";

  List<dynamic> get filteredSiswa {
    final siswa = kehadiranData?["siswa"] ?? [];
    if (filterStatus == "Semua") return siswa;
    return siswa
        .where((s) =>
            (s["status"] ?? "").toString().trim().toLowerCase() ==
            filterStatus.trim().toLowerCase())
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  String getSiswaPhotoUrl(Map<String, dynamic> siswa) {
    if (siswa["photo"] == null || siswa["photo"].toString().isEmpty) {
      return "";
    }
    return "http://192.168.1.48:8000/storage/siswa/${siswa["photo"]}";
  }

  Future<void> _loadData() async {
    final user = await AuthService.getUser();
    setState(() => name = user?["name"] ?? "");

    try {
      final result = await GuruService.getKehadiranHariIni();
      setState(() {
        kehadiranData = result["success"] == true ? result["data"] : null;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Konfirmasi"),
        content: const Text("Apakah anda ingin keluar?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await AuthService.logout();
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.mediumDark,
              foregroundColor: Colors.white,
            ),
            child: const Text("Keluar"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statistik = kehadiranData?["statistik"];
    final namaKelas = kehadiranData?["nama_kelas"] ?? "-";
    final tanggal = kehadiranData?["tanggal"] ?? "";

    String formattedTanggal = "-";
    try {
      formattedTanggal = DateFormat("EEEE, dd MMMM yyyy", "id_ID")
          .format(DateTime.parse(tanggal));
    } catch (_) {}

    return Scaffold(
      backgroundColor: AppColors.lightest,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: AppColors.mediumDark,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                // ===== HEADER =====
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
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
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Hallo, $name",
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                "Wali Kelas",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.history,
                                    color: Colors.white),
                                tooltip: "Riwayat Kehadiran",
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const GuruRiwayatKelasPage(),
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.logout,
                                    color: Colors.white),
                                onPressed: _logout,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Info kelas & tanggal
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.class_,
                                color: Colors.white, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Kelas $namaKelas",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  Text(
                                    formattedTanggal,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                if (isLoading)
                  const Padding(
                    padding: EdgeInsets.only(top: 60),
                    child: CircularProgressIndicator(
                        color: AppColors.mediumDark),
                  )
                else if (kehadiranData == null)
                  const Padding(
                    padding: EdgeInsets.only(top: 60),
                    child: Text("Gagal memuat data kehadiran"),
                  )
                else ...[
                  // ===== STATISTIK =====
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _statCard(
                            "Hadir",
                            statistik?["hadir"] ?? 0,
                            AppColors.mediumDark,
                            Icons.check_circle,
                          ),
                          const SizedBox(width: 10),
                          _statCard(
                            "Terlambat",
                            statistik?["terlambat"] ?? 0,
                            Colors.orange,
                            Icons.access_time,
                          ),
                          const SizedBox(width: 10),
                          _statCard(
                            "Izin",
                            statistik?["izin"] ?? 0,
                            AppColors.medium,
                            Icons.info,
                          ),
                          const SizedBox(width: 10),
                          _statCard(
                            "Sakit",
                            statistik?["sakit"] ?? 0,
                            Colors.purple.shade700,
                            Icons.local_hospital,
                          ),
                          const SizedBox(width: 10),
                          _statCard(
                            "Alpha",
                            statistik?["alpha"] ?? 0,
                            Colors.red.shade900,
                            Icons.remove_circle,
                          ),
                          const SizedBox(width: 10),
                          _statCard(
                            "Belum",
                            statistik?["belum_absen"] ?? 0,
                            Colors.red.shade400,
                            Icons.cancel,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ===== FILTER STATUS =====
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Daftar Siswa",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColors.darkest,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              "Semua",
                              "Hadir",
                              "Terlambat",
                              "Izin",
                              "Sakit",
                              "Alpha",
                              "Belum Absen"
                            ].map((s) {
                              final isActive = filterStatus == s;
                              return GestureDetector(
                                onTap: () => setState(() => filterStatus = s),
                                child: Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? AppColors.mediumDark
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isActive
                                          ? AppColors.mediumDark
                                          : AppColors.light,
                                    ),
                                  ),
                                  child: Text(
                                    s,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isActive
                                          ? Colors.white
                                          : AppColors.darkest,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ===== LIST SISWA =====
                  filteredSiswa.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.only(top: 40),
                          child: Column(
                            children: [
                              Icon(Icons.search_off,
                                  size: 48, color: AppColors.light),
                              SizedBox(height: 8),
                              Text(
                                "Tidak ada siswa",
                                style: TextStyle(color: Colors.black45),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: filteredSiswa.length,
                          itemBuilder: (context, index) {
                            final siswa = filteredSiswa[index];
                            return _siswaCard(siswa);
                          },
                        ),

                  const SizedBox(height: 24),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statCard(String label, int value, Color color, IconData icon) {
    return SizedBox(
      width: 82,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.darkest.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              "$value",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _siswaCard(Map<String, dynamic> siswa) {
    final String status = siswa["status"] ?? "Belum Absen";
    final String jam = (siswa["jam_masuk"] ?? "").toString().length >= 5
        ? siswa["jam_masuk"].toString().substring(0, 5)
        : "-";

    Color statusColor;
    IconData statusIcon;
    switch (status.toLowerCase()) {
      case "hadir":
        statusColor = AppColors.mediumDark;
        statusIcon = Icons.check_circle;
        break;
      case "terlambat":
        statusColor = Colors.orange;
        statusIcon = Icons.access_time;
        break;
      case "izin":
        statusColor = AppColors.medium;
        statusIcon = Icons.info;
        break;
      case "sakit":
        statusColor = Colors.purple.shade700;
        statusIcon = Icons.local_hospital;
        break;
      case "alpha":
        statusColor = Colors.red.shade900;
        statusIcon = Icons.remove_circle;
        break;
      default:
        statusColor = Colors.red.shade400;
        statusIcon = Icons.cancel;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GuruRiwayatSiswaPage(
              siswaId: siswa["id"],
              siswaName: siswa["name"] ?? "-",
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.darkest.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.mediumDark.withOpacity(0.1),
              backgroundImage: (siswa["photo"] != null &&
                      siswa["photo"].toString().isNotEmpty)
                  ? NetworkImage(getSiswaPhotoUrl(siswa))
                  : null,
              child:
                  (siswa["photo"] == null || siswa["photo"].toString().isEmpty)
                      ? Text(
                          (siswa["name"] ?? "?")
                              .toString()
                              .substring(0, 1)
                              .toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.mediumDark,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
            ),
            const SizedBox(width: 12),
            // Info siswa
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    siswa["name"] ?? "-",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkest,
                    ),
                  ),
                  Text(
                    siswa["nisn"] ?? "-",
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black45,
                    ),
                  ),
                ],
              ),
            ),
            // Status & jam
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 13, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      status,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
                if (jam != "-")
                  Text(
                    jam,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black45,
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, color: AppColors.light, size: 18),
          ],
        ),
      ),
    );
  }
}
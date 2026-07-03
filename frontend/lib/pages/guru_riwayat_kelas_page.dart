import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/guru_service.dart';
import 'guru_riwayat_siswa_page.dart';

class GuruRiwayatKelasPage extends StatefulWidget {
  const GuruRiwayatKelasPage({super.key});

  @override
  State<GuruRiwayatKelasPage> createState() => _GuruRiwayatKelasPageState();
}

class _GuruRiwayatKelasPageState extends State<GuruRiwayatKelasPage> {
  List<dynamic> dataList = [];
  String namaKelas = "";
  bool isLoading = true;

  // Index tanggal yang sedang di-expand
  int? expandedIndex;

  // Filter status di dalam detail tanggal
  String filterStatus = "Semua";

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  String getSiswaPhotoUrl(Map<String, dynamic> siswa) {
    if (siswa["photo"] == null || siswa["photo"].toString().isEmpty) {
      return "";
    }
    return "http://192.168.1.14:8000/storage/siswa/${siswa["photo"]}";
  }

  Future<void> _loadData() async {
    try {
      final result = await GuruService.getKehadiranPerTanggal();
      if (result["success"] == true) {
        setState(() {
          namaKelas = result["nama_kelas"] ?? "";
          dataList = result["data"] ?? [];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  List<dynamic> _filteredSiswa(List<dynamic> siswaList) {
    if (filterStatus == "Semua") return siswaList;
    return siswaList
        .where((s) =>
            (s["status"] ?? "").toString().trim().toLowerCase() ==
            filterStatus.trim().toLowerCase())
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffEDEDED),
      body: SafeArea(
        child: Column(
          children: [
            // ===== HEADER =====
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(8, 16, 20, 24),
              decoration: const BoxDecoration(
                color: Color(0xff1E5631),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Riwayat Kehadiran",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          "Kelas $namaKelas",
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

            const SizedBox(height: 12),

            // ===== FILTER STATUS (selalu tampil) =====
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children:
                      ["Semua", "Hadir", "Terlambat", "Belum Absen"].map((s) {
                    final isActive = filterStatus == s;
                    return GestureDetector(
                      onTap: () => setState(() => filterStatus = s),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color:
                              isActive ? const Color(0xff1E5631) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isActive
                                ? const Color(0xff1E5631)
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Text(
                          s,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isActive ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ===== LIST =====
            Expanded(
              child: isLoading
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: Color(0xff1E5631)),
                    )
                  : dataList.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.history,
                                  size: 56, color: Colors.grey.shade300),
                              const SizedBox(height: 8),
                              const Text(
                                "Belum ada riwayat kehadiran",
                                style: TextStyle(color: Colors.black45),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          color: const Color(0xff1E5631),
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 4),
                            itemCount: dataList.length,
                            itemBuilder: (context, index) {
                              final item = dataList[index];
                              final statistik = item["statistik"];
                              final siswaList =
                                  List<dynamic>.from(item["siswa"] ?? []);
                              final filtered = _filteredSiswa(siswaList);
                              final isExpanded = expandedIndex == index;

                              String tanggal = "-";
                              try {
                                tanggal =
                                    DateFormat("EEEE, dd MMMM yyyy", "id_ID")
                                        .format(DateTime.parse(
                                            item["tanggal"].toString()));
                              } catch (_) {}

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    // HEADER TANGGAL (selalu tampil, bisa di-tap)
                                    InkWell(
                                      borderRadius: BorderRadius.circular(16),
                                      onTap: () {
                                        setState(() {
                                          expandedIndex =
                                              isExpanded ? null : index;
                                        });
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(14),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.calendar_today,
                                                  size: 14,
                                                  color: Color(0xff1E5631),
                                                ),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    tanggal,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ),
                                                Icon(
                                                  isExpanded
                                                      ? Icons.expand_less
                                                      : Icons.expand_more,
                                                  color: Colors.black38,
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 10),
                                            // Mini statistik
                                            Row(
                                              children: [
                                                _miniChip(
                                                  "Hadir ${statistik["hadir"] ?? 0}",
                                                  const Color(0xff1E5631),
                                                ),
                                                const SizedBox(width: 6),
                                                _miniChip(
                                                  "Terlambat ${statistik["terlambat"] ?? 0}",
                                                  Colors.orange,
                                                ),
                                                const SizedBox(width: 6),
                                                _miniChip(
                                                  "Belum ${statistik["belum_absen"] ?? 0}",
                                                  Colors.red.shade400,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    // DETAIL SISWA (hanya tampil kalau expand)
                                    if (isExpanded) ...[
                                      const Divider(height: 1),
                                      if (filtered.isEmpty)
                                        Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Center(
                                            child: Text(
                                              "Tidak ada siswa dengan status \"$filterStatus\"",
                                              style: const TextStyle(
                                                  color: Colors.black45,
                                                  fontSize: 12),
                                            ),
                                          ),
                                        )
                                      else
                                        ...filtered.map((siswa) {
                                          final status = siswa["status"] ?? "-";
                                          final jam = (siswa["jam_masuk"] ?? "")
                                                      .toString()
                                                      .length >=
                                                  5
                                              ? siswa["jam_masuk"]
                                                  .toString()
                                                  .substring(0, 5)
                                              : "-";
                                          final isHadir =
                                              status.toLowerCase() == "hadir";
                                          final isTerlambat =
                                              status.toLowerCase() ==
                                                  "terlambat";

                                          Color statusColor;
                                          if (isHadir) {
                                            statusColor =
                                                const Color(0xff1E5631);
                                          } else if (isTerlambat) {
                                            statusColor = Colors.orange;
                                          } else {
                                            statusColor = Colors.red.shade400;
                                          }

                                          return GestureDetector(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      GuruRiwayatSiswaPage(
                                                    siswaId: siswa["id"],
                                                    siswaName:
                                                        siswa["name"] ?? "-",
                                                  ),
                                                ),
                                              );
                                            },
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 14,
                                                      vertical: 10),
                                              decoration: BoxDecoration(
                                                border: Border(
                                                  bottom: BorderSide(
                                                    color: Colors.grey.shade100,
                                                  ),
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  // Strip warna kiri
                                                  Container(
                                                    width: 3,
                                                    height: 36,
                                                    decoration: BoxDecoration(
                                                      color: statusColor,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              2),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  // Avatar inisial
                                                  CircleAvatar(
                                                    radius: 16,
                                                    backgroundColor: statusColor
                                                        .withOpacity(0.1),
                                                    backgroundImage: (siswa[
                                                                    "photo"] !=
                                                                null &&
                                                            siswa["photo"]
                                                                .toString()
                                                                .isNotEmpty)
                                                        ? NetworkImage(
                                                            getSiswaPhotoUrl(
                                                                siswa))
                                                        : null,
                                                    child: (siswa["photo"] ==
                                                                null ||
                                                            siswa["photo"]
                                                                .toString()
                                                                .isEmpty)
                                                        ? Text(
                                                            (siswa["name"] ??
                                                                    "?")
                                                                .toString()
                                                                .substring(0, 1)
                                                                .toUpperCase(),
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color:
                                                                  statusColor,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          )
                                                        : null,
                                                  ),
                                                  const SizedBox(width: 10),
                                                  // Nama
                                                  Expanded(
                                                    child: Text(
                                                      siswa["name"] ?? "-",
                                                      style: const TextStyle(
                                                          fontSize: 13),
                                                    ),
                                                  ),
                                                  // Status & jam
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.end,
                                                    children: [
                                                      Text(
                                                        status,
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: statusColor,
                                                        ),
                                                      ),
                                                      if (jam != "-")
                                                        Text(
                                                          jam,
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 11,
                                                            color:
                                                                Colors.black45,
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        }),
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/guru_service.dart';
import 'guru_riwayat_siswa_page.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

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
  bool isDownloading = false;
  

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  String getSiswaPhotoUrl(Map<String, dynamic> siswa) {
    if (siswa["photo"] == null || siswa["photo"].toString().isEmpty) {
      return "";
    }
    return "http://192.168.1.12:8000/storage/siswa/${siswa["photo"]}";
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

  Future<void> _pilihDanUnduhLaporan() async {
    DateTime bulanAwal = DateTime(DateTime.now().year, DateTime.now().month);
    DateTime bulanAkhir = DateTime(DateTime.now().year, DateTime.now().month);

    final result = await showDialog<Map<String, DateTime>>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text("Unduh Rekap Absensi"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Dari Bulan",
                      style: TextStyle(fontSize: 12, color: Colors.black54)),
                  const SizedBox(height: 6),
                  _bulanDropdown(
                    value: bulanAwal,
                    onChanged: (v) => setDialogState(() => bulanAwal = v),
                  ),
                  const SizedBox(height: 16),
                  const Text("Sampai Bulan",
                      style: TextStyle(fontSize: 12, color: Colors.black54)),
                  const SizedBox(height: 6),
                  _bulanDropdown(
                    value: bulanAkhir,
                    onChanged: (v) => setDialogState(() => bulanAkhir = v),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Batal"),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (bulanAkhir.isBefore(bulanAwal)) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                          content: Text(
                              "Bulan akhir tidak boleh sebelum bulan awal"),
                        ),
                      );
                      return;
                    }
                    Navigator.pop(ctx, {"awal": bulanAwal, "akhir": bulanAkhir});
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff1E5631)),
                  child:
                      const Text("Unduh", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) return;

    setState(() => isDownloading = true);

    final bulanAwalStr = DateFormat("yyyy-MM").format(result["awal"]!);
    final bulanAkhirStr = DateFormat("yyyy-MM").format(result["akhir"]!);

    final res = await GuruService.downloadLaporanAbsensi(
      bulanAwal: bulanAwalStr,
      bulanAkhir: bulanAkhirStr,
    );

    if (!mounted) return;
    setState(() => isDownloading = false);

    if (res["success"] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Laporan berhasil diunduh")),
      );
      OpenFilex.open(res["path"]);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res["message"] ?? "Gagal mengunduh laporan")),
      );
    }
  }

  Widget _bulanDropdown({
    required DateTime value,
    required ValueChanged<DateTime> onChanged,
  }) {
    final now = DateTime.now();
    final List<DateTime> options = List.generate(24, (i) {
      final d = DateTime(now.year, now.month - i);
      return DateTime(d.year, d.month);
    });

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<DateTime>(
          value: options.firstWhere(
            (o) => o.year == value.year && o.month == value.month,
            orElse: () => options.first,
          ),
          isExpanded: true,
          items: options.map((d) {
            return DropdownMenuItem(
              value: d,
              child: Text(DateFormat("MMMM yyyy", "id_ID").format(d)),
            );
          }).toList(),
          onChanged: (d) {
            if (d != null) onChanged(d);
          },
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
                  isDownloading
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(Icons.download_rounded,
                              color: Colors.white),
                          tooltip: "Unduh Rekap Absensi",
                          onPressed: _pilihDanUnduhLaporan,
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
                                            SingleChildScrollView(
                                              scrollDirection: Axis.horizontal,
                                              child: Row(
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
                                                    "Izin ${statistik["izin"] ?? 0}",
                                                    Colors.blue.shade700,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  _miniChip(
                                                    "Sakit ${statistik["sakit"] ?? 0}",
                                                    Colors.purple.shade700,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  _miniChip(
                                                    "Alpha ${statistik["alpha"] ?? 0}",
                                                    Colors.red.shade900,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  _miniChip(
                                                    "Belum ${statistik["belum_absen"] ?? 0}",
                                                    Colors.red.shade400,
                                                  ),
                                                ],
                                              ),
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
                                          Color statusColor;
                                          switch (status.toLowerCase()) {
                                            case "hadir":
                                              statusColor =
                                                  const Color(0xff1E5631);
                                              break;
                                            case "terlambat":
                                              statusColor = Colors.orange;
                                              break;
                                            case "izin":
                                              statusColor =
                                                  Colors.blue.shade700;
                                              break;
                                            case "sakit":
                                              statusColor =
                                                  Colors.purple.shade700;
                                              break;
                                            case "alpha":
                                              statusColor =
                                                  Colors.red.shade900;
                                              break;
                                            default:
                                              statusColor =
                                                  Colors.red.shade400;
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
                                                      if (status.toLowerCase() ==
                                                              "izin" &&
                                                          (siswa["catatan"] ??
                                                                  "")
                                                              .toString()
                                                              .isNotEmpty)
                                                        Text(
                                                          siswa["catatan"],
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 10,
                                                            color:
                                                                Colors.black38,
                                                          ),
                                                          maxLines: 1,
                                                          overflow:
                                                              TextOverflow
                                                                  .ellipsis,
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

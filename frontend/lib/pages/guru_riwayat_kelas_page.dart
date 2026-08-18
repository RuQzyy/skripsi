import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/guru_service.dart';
import '../pages/login_page.dart'; // sumber AppColors
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
  bool isDownloading = false;

  /// Bulan yang sedang ditampilkan di kalender
  DateTime displayedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  /// Tanggal yang sedang dipilih (untuk menampilkan detail di bawah kalender)
  DateTime? selectedDate;

  /// Filter status di dalam detail tanggal
  String filterStatus = "Semua";

  /// Lookup cepat: "yyyy-MM-dd" -> data item hari itu
  Map<String, dynamic> get _dataByDate {
    final map = <String, dynamic>{};
    for (final item in dataList) {
      try {
        final d = DateTime.parse(item["tanggal"].toString()).toLocal();
        map[_dateKey(d)] = item;
      } catch (_) {}
    }
    return map;
  }

  String _dateKey(DateTime d) => DateFormat("yyyy-MM-dd").format(d);

  Map<String, dynamic>? get _selectedItem {
    if (selectedDate == null) return null;
    return _dataByDate[_dateKey(selectedDate!)];
  }

  List<dynamic> get _filteredSiswaSelected {
    final list = List<dynamic>.from(_selectedItem?["siswa"] ?? []);
    if (filterStatus == "Semua") return list;
    return list
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
    try {
      final result = await GuruService.getKehadiranPerTanggal();
      if (result["success"] == true) {
        setState(() {
          namaKelas = result["nama_kelas"] ?? "";
          dataList = result["data"] ?? [];
          isLoading = false;
        });

        // Otomatis pilih tanggal terbaru yang ada datanya, jika belum ada pilihan
        if (selectedDate == null && _dataByDate.isNotEmpty) {
          final latestKey = (_dataByDate.keys.toList()..sort()).last;
          final latestDate = DateTime.parse(latestKey);
          setState(() {
            selectedDate = latestDate;
            displayedMonth = DateTime(latestDate.year, latestDate.month);
          });
        }
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
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
                    backgroundColor: AppColors.mediumDark,
                  ),
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
        border: Border.all(color: AppColors.light),
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

  void _gantiBulan(int delta) {
    setState(() {
      displayedMonth = DateTime(
        displayedMonth.year,
        displayedMonth.month + delta,
      );
    });
  }

  // ==========================================================
  // HELPER: HITUNG PERSENTASE KEHADIRAN & WARNA
  // ==========================================================

  int _toInt(dynamic v) => int.tryParse(v?.toString() ?? '') ?? 0;

  /// Menghitung persentase kehadiran efektif (Hadir + Terlambat) dari total siswa
  /// pada hari tersebut. Mengembalikan -1 jika tidak ada data / total siswa 0.
  double _attendancePercent(Map<String, dynamic> item) {
    final statistik = item["statistik"] ?? {};
    final hadir = _toInt(statistik["hadir"]);
    final terlambat = _toInt(statistik["terlambat"]);
    final izin = _toInt(statistik["izin"]);
    final sakit = _toInt(statistik["sakit"]);
    final alpha = _toInt(statistik["alpha"]);
    final bolos = _toInt(statistik["bolos"]);
    final belumAbsen = _toInt(statistik["belum_absen"]);

    final total = hadir + terlambat + izin + sakit + alpha + bolos + belumAbsen;
    if (total == 0) return -1;

    final hadirEfektif = hadir + terlambat;
    return (hadirEfektif / total) * 100;
  }

  /// Warna berdasarkan persentase kehadiran (heatmap).
  Color _attendanceColor(double percent) {
    if (percent < 0) return Colors.transparent;
    if (percent >= 90) return const Color(0xFF2E7D32); // hijau tua - sangat baik
    if (percent >= 75) return const Color(0xFF66BB6A); // hijau muda - baik
    if (percent >= 50) return const Color(0xFFFFA726); // oranye - waspada
    return const Color(0xFFE53935); // merah - rendah
  }

  String _attendanceLabel(double percent) {
    if (percent < 0) return "-";
    return "${percent.toStringAsFixed(0)}%";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightest,
      body: SafeArea(
        child: Column(
          children: [
            // ===== HEADER =====
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(8, 16, 20, 24),
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

            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.mediumDark),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      color: AppColors.mediumDark,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildCalendarCard(),
                            const SizedBox(height: 10),
                            _buildLegend(),
                            const SizedBox(height: 20),
                            _buildDetailSection(),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // LEGEND WARNA KEHADIRAN
  // ==========================================================
  Widget _buildLegend() {
    final items = [
      {"label": "≥ 90%", "color": _attendanceColor(90)},
      {"label": "75–89%", "color": _attendanceColor(75)},
      {"label": "50–74%", "color": _attendanceColor(50)},
      {"label": "< 50%", "color": _attendanceColor(0)},
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: items.map((it) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: it["color"] as Color,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              it["label"] as String,
              style: const TextStyle(fontSize: 11, color: Colors.black45),
            ),
          ],
        );
      }).toList(),
    );
  }

  // ==========================================================
  // KALENDER
  // ==========================================================
  Widget _buildCalendarCard() {
    final firstDayOfMonth =
        DateTime(displayedMonth.year, displayedMonth.month, 1);
    final daysInMonth =
        DateTime(displayedMonth.year, displayedMonth.month + 1, 0).day;

    // weekday: Senin = 1 ... Minggu = 7
    final leadingBlanks = firstDayOfMonth.weekday - 1;

    final totalCells = leadingBlanks + daysInMonth;
    final rowCount = (totalCells / 7).ceil();

    final today = DateTime.now();
    final byDate = _dataByDate;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkest.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header bulan + navigasi
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: AppColors.darkest),
                onPressed: () => _gantiBulan(-1),
              ),
              Text(
                DateFormat("MMMM yyyy", "id_ID").format(displayedMonth),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.darkest,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: AppColors.darkest),
                onPressed: () => _gantiBulan(1),
              ),
            ],
          ),

          const SizedBox(height: 4),

          // Label hari
          Row(
            children: ["Sen", "Sel", "Rab", "Kam", "Jum", "Sab", "Min"]
                .map(
                  (d) => Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: (d == "Sab" || d == "Min")
                              ? AppColors.medium
                              : Colors.black45,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),

          const SizedBox(height: 6),

          // Grid tanggal
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: rowCount * 7,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) {
              final dayNumber = index - leadingBlanks + 1;
              if (dayNumber < 1 || dayNumber > daysInMonth) {
                return const SizedBox.shrink();
              }

              final date = DateTime(
                displayedMonth.year,
                displayedMonth.month,
                dayNumber,
              );
              final key = _dateKey(date);
              final item = byDate[key];
              final hasData = item != null;
              final percent = hasData ? _attendancePercent(item) : -1.0;
              final attendanceColor = _attendanceColor(percent);

              final isSelected = selectedDate != null &&
                  _dateKey(selectedDate!) == key;
              final isToday = _dateKey(today) == key;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedDate = date;
                    filterStatus = "Semua";
                  });
                },
                child: Tooltip(
                  message: hasData
                      ? "Kehadiran: ${_attendanceLabel(percent)}"
                      : "Tidak ada data",
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.mediumDark
                          : hasData
                              ? attendanceColor.withOpacity(0.18)
                              : isToday
                                  ? AppColors.light.withOpacity(0.4)
                                  : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: (hasData && !isSelected)
                          ? Border.all(
                              color: attendanceColor.withOpacity(0.7),
                              width: 1,
                            )
                          : (isToday && !isSelected
                              ? Border.all(
                                  color: AppColors.mediumDark.withOpacity(0.5),
                                  width: 1,
                                )
                              : null),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "$dayNumber",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : hasData
                                    ? attendanceColor
                                    : AppColors.darkest,
                          ),
                        ),
                        const SizedBox(height: 2),
                        if (hasData)
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? Colors.white
                                  : attendanceColor,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // DETAIL TANGGAL TERPILIH
  // ==========================================================
  Widget _buildDetailSection() {
    if (selectedDate == null) {
      return const Padding(
        padding: EdgeInsets.only(top: 20),
        child: Center(
          child: Text(
            "Pilih tanggal pada kalender untuk melihat detail",
            style: TextStyle(color: Colors.black45, fontSize: 12),
          ),
        ),
      );
    }

    final item = _selectedItem;
    final formattedTanggal =
        DateFormat("EEEE, dd MMMM yyyy", "id_ID").format(selectedDate!);

    if (item == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            formattedTanggal,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: AppColors.darkest,
            ),
          ),
          const SizedBox(height: 24),
          const Center(
            child: Column(
              children: [
                Icon(Icons.event_busy, size: 48, color: AppColors.light),
                SizedBox(height: 8),
                Text(
                  "Tidak ada data absensi pada tanggal ini",
                  style: TextStyle(color: Colors.black45, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      );
    }

    final statistik = item["statistik"];
    final percent = _attendancePercent(item);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              formattedTanggal,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppColors.darkest,
              ),
            ),
            if (percent >= 0)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _attendanceColor(percent).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "Kehadiran ${_attendanceLabel(percent)}",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _attendanceColor(percent),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),

        // Mini statistik
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _miniChip("Hadir ${statistik?["hadir"] ?? 0}",
                  AppColors.mediumDark),
              const SizedBox(width: 6),
              _miniChip(
                  "Terlambat ${statistik?["terlambat"] ?? 0}", Colors.orange),
              const SizedBox(width: 6),
              _miniChip("Izin ${statistik?["izin"] ?? 0}", AppColors.medium),
              const SizedBox(width: 6),
              _miniChip(
                  "Sakit ${statistik?["sakit"] ?? 0}", Colors.purple.shade700),
              const SizedBox(width: 6),
              _miniChip(
                  "Alpha ${statistik?["alpha"] ?? 0}", Colors.red.shade900),
              const SizedBox(width: 6),
              _miniChip(
                  "Bolos ${statistik?["bolos"] ?? 0}", Colors.brown.shade600),
              const SizedBox(width: 6),
              _miniChip("Belum ${statistik?["belum_absen"] ?? 0}",
                  Colors.red.shade400),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Filter status
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
              "Bolos",
              "Belum Absen"
            ].map((s) {
              final isActive = filterStatus == s;
              return GestureDetector(
                onTap: () => setState(() => filterStatus = s),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.mediumDark : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isActive ? AppColors.mediumDark : AppColors.light,
                    ),
                  ),
                  child: Text(
                    s,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isActive ? Colors.white : AppColors.darkest,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 14),

        // Daftar siswa
        _filteredSiswaSelected.isEmpty
            ? Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Center(
                  child: Text(
                    "Tidak ada siswa dengan status \"$filterStatus\"",
                    style: const TextStyle(
                        color: Colors.black45, fontSize: 12),
                  ),
                ),
              )
            : Column(
                children: _filteredSiswaSelected.map((siswa) {
                  final status = siswa["status"] ?? "-";
                  final jam =
                      (siswa["jam_masuk"] ?? "").toString().length >= 5
                          ? siswa["jam_masuk"].toString().substring(0, 5)
                          : "-";
                  Color statusColor;
                  switch (status.toLowerCase()) {
                    case "hadir":
                      statusColor = AppColors.mediumDark;
                      break;
                    case "terlambat":
                      statusColor = Colors.orange;
                      break;
                    case "izin":
                      statusColor = AppColors.medium;
                      break;
                    case "sakit":
                      statusColor = Colors.purple.shade700;
                      break;
                    case "alpha":
                      statusColor = Colors.red.shade900;
                      break;
                    case "bolos":
                      statusColor = Colors.brown.shade600;
                      break;
                    default:
                      statusColor = Colors.red.shade400;
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
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.darkest.withOpacity(0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Strip warna kiri
                          Container(
                            width: 3,
                            height: 36,
                            decoration: BoxDecoration(
                              color: statusColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Avatar inisial
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: statusColor.withOpacity(0.1),
                            backgroundImage: (siswa["photo"] != null &&
                                    siswa["photo"].toString().isNotEmpty)
                                ? NetworkImage(getSiswaPhotoUrl(siswa))
                                : null,
                            child: (siswa["photo"] == null ||
                                    siswa["photo"].toString().isEmpty)
                                ? Text(
                                    (siswa["name"] ?? "?")
                                        .toString()
                                        .substring(0, 1)
                                        .toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: statusColor,
                                      fontWeight: FontWeight.bold,
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
                                fontSize: 13,
                                color: AppColors.darkest,
                              ),
                            ),
                          ),
                          // Status & jam
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                status,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: statusColor,
                                ),
                              ),
                              if (jam != "-")
                                Text(
                                  jam,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.black45,
                                  ),
                                ),
                              if (status.toLowerCase() == "izin" &&
                                  (siswa["catatan"] ?? "")
                                      .toString()
                                      .isNotEmpty)
                                Text(
                                  siswa["catatan"],
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.black38,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
      ],
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
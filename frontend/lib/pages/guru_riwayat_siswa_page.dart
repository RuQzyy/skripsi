import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/guru_service.dart';
import '../pages/login_page.dart'; // sumber AppColors

class GuruRiwayatSiswaPage extends StatefulWidget {
  final int siswaId;
  final String siswaName;

  const GuruRiwayatSiswaPage({
    super.key,
    required this.siswaId,
    required this.siswaName,
  });

  @override
  State<GuruRiwayatSiswaPage> createState() => _GuruRiwayatSiswaPageState();
}

class _GuruRiwayatSiswaPageState extends State<GuruRiwayatSiswaPage> {
  Map<String, dynamic>? data; // menyimpan info siswa & statistik (dari page 1)
  List<dynamic> riwayatList = []; // akumulasi seluruh riwayat yang sudah dimuat

  bool isLoading = true; // loading awal (full screen)
  bool isLoadingMore = false; // loading saat fetch halaman berikutnya
  bool hasMore = true; // masih ada halaman selanjutnya atau tidak

  int currentPage = 1;
  static const int _scrollThreshold = 200; // px dari bawah untuk trigger load

  final ScrollController _scrollController = ScrollController();

  String filterStatus = "Semua";

  List<dynamic> get filteredRiwayat {
    if (filterStatus == "Semua") return riwayatList;
    return riwayatList
        .where((r) =>
            (r["status"] ?? "").toString().trim().toLowerCase() ==
            filterStatus.trim().toLowerCase())
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _loadData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - _scrollThreshold &&
        !isLoading &&
        !isLoadingMore &&
        hasMore) {
      _loadMore();
    }
  }

  /// Load awal / refresh — reset ke halaman 1
  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
      currentPage = 1;
      hasMore = true;
      riwayatList = [];
    });

    try {
      final result =
          await GuruService.getRiwayatSiswa(widget.siswaId, page: 1);

      if (result["success"] == true) {
        final resData = result["data"];
        final items = List<dynamic>.from(resData?["riwayat"] ?? []);
        final respCurrentPage = resData?["current_page"] ?? 1;
        final respLastPage = resData?["last_page"] ?? 1;

        setState(() {
          data = resData;
          riwayatList = items;
          currentPage = respCurrentPage;
          hasMore = respCurrentPage < respLastPage;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          hasMore = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        hasMore = false;
      });
    }
  }

  /// Fetch halaman berikutnya lalu append ke list yang sudah ada
  Future<void> _loadMore() async {
    if (isLoadingMore || !hasMore) return;

    setState(() => isLoadingMore = true);

    try {
      final nextPage = currentPage + 1;
      final result = await GuruService.getRiwayatSiswa(
        widget.siswaId,
        page: nextPage,
      );

      if (!mounted) return;

      if (result["success"] == true) {
        final resData = result["data"];
        final newItems = List<dynamic>.from(resData?["riwayat"] ?? []);
        final respCurrentPage = resData?["current_page"] ?? nextPage;
        final respLastPage = resData?["last_page"] ?? respCurrentPage;

        setState(() {
          riwayatList.addAll(newItems);
          currentPage = respCurrentPage;
          hasMore = respCurrentPage < respLastPage;
          isLoadingMore = false;
        });
      } else {
        setState(() {
          isLoadingMore = false;
          hasMore = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoadingMore = false);
    }
  }

  Future<void> _ubahStatus(Map<String, dynamic> item) async {
    final currentStatus = (item["status"] ?? "").toString();
    final absensiId = item["id"];

    if (absensiId == null) return;

    final statusOptions = [
      "Hadir",
      "Terlambat",
      "Izin",
      "Sakit",
      "Alpha",
      "Bolos"
    ];
    String? tempSelected = statusOptions.firstWhere(
      (s) => s.toLowerCase() == currentStatus.toLowerCase(),
      orElse: () => statusOptions.first,
    );
    final catatanController =
        TextEditingController(text: item["catatan"] ?? "");

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text("Ubah Status Kehadiran"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...statusOptions.map((s) {
                      return RadioListTile<String>(
                        value: s,
                        groupValue: tempSelected,
                        title: Text(s),
                        activeColor: AppColors.mediumDark,
                        onChanged: (v) =>
                            setDialogState(() => tempSelected = v),
                      );
                    }),
                    if (tempSelected == "Izin") ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: catatanController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: "Catatan Izin",
                          hintText: "Contoh: Acara keluarga",
                          border: OutlineInputBorder(
                            borderSide: const BorderSide(
                              color: AppColors.light,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                              color: AppColors.mediumDark,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Batal"),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (tempSelected == "Izin" &&
                        catatanController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                            content: Text("Catatan izin wajib diisi")),
                      );
                      return;
                    }
                    Navigator.pop(ctx, {
                      "status": tempSelected ?? currentStatus,
                      "catatan": catatanController.text.trim(),
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.mediumDark,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Simpan"),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) return;

    final selectedStatus = result["status"]!;
    if (selectedStatus.toLowerCase() == currentStatus.toLowerCase() &&
        (item["catatan"] ?? "") == result["catatan"]) {
      return;
    }

    final res = await GuruService.updateStatusAbsensi(
      absensiId: absensiId,
      status: selectedStatus,
      catatan: selectedStatus == "Izin" ? result["catatan"] : null,
    );

    if (!mounted) return;

    if (res["success"] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Status berhasil diubah")),
      );
      // Reload dari halaman 1 supaya data & statistik sinkron kembali
      _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res["message"] ?? "Gagal mengubah status")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final statistik = data?["statistik"];

    return Scaffold(
      backgroundColor: AppColors.lightest,
      body: SafeArea(
        child: Column(
          children: [
            // HEADER
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.siswaName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              data?["siswa"]?["nisn"] ?? "-",
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

                  if (statistik != null) ...[
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _miniStat("Hadir",
                                (statistik["hadir"] ?? 0) as int, Colors.white),
                            _miniDivider(),
                            _miniStat("Terlambat",
                                (statistik["terlambat"] ?? 0) as int,
                                Colors.orange.shade200),
                            _miniDivider(),
                            _miniStat("Izin",
                                (statistik["izin"] ?? 0) as int,
                                AppColors.light),
                            _miniDivider(),
                            _miniStat("Sakit",
                                (statistik["sakit"] ?? 0) as int,
                                Colors.purple.shade200),
                            _miniDivider(),
                            _miniStat("Alpha",
                                (statistik["alpha"] ?? 0) as int,
                                Colors.red.shade200),
                            _miniDivider(),
                            _miniStat("Bolos",
                                (statistik["bolos"] ?? 0) as int,
                                Colors.brown.shade200),
                            _miniDivider(),
                            _miniStat("Total",
                                (statistik["total"] ?? 0) as int,
                                Colors.white70),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // FILTER
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
                    "Bolos"
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
                            color: isActive ? Colors.white : AppColors.darkest,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            if (filterStatus != "Semua")
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 20, right: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    hasMore
                        ? "Filter hanya berlaku pada data yang sudah dimuat"
                        : "",
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.black38,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 12),

            // LIST (Infinite Scroll)
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.mediumDark),
                    )
                  : riwayatList.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.history,
                                  size: 48, color: AppColors.light),
                              const SizedBox(height: 8),
                              const Text(
                                "Belum ada riwayat absensi",
                                style: TextStyle(color: Colors.black45),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          color: AppColors.mediumDark,
                          child: filteredRiwayat.isEmpty
                              ? ListView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  children: [
                                    SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height *
                                              0.5,
                                      child: Center(
                                        child: Text(
                                          "Tidak ada riwayat dengan status \"$filterStatus\"",
                                          style: const TextStyle(
                                              color: Colors.black45,
                                              fontSize: 12),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : ListView.builder(
                                  controller: _scrollController,
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 20),
                                  itemCount: filteredRiwayat.length +
                                      (hasMore ? 1 : 0),
                                  itemBuilder: (context, index) {
                                    // Item terakhir = indikator loading / trigger load more
                                    if (index >= filteredRiwayat.length) {
                                      return Padding(
                                        padding:
                                            const EdgeInsets.symmetric(
                                                vertical: 20),
                                        child: Center(
                                          child: isLoadingMore
                                              ? const SizedBox(
                                                  width: 22,
                                                  height: 22,
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color:
                                                        AppColors.mediumDark,
                                                  ),
                                                )
                                              : const SizedBox.shrink(),
                                        ),
                                      );
                                    }

                                    final item = filteredRiwayat[index];

                                    String tanggal = "-";
                                    try {
                                      tanggal = DateFormat(
                                              "EEEE, dd MMM yyyy", "id_ID")
                                          .format(DateTime.parse(
                                                  item["tanggal"].toString())
                                              .toLocal());
                                    } catch (_) {}

                                    final jam = (item["jam_masuk"] ?? "")
                                                .toString()
                                                .length >=
                                            5
                                        ? item["jam_masuk"]
                                            .toString()
                                            .substring(0, 5)
                                        : "-";
                                    final status = item["status"] ?? "-";

                                    Color itemColor;
                                    switch (status.toLowerCase()) {
                                      case "hadir":
                                        itemColor = AppColors.mediumDark;
                                        break;
                                      case "alpha":
                                        itemColor = Colors.red.shade900;
                                        break;
                                      case "izin":
                                        itemColor = AppColors.medium;
                                        break;
                                      case "sakit":
                                        itemColor = Colors.purple.shade700;
                                        break;
                                      case "bolos":
                                        itemColor = Colors.brown.shade600;
                                        break;
                                      case "terlambat":
                                        itemColor = Colors.orange;
                                        break;
                                      default:
                                        itemColor = Colors.red.shade400;
                                    }

                                    return GestureDetector(
                                      onTap: () => _ubahStatus(item),
                                      child: Container(
                                        margin:
                                            const EdgeInsets.only(bottom: 10),
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          border: Border.all(
                                            color: itemColor.withOpacity(0.2),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 4,
                                              height: 44,
                                              decoration: BoxDecoration(
                                                color: itemColor,
                                                borderRadius:
                                                    BorderRadius.circular(2),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    tanggal,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: AppColors.darkest,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    status,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: itemColor,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  if (status
                                                              .toLowerCase() ==
                                                          "izin" &&
                                                      (item["catatan"] ?? "")
                                                          .toString()
                                                          .isNotEmpty) ...[
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      item["catatan"],
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        color:
                                                            Colors.black54,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow
                                                          .ellipsis,
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                            Text(
                                              jam,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: AppColors.darkest,
                                              ),
                                            ),
                                          ],
                                        ),
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

  Widget _miniStat(String label, int value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          Text(
            "$value",
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _miniDivider() {
    return Container(
      width: 1,
      height: 30,
      color: Colors.white24,
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}
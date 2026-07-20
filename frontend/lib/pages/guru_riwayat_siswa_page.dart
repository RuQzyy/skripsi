import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/guru_service.dart';

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
  Map<String, dynamic>? data;
  bool isLoading = true;
  String filterStatus = "Semua";

  List<dynamic> get filteredRiwayat {
    final list = data?["riwayat"] ?? [];
    if (filterStatus == "Semua") return list;
    return list
        .where((r) =>
            (r["status"] ?? "").toString().trim().toLowerCase() ==
            filterStatus.trim().toLowerCase())
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final result = await GuruService.getRiwayatSiswa(widget.siswaId);
      setState(() {
        data = result["success"] == true ? result["data"] : null;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _ubahStatus(Map<String, dynamic> item) async {
    final currentStatus = (item["status"] ?? "").toString();
    final absensiId = item["id"];

    if (absensiId == null) return;

    final statusOptions = ["Hadir", "Terlambat", "Izin", "Sakit", "Alpha"];
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
                        activeColor: const Color(0xff1E5631),
                        onChanged: (v) =>
                            setDialogState(() => tempSelected = v),
                      );
                    }),
                    if (tempSelected == "Izin") ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: catatanController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: "Catatan Izin",
                          hintText: "Contoh: Acara keluarga",
                          border: OutlineInputBorder(),
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
                    backgroundColor: const Color(0xff1E5631),
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
      backgroundColor: const Color(0xffEDEDED),
      body: SafeArea(
        child: Column(
          children: [
            // HEADER
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
                      child: Row(
                        children: [
                          _miniStat("Hadir",
                              (statistik["hadir"] ?? 0) as int, Colors.white),
                          _miniDivider(),
                          _miniStat("Terlambat",
                              (statistik["terlambat"] ?? 0) as int,
                              const Color(0xffF4D03F)),
                          _miniDivider(),
                          _miniStat("Izin",
                              (statistik["izin"] ?? 0) as int,
                              Colors.blue.shade200),
                          _miniDivider(),
                          _miniStat("Sakit",
                              (statistik["sakit"] ?? 0) as int,
                              Colors.purple.shade200),
                          _miniDivider(),
                          _miniStat("Alpha",
                              (statistik["alpha"] ?? 0) as int,
                              Colors.red.shade200),
                          _miniDivider(),
                          _miniStat("Total",
                              (statistik["total"] ?? 0) as int, Colors.white70),
                        ],
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
                  children: ["Semua", "Hadir", "Terlambat", "Izin", "Sakit", "Alpha"].map((s) {
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
                              ? const Color(0xff1E5631)
                              : Colors.white,
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

            // LIST
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xff1E5631)),
                    )
                  : filteredRiwayat.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.history,
                                  size: 48, color: Colors.grey.shade300),
                              const SizedBox(height: 8),
                              const Text(
                                "Belum ada riwayat absensi",
                                style: TextStyle(color: Colors.black45),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: filteredRiwayat.length,
                          itemBuilder: (context, index) {
                            final item = filteredRiwayat[index];

                            String tanggal = "-";
                            try {
                              tanggal = DateFormat("EEEE, dd MMM yyyy", "id_ID")
                                  .format(DateTime.parse(item["tanggal"].toString()));
                            } catch (_) {}

                            final jam =
                                (item["jam_masuk"] ?? "").toString().length >= 5
                                    ? item["jam_masuk"].toString().substring(0, 5)
                                    : "-";
                            final status = item["status"] ?? "-";

                            Color itemColor;
                            if (status.toLowerCase() == "hadir") {
                              itemColor = const Color(0xff1E5631);
                            } else if (status.toLowerCase() == "alpha") {
                              itemColor = Colors.red.shade900;
                            } else if (status.toLowerCase() == "izin") {
                              itemColor = Colors.blue.shade700;
                            } else if (status.toLowerCase() == "sakit") {
                              itemColor = Colors.purple.shade700;
                            } else {
                              itemColor = Colors.orange;
                            }

                            return GestureDetector(
                              onTap: () => _ubahStatus(item),
                              child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
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
                                      borderRadius: BorderRadius.circular(2),
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
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          status,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: itemColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        if (status.toLowerCase() == "izin" &&
                                            (item["catatan"] ?? "")
                                                .toString()
                                                .isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            item["catatan"],
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.black54,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
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
                                    ),
                                  ),
                                ],
                              ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(String label, int value, Color color) {
    return Expanded(
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
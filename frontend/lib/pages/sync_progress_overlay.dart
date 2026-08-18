import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../services/sync_service.dart';

/// ==========================================================
/// SyncProgressOverlay
/// ==========================================================
/// Overlay animasi yang otomatis muncul di atas layar manapun setiap
/// kali SyncService sedang mengirim antrian absensi offline ke server
/// (misal begitu HP kembali online setelah offline).
///
/// Menampilkan:
/// - Animasi Lottie (loading/sync) di bagian atas
/// - Label item yang sedang diproses ("Item 2 dari 5"), kalau lebih
///   dari satu item dalam antrian
/// - Checklist langkah-langkah proses secara real-time: "Mengunggah ke
///   server" -> "Verifikasi lokasi & wajah" -> "Menyimpan hasil",
///   masing-masing dengan status (menunggu / berjalan / berhasil /
///   peringatan / gagal) dan alasan singkat kalau ada masalah --
///   supaya user tahu persis di tahap mana prosesnya, bukan cuma teks
///   statis "Hadir (Menunggu Sinkronisasi)" tanpa penjelasan.
///
/// ==========================================================
/// CARA PAKAI
/// ==========================================================
/// Taruh `const SyncProgressOverlay()` sebagai child PALING ATAS di
/// dalam sebuah Stack pada halaman yang mau menampilkannya (biasanya
/// cukup di halaman utama / dashboard). Contoh minimal di
/// dashboard_page.dart:
///
/// return Scaffold(
///   body: Stack(
///     children: [
///       SafeArea(
///         child: SingleChildScrollView(
///           child: Column( ... isi dashboard yang sudah ada ... ),
///         ),
///       ),
///       const SyncProgressOverlay(),
///     ],
///   ),
///   bottomNavigationBar: ...,
/// );
///
/// Widget ini otomatis pasang/lepas dirinya sendiri berdasarkan
/// SyncService.instance.isSyncRunning, jadi tidak perlu dipanggil
/// manual dari mana pun -- cukup ditaruh sekali di root halaman utama.
///
/// ==========================================================
/// SETUP ASET LOTTIE
/// ==========================================================
/// 1. Tambahkan dependency di pubspec.yaml:
///      dependencies:
///        lottie: ^3.1.0
/// 2. Download animasi bertema "cloud sync" / "cloud upload" / "loading"
///    (gratis) dari lottiefiles.com, simpan sebagai:
///      assets/lottie/sync_animation.json
/// 3. Daftarkan di pubspec.yaml:
///      flutter:
///        assets:
///          - assets/lottie/sync_animation.json
/// Kalau file belum ada, widget ini otomatis fallback ke spinner biasa
/// (lihat errorBuilder di bawah) supaya tidak crash/blank.
class SyncProgressOverlay extends StatefulWidget {
  const SyncProgressOverlay({super.key});

  @override
  State<SyncProgressOverlay> createState() => _SyncProgressOverlayState();
}

class _SyncProgressOverlayState extends State<SyncProgressOverlay> {
  bool _visible = false;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    SyncService.instance.isSyncRunning.addListener(_onSyncRunningChanged);

    // Kalau ternyata sync sedang berjalan saat widget ini pertama kali
    // dibuat (misal halaman dibuka di tengah proses sync), langsung
    // tampilkan tanpa menunggu perubahan berikutnya.
    if (SyncService.instance.isSyncRunning.value) {
      _visible = true;
    }
  }

  @override
  void dispose() {
    SyncService.instance.isSyncRunning.removeListener(_onSyncRunningChanged);
    _hideTimer?.cancel();
    super.dispose();
  }

  void _onSyncRunningChanged() {
    final running = SyncService.instance.isSyncRunning.value;

    _hideTimer?.cancel();

    if (running) {
      setState(() => _visible = true);
    } else {
      // Beri jeda sebentar sebelum overlay hilang, supaya user sempat
      // membaca status akhir (berhasil / menunggu review / gagal) dari
      // langkah terakhir -- tidak langsung menghilang begitu selesai.
      _hideTimer = Timer(const Duration(milliseconds: 1600), () {
        if (mounted) setState(() => _visible = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !_visible,
      child: AnimatedOpacity(
        opacity: _visible ? 1 : 0,
        duration: const Duration(milliseconds: 250),
        child: Container(
          color: Colors.black.withOpacity(0.55),
          width: double.infinity,
          height: double.infinity,
          child: Center(
            child: _visible ? const _SyncProgressCard() : const SizedBox(),
          ),
        ),
      ),
    );
  }
}

class _SyncProgressCard extends StatelessWidget {
  const _SyncProgressCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ================= ANIMASI LOTTIE =================
          SizedBox(
            height: 140,
            child: Lottie.asset(
              'assets/lottie/sync_animation.json',
              repeat: true,
              // Kalau file lottie belum ditambahkan ke assets, tampilkan
              // fallback spinner biasa supaya UI tidak error/blank.
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 4),

          const Text(
            "Menyinkronkan Absensi",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),

          const SizedBox(height: 4),

          ValueListenableBuilder<String?>(
            valueListenable: SyncService.instance.currentItemLabel,
            builder: (_, label, __) {
              if (label == null) return const SizedBox(height: 4);
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 12),

          // ================= CHECKLIST LANGKAH =================
          ValueListenableBuilder<List<SyncStep>>(
            valueListenable: SyncService.instance.currentSteps,
            builder: (_, steps, __) {
              if (steps.isEmpty) return const SizedBox();
              return Column(
                children: [
                  for (int i = 0; i < steps.length; i++) ...[
                    _StepRow(step: steps[i]),
                    if (i != steps.length - 1) const SizedBox(height: 10),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final SyncStep step;

  const _StepRow({required this.step});

  @override
  Widget build(BuildContext context) {
    late final Widget icon;
    late final Color textColor;

    switch (step.status) {
      case SyncStepStatus.waiting:
        icon = Icon(Icons.circle_outlined, size: 18, color: Colors.grey.shade400);
        textColor = Colors.black38;
        break;
      case SyncStepStatus.inProgress:
        icon = const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
        textColor = Colors.black87;
        break;
      case SyncStepStatus.success:
        icon = const Icon(Icons.check_circle, size: 18, color: Colors.green);
        textColor = Colors.black87;
        break;
      case SyncStepStatus.warning:
        icon = const Icon(Icons.error_outline, size: 18, color: Colors.orange);
        textColor = Colors.black87;
        break;
      case SyncStepStatus.error:
        icon = const Icon(Icons.cancel, size: 18, color: Colors.red);
        textColor = Colors.black87;
        break;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 18, height: 18, child: icon),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                step.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: step.status == SyncStepStatus.inProgress
                      ? FontWeight.w600
                      : FontWeight.w500,
                  color: textColor,
                ),
              ),
              if (step.detail != null && step.detail!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    step.detail!,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: step.status == SyncStepStatus.error
                          ? Colors.red.shade400
                          : step.status == SyncStepStatus.warning
                              ? Colors.orange.shade700
                              : Colors.black45,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
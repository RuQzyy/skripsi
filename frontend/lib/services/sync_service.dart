import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:ntp/ntp.dart'; // ✅ tambahan
import 'package:shared_preferences/shared_preferences.dart';

import 'local_db_service.dart';
import 'attendance_service.dart';

/// ==========================================================
/// STATUS TIAP LANGKAH PROSES SINKRONISASI (tambahan, untuk UI)
/// ==========================================================
enum SyncStepStatus {
  waiting, // belum dimulai
  inProgress, // sedang berjalan
  success, // selesai & berhasil
  warning, // selesai tapi ada catatan
  error, // gagal
}

/// Satu baris langkah yang ditampilkan di UI progres sinkronisasi
/// (misal "Mengunggah ke server" -> berhasil / gagal + alasan).
@immutable
class SyncStep {
  final String label;
  final SyncStepStatus status;
  final String? detail;

  const SyncStep({
    required this.label,
    required this.status,
    this.detail,
  });

  SyncStep copyWith({SyncStepStatus? status, String? detail}) {
    return SyncStep(
      label: label,
      status: status ?? this.status,
      detail: detail ?? this.detail,
    );
  }
}

/// ==========================================================
/// SyncService
/// ==========================================================
/// Bertugas mengirim antrian absensi offline (tabel attendance_queue)
/// ke server begitu HP terhubung internet lagi.
///
/// Dipicu oleh 3 hal:
/// 1. Perubahan konektivitas (offline -> online) via connectivity_plus
/// 2. App kembali ke foreground (dipanggil manual dari main.dart)
/// 3. Timer periodik sebagai jaring pengaman kalau event konektivitas
///    tidak terdeteksi dengan baik oleh OS
///
/// Item dikirim SATU PER SATU secara berurutan (bukan paralel) supaya:
/// - urutan waktu absensi tetap terjaga
/// - kalau di tengah jalan koneksi putus lagi, sisa antrian otomatis
///   berhenti diproses dan menunggu percobaan berikutnya
///
/// PENTING: semua operasi di sini selalu di-scope ke user_id yang
/// sedang login (lihat _getUserId()), supaya antrian absensi tidak
/// pernah tercampur atau "bocor" ke akun lain kalau device dipakai
/// bergantian.
///
/// ==========================================================
/// CATATAN (fix): semantik hasil sync dari server
/// ==========================================================
/// AttendanceController::sync() di server sekarang menjalankan
/// validasi yang SAMA PERSIS seperti absen online (jendela waktu,
/// akurasi GPS, radius lokasi, WiFi sekolah, verifikasi wajah termasuk
/// anti-spoof). TIDAK ADA LAGI status "pending_review menunggu admin".
///
/// - Kalau semua validasi lolos -> success:true, sync_status:'synced'
///   -> item dihapus dari antrian lokal, dianggap identik dengan
///   absen online yang berhasil.
/// - Kalau ada data yang tidak memenuhi ketentuan (jam/GPS/radius/
///   WiFi/wajah) -> success:false DAN rejected:true -> KEPUTUSAN
///   FINAL, item ditandai `rejected` di lokal dan TIDAK di-retry
///   otomatis. Ditampilkan ke user lewat banner "Absensi Ditolak" di
///   dashboard (lihat getTodayRejectedItem di LocalDbService).
/// - Kalau gagal karena hal TEKNIS (setting belum dibuat, BSSID
///   sekolah belum diatur, exception server) -> success:false TANPA
///   flag rejected -> ditandai `failed`, boleh dicoba lagi otomatis
///   oleh siklus sync berikutnya.
///
/// ==========================================================
/// TAMBAHAN (fitur UI progres sinkronisasi)
/// ==========================================================
/// Tiga ValueNotifier baru di bawah ([isSyncRunning], [currentItemLabel],
/// [currentSteps]) khusus dipakai untuk menggerakkan UI overlay
/// (lihat SyncProgressOverlay) yang menampilkan animasi + checklist
/// tahapan proses secara real-time, supaya user tahu persis di mana
/// prosesnya berada -- termasuk kalau ditolak, alasannya langsung
/// terlihat di situ, bukan cuma teks statis "Menunggu Sinkronisasi".
class SyncService {
  SyncService._internal();
  static final SyncService instance = SyncService._internal();

  final AttendanceService _attendanceService = AttendanceService();

  // ✅ tambahan: toleransi drift waktu perangkat vs server, sama
  // dengan yang dipakai dashboard_page.dart.
  static const Duration _maxAllowedTimeDrift = Duration(minutes: 3);

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  Timer? _periodicTimer;

  bool _isSyncing = false;

  /// Dipakai UI (misal badge di dashboard) untuk tahu berapa item yang
  /// masih menunggu terkirim. Update otomatis setiap kali sync dijalankan.
  final ValueNotifier<int> pendingCount = ValueNotifier<int>(0);

  /// Status koneksi internet HP saat ini, diperbarui otomatis lewat
  /// listener connectivity_plus. Dipakai UI untuk menampilkan
  /// banner "Online" / "Offline".
  final ValueNotifier<bool> isOnline = ValueNotifier<bool>(true);

  /// Kapan terakhir kali proses sinkronisasi selesai dijalankan
  /// (berhasil, gagal sebagian, ditolak, atau tidak ada antrian sama
  /// sekali). Dipakai UI untuk menampilkan "Sinkronisasi terakhir: 2
  /// menit lalu".
  final ValueNotifier<DateTime?> lastSyncedAt = ValueNotifier<DateTime?>(null);

  // ==========================================================
  // TAMBAHAN: notifier untuk UI progres sinkronisasi (Lottie + checklist)
  // ==========================================================

  /// true selama ada item yang benar-benar sedang diproses (antrian
  /// tidak kosong). Dipakai overlay untuk tahu kapan harus tampil.
  /// Sengaja TIDAK diaktifkan untuk pengecekan rutin yang antriannya
  /// kosong, supaya overlay tidak muncul setiap 30 detik tanpa alasan.
  final ValueNotifier<bool> isSyncRunning = ValueNotifier<bool>(false);

  /// Label item yang sedang diproses, misal "Item 2 dari 5".
  final ValueNotifier<String?> currentItemLabel =
      ValueNotifier<String?>(null);

  /// Checklist langkah untuk item yang SEDANG diproses saat ini.
  /// Diperbarui live oleh _processItem() di setiap tahap.
  final ValueNotifier<List<SyncStep>> currentSteps =
      ValueNotifier<List<SyncStep>>(const []);

  /// Ambil id user yang sedang login dari SharedPreferences.
  ///
  /// Return null kalau belum ada user login (misal dipanggil sebelum
  /// login pertama kali, atau sesudah logout) -> pemanggil harus
  /// menangani null ini dengan tidak melakukan apa-apa, BUKAN dengan
  /// fallback ke "semua user" atau default id tertentu.
  Future<int?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt("user_id");
  }

  /// ✅ tambahan: verifikasi waktu perangkat vs server (NTP) dan simpan
  /// offset kalau berhasil & masih dalam toleransi. Dipanggil sebelum
  /// syncNow() memproses antrian, supaya time_offset_age_seconds yang
  /// dikirim ke server nanti selalu berdasar verifikasi paling baru
  /// yang tersedia saat koneksi hidup -- termasuk kalau dashboard
  /// sedang tidak dibuka / app di background.
  Future<void> _refreshTimeOffsetIfPossible() async {
    try {
      final DateTime networkTime =
          await NTP.now(lookUpAddress: "pool.ntp.org")
              .timeout(const Duration(seconds: 6));
      final DateTime deviceTime = DateTime.now();
      final Duration drift = deviceTime.difference(networkTime).abs();

      if (drift > _maxAllowedTimeDrift) {
        debugPrint(
            "[SyncService] Drift waktu perangkat terlalu besar: ${drift.inSeconds}s");
        return;
      }

      final offsetMs = networkTime.difference(deviceTime).inMilliseconds;
      await LocalDbService.instance.saveTimeOffset(offsetMs);
    } catch (e) {
      debugPrint("[SyncService] Gagal refresh time offset: $e");
    }
  }

  /// Dipanggil sekali saat app start (misal di main.dart / setelah login).
  Future<void> init() async {
    await refreshPendingCount();

    // Dengar perubahan status konektivitas.
    _connectivitySub?.cancel();
    _connectivitySub = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) async {
      final online = results.any((r) => r != ConnectivityResult.none);

      isOnline.value = online;

      if (online) {
        debugPrint(
            "[SyncService] Internet kembali, menunggu jaringan stabil...");

        // beri waktu agar internet benar-benar aktif
        await Future.delayed(const Duration(seconds: 2));

        syncNow();
      }
    });

    // Jaring pengaman: coba sync tiap 30 detik selama app aktif,
    // untuk kondisi di mana event konektivitas tidak terpicu (jarang
    // terjadi tapi ada di beberapa perangkat Android).
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) {
        syncNow();
      },
    );

    // Coba langsung sekali saat init, siapa tahu ada antrian tersisa
    // dari sesi sebelumnya dan HP sudah online.
    syncNow();
  }

  Future<void> dispose() async {
    await _connectivitySub?.cancel();
    _periodicTimer?.cancel();
  }

  /// Dipanggil setelah login berhasil ATAU setelah logout, supaya
  /// badge pendingCount langsung mencerminkan antrian milik user yang
  /// sedang aktif (bukan sisa dari user sebelumnya).
  Future<void> refreshPendingCount() async {
    final userId = await _getUserId();

    if (userId == null) {
      pendingCount.value = 0;
      return;
    }

    final count = await LocalDbService.instance.countPending(userId);
    pendingCount.value = count;
  }

  /// Trigger sinkronisasi manual. Aman dipanggil berkali-kali —
  /// kalau sedang berjalan, panggilan berikutnya diabaikan (bukan
  /// ditumpuk), supaya tidak ada dua proses sync jalan bersamaan.
  Future syncNow() async {
    if (_isSyncing) {
      debugPrint("[SyncService] Sync sudah berjalan, lewati panggilan ini.");
      return;
    }

    final userId = await _getUserId();

    if (userId == null) {
      debugPrint(
          "[SyncService] Tidak ada user yang login, lewati sinkronisasi.");
      return;
    }

    final connectivity = await Connectivity().checkConnectivity();

    if (connectivity.contains(ConnectivityResult.none)) {
      debugPrint("[SyncService] Tidak ada koneksi internet.");
      return;
    }

    _isSyncing = true;

    try {
      final items = await LocalDbService.instance.getSyncableItems(userId);

      if (items.isEmpty) {
        debugPrint("[SyncService] Tidak ada antrian yang perlu dikirim.");
        return;
      }

      // ✅ tambahan: pastikan offset waktu sesegar mungkin sebelum
      // antrian dikirim, supaya time_offset_age_seconds akurat saat
      // sampai ke server.
      await _refreshTimeOffsetIfPossible();

      debugPrint("[SyncService] Memproses ${items.length} antrian absensi "
          "milik user $userId...");

      // Baru sekarang nyalakan overlay, karena kita sudah pasti ada
      // item yang mau diproses (bukan sekadar pengecekan rutin kosong).
      isSyncRunning.value = true;

      for (int i = 0; i < items.length; i++) {
        final item = items[i];

        currentItemLabel.value = items.length > 1
            ? "Item ${i + 1} dari ${items.length}"
            : null;

        final shouldStop = await _processItem(item);

        // Kalau _processItem bilang "berhenti" (indikasi jaringan putus
        // lagi di tengah proses), hentikan loop -> sisa antrian menunggu
        // percobaan berikutnya, tidak dihajar terus-menerus tanpa jeda.
        if (shouldStop) {
          debugPrint(
              "[SyncService] Berhenti memproses antrian, sepertinya koneksi terputus lagi.");
          break;
        }
      }
    } finally {
      _isSyncing = false;
      isSyncRunning.value = false;
      currentItemLabel.value = null;
      await refreshPendingCount();
      lastSyncedAt.value = DateTime.now();
    }
  }

  /// Template checklist awal untuk satu item yang mau diproses.
  /// Step pertama langsung "success" karena data (foto+lokasi) memang
  /// sudah tersedia lokal sejak disimpan saat offline -- yang belum
  /// terjadi adalah pengiriman & validasinya oleh server.
  List<SyncStep> _initialSteps() => const [
        SyncStep(
          label: "Menyiapkan data absensi tersimpan",
          status: SyncStepStatus.success,
        ),
        SyncStep(
          label: "Mengunggah ke server",
          status: SyncStepStatus.waiting,
        ),
        SyncStep(
          label: "Verifikasi lokasi, wajah & waktu",
          status: SyncStepStatus.waiting,
        ),
        SyncStep(
          label: "Menyimpan hasil",
          status: SyncStepStatus.waiting,
        ),
      ];

  /// Update satu baris step berdasarkan index, lalu publish list baru
  /// (harus instance baru supaya ValueNotifier memicu listener).
  void _updateStep(int index, {SyncStepStatus? status, String? detail}) {
    final steps = List<SyncStep>.from(currentSteps.value);
    if (index < 0 || index >= steps.length) return;
    steps[index] = steps[index].copyWith(status: status, detail: detail);
    currentSteps.value = steps;
  }

  /// Proses satu item antrian.
  /// Return `true` kalau proses harus DIHENTIKAN untuk item-item
  /// berikutnya (misal karena kehilangan koneksi lagi).
  Future<bool> _processItem(AttendanceQueueItem item) async {
    currentSteps.value = _initialSteps();

    await LocalDbService.instance.updateQueueItemStatus(
      item.clientUuid,
      status: AttendanceQueueStatus.syncing,
    );

    // Step "Mengunggah ke server" mulai berjalan.
    _updateStep(1, status: SyncStepStatus.inProgress);

    try {
      final result = await _attendanceService.syncAttendance(item);

      final bool success = result["success"] == true;

      if (!success) {
        final bool rejected = result["rejected"] == true;
        final message = result["message"]?.toString() ??
            (rejected ? "Absensi ditolak" : "Sinkronisasi gagal");

        if (rejected) {
          // ==========================================================
          // DITOLAK FINAL oleh server.
          // ==========================================================
          // Server sudah menjalankan validasi PERSIS seperti jalur
          // online (jam absen, akurasi GPS, radius lokasi, WiFi
          // sekolah, verifikasi wajah termasuk anti-spoof) dan
          // menyatakan data ini tidak memenuhi ketentuan. Ini
          // keputusan final -> TIDAK boleh di-retry otomatis.
          //
          // Upload ke server sendiri berhasil sampai (makanya kita
          // dapat balasan berisi alasan penolakan), jadi step 1 tetap
          // ditandai success; yang gagal adalah tahap validasinya.
          _updateStep(1, status: SyncStepStatus.success);
          _updateStep(2, status: SyncStepStatus.error, detail: message);
          _updateStep(3, status: SyncStepStatus.error, detail: "Ditolak");

          await LocalDbService.instance.updateQueueItemStatus(
            item.clientUuid,
            status: AttendanceQueueStatus.rejected,
            serverMessage: message,
          );

          // Foto lokal sudah tidak diperlukan lagi -- keputusan sudah
          // final, tidak akan dikirim ulang.
          await _deleteLocalPhoto(item.photoPath);

          debugPrint(
              "[SyncService] Item ${item.clientUuid} DITOLAK server: $message");

          return false;
        }

        // ==========================================================
        // Kegagalan TEKNIS (bukan penolakan data), mis. pengaturan
        // absensi belum dibuat, BSSID sekolah belum diatur admin,
        // atau exception tak terduga di server. Boleh di-retry.
        // ==========================================================
        _updateStep(1, status: SyncStepStatus.error, detail: message);

        await LocalDbService.instance.updateQueueItemStatus(
          item.clientUuid,
          status: AttendanceQueueStatus.failed,
          retryCount: item.retryCount + 1,
          lastError: message,
        );

        debugPrint(
            "[SyncService] Item ${item.clientUuid} gagal disinkronkan: $message");

        return false;
      }

      // ==========================================================
      // Lolos semua validasi (identik jalur online) -> langsung
      // tersimpan di server. Tidak ada lagi cabang pending_review.
      // ==========================================================
      _updateStep(1, status: SyncStepStatus.success);
      _updateStep(2, status: SyncStepStatus.success);
      _updateStep(3, status: SyncStepStatus.success, detail: "Tersinkronkan");

      // Data sudah tersimpan di server (akan muncul lewat
      // getTodayAttendance / getRiwayatAttendance), jadi item lokal
      // dan foto lokalnya tidak diperlukan lagi.
      await LocalDbService.instance.deleteQueueItem(item.clientUuid);
      await _deleteLocalPhoto(item.photoPath);

      debugPrint(
          "[SyncService] Item ${item.clientUuid} berhasil disinkronkan.");

      return false;
    } on SocketException catch (e) {
      _updateStep(
        1,
        status: SyncStepStatus.error,
        detail: "Tidak ada koneksi internet",
      );

      await LocalDbService.instance.updateQueueItemStatus(
        item.clientUuid,
        status: AttendanceQueueStatus.pending,
        retryCount: item.retryCount + 1,
        lastError: "Tidak ada koneksi internet",
      );

      debugPrint("[SyncService] SocketException pada ${item.clientUuid}: $e");

      // tunggu sebentar, mungkin internet baru saja aktif
      await Future.delayed(const Duration(seconds: 3));

      return true;
    } on TimeoutException catch (e) {
      _updateStep(
        1,
        status: SyncStepStatus.error,
        detail: "Waktu koneksi habis (timeout)",
      );

      await LocalDbService.instance.updateQueueItemStatus(
        item.clientUuid,
        status: AttendanceQueueStatus.pending,
        retryCount: item.retryCount + 1,
        lastError: "Waktu koneksi habis (timeout)",
      );
      debugPrint("[SyncService] Timeout pada ${item.clientUuid}: $e");
      return true;
    } catch (e) {
      _updateStep(1, status: SyncStepStatus.error, detail: e.toString());

      // Error tak terduga (misal file foto sudah terhapus manual dari
      // storage) -> tandai failed untuk item ini saja, lanjut ke yang lain.
      await LocalDbService.instance.updateQueueItemStatus(
        item.clientUuid,
        status: AttendanceQueueStatus.failed,
        retryCount: item.retryCount + 1,
        lastError: e.toString(),
      );
      debugPrint("[SyncService] Error tak terduga pada ${item.clientUuid}: $e");
      return false;
    }
  }

  Future<void> _deleteLocalPhoto(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // Gagal hapus foto bukan hal fatal, cukup dicatat saja.
      debugPrint("[SyncService] Gagal menghapus foto lokal $path: $e");
    }
  }
}
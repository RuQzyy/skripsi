import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

/// ==========================================================
/// STATUS ANTRIAN ABSENSI
/// ==========================================================
/// pending          -> baru disimpan di HP, belum pernah dicoba dikirim
/// syncing          -> sedang dalam proses upload (mencegah double-send)
/// synced           -> berhasil terkirim & diterima server
/// failed           -> sempat dicoba kirim tapi gagal (jaringan/error server),
///                     boleh dicoba ulang
/// pending_review   -> berhasil terkirim, tapi verifikasi wajah di server
///                     tidak cocok / gagal -> perlu ditinjau admin
/// rejected         -> ditolak FINAL oleh server (misal fake GPS, di luar
///                     radius, wajah tidak cocok berkali-kali, dll).
///                     TIDAK boleh di-retry otomatis, dan TIDAK boleh
///                     dianggap sebagai "sudah absen hari ini" oleh UI.
class AttendanceQueueStatus {
  static const String pending = "pending";
  static const String syncing = "syncing";
  static const String synced = "synced";
  static const String failed = "failed";
  static const String pendingReview = "pending_review";
  static const String rejected = "rejected";
}

/// Model satu baris antrian absensi offline.
///
/// PENTING: setiap item WAJIB terikat ke satu [userId]. Ini mencegah
/// data absensi "nyasar" ke akun lain kalau HP dipakai bergantian oleh
/// beberapa user (misal HP testing/shared).
class AttendanceQueueItem {
  final int? id;
  final int userId;
  final String clientUuid;
  final String mode; // "masuk" atau "pulang"
  final String photoPath;
  final double latitude;
  final double longitude;
  final double accuracy;
  final String? wifiBssid;
  final bool isMocked;
  final DateTime capturedAt;
  final String status;
  final int retryCount;
  final String? lastError;
  final String? serverMessage;
  final DateTime createdAt;

  AttendanceQueueItem({
    this.id,
    required this.userId,
    required this.clientUuid,
    required this.mode,
    required this.photoPath,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    this.wifiBssid,
    this.isMocked = false,
    required this.capturedAt,
    this.status = AttendanceQueueStatus.pending,
    this.retryCount = 0,
    this.lastError,
    this.serverMessage,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'client_uuid': clientUuid,
      'mode': mode,
      'photo_path': photoPath,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'wifi_bssid': wifiBssid,
      'is_mocked': isMocked ? 1 : 0,
      'captured_at': capturedAt.toIso8601String(),
      'status': status,
      'retry_count': retryCount,
      'last_error': lastError,
      'server_message': serverMessage,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory AttendanceQueueItem.fromMap(Map<String, dynamic> map) {
    return AttendanceQueueItem(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      clientUuid: map['client_uuid'] as String,
      mode: map['mode'] as String,
      photoPath: map['photo_path'] as String,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      accuracy: (map['accuracy'] as num).toDouble(),
      wifiBssid: map['wifi_bssid'] as String?,
      isMocked: (map['is_mocked'] as int) == 1,
      capturedAt: DateTime.parse(map['captured_at'] as String),
      status: map['status'] as String,
      retryCount: map['retry_count'] as int? ?? 0,
      lastError: map['last_error'] as String?,
      serverMessage: map['server_message'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  AttendanceQueueItem copyWith({
    String? status,
    int? retryCount,
    String? lastError,
    String? serverMessage,
  }) {
    return AttendanceQueueItem(
      id: id,
      userId: userId,
      clientUuid: clientUuid,
      mode: mode,
      photoPath: photoPath,
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      wifiBssid: wifiBssid,
      isMocked: isMocked,
      capturedAt: capturedAt,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      lastError: lastError ?? this.lastError,
      serverMessage: serverMessage ?? this.serverMessage,
      createdAt: createdAt,
    );
  }
}

class LocalDbService {
  LocalDbService._internal();
  static final LocalDbService instance = LocalDbService._internal();

  static const String _dbName = "absensi_local.db";

  // Versi dinaikkan 1 -> 2 karena menambahkan kolom user_id pada
  // attendance_queue (lihat onUpgrade di bawah).
  static const int _dbVersion = 2;

  static const String tableQueue = "attendance_queue";
  static const String tableKv = "kv_store";

  // Key-key yang dipakai di tabel kv_store
  static const String keyCachedSetting = "cached_setting";
  static const String keyTimeOffsetMs = "time_offset_ms";
  static const String keyTimeOffsetUpdatedAt = "time_offset_updated_at";

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $tableQueue (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            client_uuid TEXT NOT NULL UNIQUE,
            mode TEXT NOT NULL,
            photo_path TEXT NOT NULL,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            accuracy REAL NOT NULL,
            wifi_bssid TEXT,
            is_mocked INTEGER NOT NULL DEFAULT 0,
            captured_at TEXT NOT NULL,
            status TEXT NOT NULL DEFAULT '${AttendanceQueueStatus.pending}',
            retry_count INTEGER NOT NULL DEFAULT 0,
            last_error TEXT,
            server_message TEXT,
            created_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE $tableKv (
            key TEXT PRIMARY KEY,
            value TEXT,
            updated_at TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Tambah kolom user_id ke tabel lama.
          // Data lama tidak punya info kepemilikan user yang jelas,
          // jadi paling aman dihapus semua daripada berisiko "bocor"
          // tampil ke akun yang salah setelah migrasi.
          await db.execute(
            "ALTER TABLE $tableQueue ADD COLUMN user_id INTEGER NOT NULL DEFAULT 0",
          );
          await db.delete(tableQueue, where: 'user_id = 0');
        }

        // Tempat menaruh ALTER TABLE dkk untuk versi berikutnya:
        // if (oldVersion < 3) {
        //   await db.execute("ALTER TABLE $tableQueue ADD COLUMN kolom_baru TEXT");
        // }
      },
    );
  }

  // ==========================================================
  // ANTRIAN ABSENSI (attendance_queue)
  // ==========================================================
  // Semua method di bawah WAJIB menerima/menyaring berdasarkan
  // [userId] supaya data antrian tidak tercampur antar akun kalau
  // device dipakai bergantian.

  /// Menyimpan satu record absensi offline baru ke antrian.
  /// Return id lokal (auto increment) hasil insert.
  Future<int> insertQueueItem(AttendanceQueueItem item) async {
    final db = await database;
    final map = item.toMap()..remove('id');
    return db.insert(
      tableQueue,
      map,
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  /// Ambil semua item milik [userId] yang masih perlu dikirim
  /// (pending atau failed). Diurutkan dari yang paling lama dibuat
  /// -> urutan antrian yang benar.
  ///
  /// CATATAN: item berstatus [AttendanceQueueStatus.rejected] SENGAJA
  /// tidak diikutkan di sini. Rejected berarti server sudah memberi
  /// keputusan final menolak (misal fake GPS / di luar radius / wajah
  /// tidak cocok), jadi tidak boleh dicoba kirim ulang otomatis. Kalau
  /// user ingin absen lagi, itu harus jadi absensi baru (record baru),
  /// bukan retry dari item yang sama.
  Future<List<AttendanceQueueItem>> getSyncableItems(int userId) async {
    final db = await database;
    final result = await db.query(
      tableQueue,
      where: 'user_id = ? AND status IN (?, ?)',
      whereArgs: [
        userId,
        AttendanceQueueStatus.pending,
        AttendanceQueueStatus.failed,
      ],
      orderBy: 'created_at ASC',
    );
    return result.map((e) => AttendanceQueueItem.fromMap(e)).toList();
  }

  /// Ambil semua item milik [userId] (untuk ditampilkan di UI
  /// riwayat/antrian, semua status).
  Future<List<AttendanceQueueItem>> getAllQueueItems(int userId) async {
    final db = await database;
    final result = await db.query(
      tableQueue,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    return result.map((e) => AttendanceQueueItem.fromMap(e)).toList();
  }

  /// Cari item berdasarkan client_uuid (dipakai untuk cek idempotensi
  /// lokal). client_uuid sudah unik secara global jadi tidak perlu
  /// filter user_id di sini.
  Future<AttendanceQueueItem?> getQueueItemByUuid(String clientUuid) async {
    final db = await database;
    final result = await db.query(
      tableQueue,
      where: 'client_uuid = ?',
      whereArgs: [clientUuid],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return AttendanceQueueItem.fromMap(result.first);
  }

  /// Cek apakah untuk tanggal & mode tertentu, milik [userId] ini,
  /// ADA item antrian yang MASIH DIANGGAP absensi yang berlaku hari ini
  /// (dipakai dashboard untuk menampilkan "Hadir (Menunggu Sinkronisasi)"
  /// dan mengunci tombol "Lakukan Absensi").
  ///
  /// PENTING (fix): status [AttendanceQueueStatus.failed] DAN
  /// [AttendanceQueueStatus.rejected] sama-sama dikecualikan.
  ///
  /// - failed  -> belum ada keputusan final, masih akan di-retry oleh
  ///              SyncService, jadi jangan dianggap "sudah absen" di UI
  ///              (kalau tetap dianggap, user bisa salah kira sudah
  ///              absen padahal belum tentu terkirim).
  /// - rejected -> sudah ada keputusan final DITOLAK oleh server. Kalau
  ///              status ini tidak dikecualikan, dashboard akan terus
  ///              menganggap user "sudah absen" selamanya (padahal
  ///              sebenarnya ditolak), tombol "Lakukan Absensi" tidak
  ///              akan pernah muncul lagi, dan user tidak bisa absen
  ///              ulang meski jam absensi masih berlaku. Ini bug yang
  ///              sebelumnya menyebabkan user "terkunci".
  Future<AttendanceQueueItem?> getTodayQueueItem(
    int userId,
    String mode,
  ) async {
    final db = await database;
    final today = await getCorrectedNow();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final result = await db.query(
      tableQueue,
      where: 'user_id = ? AND mode = ? AND captured_at >= ? AND captured_at < ? '
          'AND status NOT IN (?, ?)',
      whereArgs: [
        userId,
        mode,
        startOfDay.toIso8601String(),
        endOfDay.toIso8601String(),
        AttendanceQueueStatus.failed,
        AttendanceQueueStatus.rejected,
      ],
      orderBy: 'created_at DESC',
      limit: 1,
    );

    if (result.isEmpty) return null;
    return AttendanceQueueItem.fromMap(result.first);
  }

  /// Cari item yang HARI INI berstatus [AttendanceQueueStatus.rejected]
  /// untuk [userId] + [mode] tertentu.
  ///
  /// Dipakai khusus oleh UI (Dashboard) untuk menampilkan banner
  /// "Absensi Ditolak" beserta alasannya (dari [serverMessage] atau
  /// [lastError]), TERPISAH dari [getTodayQueueItem] yang dipakai untuk
  /// menentukan apakah user "sudah absen" hari ini.
  ///
  /// Return null kalau tidak ada item yang ditolak hari ini untuk
  /// mode tersebut (baik karena memang belum pernah absen, atau
  /// karena absensi terakhirnya berhasil/masih pending).
  Future<AttendanceQueueItem?> getTodayRejectedItem(
    int userId,
    String mode,
  ) async {
    final db = await database;
    final today = await getCorrectedNow();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final result = await db.query(
      tableQueue,
      where: 'user_id = ? AND mode = ? AND captured_at >= ? AND captured_at < ? '
          'AND status = ?',
      whereArgs: [
        userId,
        mode,
        startOfDay.toIso8601String(),
        endOfDay.toIso8601String(),
        AttendanceQueueStatus.rejected,
      ],
      orderBy: 'created_at DESC',
      limit: 1,
    );

    if (result.isEmpty) return null;
    return AttendanceQueueItem.fromMap(result.first);
  }

  /// Update status + info tambahan (dipanggil oleh SyncService setelah
  /// mencoba upload: sukses -> synced, gagal -> failed + pesan error,
  /// ditolak final -> rejected + pesan error).
  Future<void> updateQueueItemStatus(
    String clientUuid, {
    required String status,
    int? retryCount,
    String? lastError,
    String? serverMessage,
  }) async {
    final db = await database;
    final current = await getQueueItemByUuid(clientUuid);
    if (current == null) return;

    final updated = current.copyWith(
      status: status,
      retryCount: retryCount ?? current.retryCount,
      lastError: lastError,
      serverMessage: serverMessage,
    );

    await db.update(
      tableQueue,
      updated.toMap(),
      where: 'client_uuid = ?',
      whereArgs: [clientUuid],
    );
  }

  /// Naikkan retry_count +1 (dipanggil sebelum mencoba upload ulang).
  Future<void> incrementRetryCount(String clientUuid) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE $tableQueue SET retry_count = retry_count + 1 WHERE client_uuid = ?',
      [clientUuid],
    );
  }

  /// Hapus satu item dari antrian (biasanya setelah synced & foto sudah
  /// dihapus dari storage HP).
  Future<void> deleteQueueItem(String clientUuid) async {
    final db = await database;
    await db.delete(
      tableQueue,
      where: 'client_uuid = ?',
      whereArgs: [clientUuid],
    );
  }

  /// Hitung berapa item milik [userId] yang masih menunggu dikirim ->
  /// dipakai untuk badge di dashboard ("3 absensi menunggu koneksi").
  ///
  /// Sengaja hanya menghitung pending + failed (item yang MASIH akan
  /// dicoba dikirim). Item rejected tidak dihitung di sini karena sudah
  /// final dan tidak akan disinkronkan lagi -> ditampilkan lewat banner
  /// "Absensi Ditolak" (getTodayRejectedItem), bukan lewat badge sync.
  Future<int> countPending(int userId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as total FROM $tableQueue WHERE user_id = ? AND status IN (?, ?)',
      [userId, AttendanceQueueStatus.pending, AttendanceQueueStatus.failed],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Hapus semua antrian absensi milik [userId] tertentu saja.
  /// Berguna kalau suatu saat butuh reset data satu user tanpa
  /// mengganggu user lain di device yang sama.
  Future<void> clearQueueForUser(int userId) async {
    final db = await database;
    await db.delete(
      tableQueue,
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  // ==========================================================
  // KEY-VALUE STORE (kv_store)
  // ==========================================================

  Future<void> _setValue(String key, String value) async {
    final db = await database;
    await db.insert(
      tableKv,
      {
        'key': key,
        'value': value,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> _getValue(String key) async {
    final db = await database;
    final result = await db.query(
      tableKv,
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return result.first['value'] as String?;
  }

  /// Simpan hasil AttendanceSetting terakhir yang berhasil diambil dari
  /// server (dalam bentuk JSON mentah / Map hasil decode response API).
  ///
  /// Catatan: setting ini sifatnya global (bukan per user), jadi aman
  /// tetap disimpan tanpa user_id.
  Future<void> saveCachedSetting(Map<String, dynamic> settingJson) async {
    await _setValue(keyCachedSetting, jsonEncode(settingJson));
  }

  /// Ambil kembali cache setting terakhir. Null kalau belum pernah
  /// tersimpan sama sekali (misal instalasi baru & belum pernah online).
  Future<Map<String, dynamic>?> getCachedSetting() async {
    final raw = await _getValue(keyCachedSetting);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  /// Simpan offset waktu server vs HP (dalam milidetik).
  /// offset = serverTime.millisecondsSinceEpoch - deviceTime.millisecondsSinceEpoch
  /// Dipanggil setiap kali app berhasil mendapat waktu server yang valid
  /// (misalnya dari response getSetting(), kalau server menyertakan
  /// timestamp-nya sendiri).
  Future<void> saveTimeOffset(int offsetMs) async {
    await _setValue(keyTimeOffsetMs, offsetMs.toString());
    await _setValue(
      keyTimeOffsetUpdatedAt,
      DateTime.now().toIso8601String(),
    );
  }

  /// Ambil offset waktu tersimpan. Null kalau belum pernah disimpan.
  Future<int?> getTimeOffset() async {
    final raw = await _getValue(keyTimeOffsetMs);
    if (raw == null) return null;
    return int.tryParse(raw);
  }

  /// Kapan offset waktu terakhir diperbarui -> dipakai untuk menandai
  /// absensi offline sebagai "perlu review" kalau offset sudah terlalu lama
  /// tidak disegarkan (misal HP offline berhari-hari).
  Future<DateTime?> getTimeOffsetUpdatedAt() async {
    final raw = await _getValue(keyTimeOffsetUpdatedAt);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  /// Umur verifikasi waktu terakhir kali app berhasil sinkron NTP.
  /// Null kalau belum pernah diverifikasi sama sekali sejak install.
  /// Dipakai untuk mengirim `time_offset_age_seconds` ke server saat
  /// sync, supaya server tahu seberapa bisa dipercaya capturedAt item
  /// offline ini.
  Future<Duration?> getTimeOffsetAge() async {
    final updatedAt = await getTimeOffsetUpdatedAt();
    if (updatedAt == null) return null;
    return DateTime.now().difference(updatedAt);
  }

  /// Hitung "waktu sekarang yang sudah dikoreksi" berdasarkan offset
  /// tersimpan. Kalau belum ada offset sama sekali, kembalikan waktu HP
  /// apa adanya (fallback paling aman untuk kasus HP baru/belum pernah
  /// online).
  Future<DateTime> getCorrectedNow() async {
    final offset = await getTimeOffset();
    final deviceNow = DateTime.now();
    if (offset == null) return deviceNow;
    return deviceNow.add(Duration(milliseconds: offset));
  }

  // ==========================================================
  // UTIL
  // ==========================================================

  /// Hapus semua data lokal (dipakai misalnya saat logout, supaya antrian
  /// absensi tidak tercampur akun lain kalau HP dipakai bergantian).
  ///
  /// PENTING: panggil ini di proses logout (lihat AuthService.logout()).
  Future<void> clearAll() async {
    final db = await database;
    await db.delete(tableQueue);
    await db.delete(tableKv);
  }

  Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }
}
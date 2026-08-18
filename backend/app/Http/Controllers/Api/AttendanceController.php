<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Absensi;
use App\Models\AbsensiSetting;
use App\Models\User;
use App\Http\Controllers\Api\FaceController;
use Illuminate\Support\Facades\DB;

class AttendanceController extends Controller
{
    public function store(Request $request)
    {
        $request->validate([
            'photo' => 'required|image'
        ]);

        $user = $request->user();

        // ==========================
        // Face ID harus sudah ada
        // ==========================

        if (empty($user->face_id)) {
            return response()->json([
                'success' => false,
                'message' => 'Face ID belum terdaftar.'
            ], 400);
        }

        // ==========================
        // Sudah absen hari ini?
        // ==========================

        $today = now()->toDateString();

        $check = Absensi::where('user_id', $user->id)
            ->whereDate('tanggal', $today)
            ->first();

        if ($check) {
            return response()->json([
                'success' => false,
                'message' => 'Anda sudah melakukan absensi hari ini.'
            ], 400);
        }

        // ==========================
        // Cek jam absensi
        // ==========================

        $setting = AbsensiSetting::first();

        if (!$setting) {
            return response()->json([
                'success' => false,
                'message' => 'Pengaturan absensi belum dibuat.'
            ], 500);
        }

      $now = now()->format('H:i:s');

        if ($now < $setting->jam_absen_mulai) {
            return response()->json([
                'success' => false,
                'message' => 'Absensi belum dibuka.'
            ], 400);
        }

        if ($now > $setting->jam_absen_selesai) {
            return response()->json([
                'success' => false,
                'message' => 'Jam absensi sudah berakhir.'
            ], 400);
        }

        // ==========================
        // Validasi lokasi (radius)
        // ==========================

        $request->validate([
            'latitude'  => 'required|numeric',
            'longitude' => 'required|numeric',
            'accuracy'  => 'required|numeric',
        ]);

        // Tolak jika akurasi GPS terlalu buruk
        if ($request->accuracy > 75) {
            return response()->json([
                'success' => false,
                'message' => 'Sinyal GPS kurang akurat (± ' . round($request->accuracy) . ' meter). Coba pindah ke area terbuka dan ulangi.'
            ], 400);
        }

        $distance = self::calculateDistance(
            $request->latitude,
            $request->longitude,
            $setting->latitude,
            $setting->longitude
        );

        if ($distance > $setting->radius) {
            return response()->json([
                'success' => false,
                'message' => 'Anda berada di luar area absensi. Jarak: ' . round($distance) . ' meter.'
            ], 400);
        }

        // ==========================
        // Validasi WiFi sekolah
        // ==========================

        if ($setting->wifi_required) {
            $request->validate([
                'wifi_bssid' => 'required|string',
            ]);

            $userBssid = strtolower(trim($request->wifi_bssid));
            $schoolBssid = strtolower(trim($setting->wifi_bssid ?? ''));

            if (empty($schoolBssid)) {
                return response()->json([
                    'success' => false,
                    'message' => 'BSSID WiFi sekolah belum diatur oleh admin.'
                ], 500);
            }

            if ($userBssid !== $schoolBssid) {
                return response()->json([
                    'success' => false,
                    'message' => 'Anda harus terhubung ke jaringan WiFi sekolah untuk melakukan absensi.'
                ], 400);
            }
        }

        $faceResult = $this->verifyFace($user, $request);

        if ($faceResult instanceof \Illuminate\Http\JsonResponse) {
            return $faceResult;
        }

        // ==========================
        // Simpan absensi
        // ==========================

      $status = "hadir";

        if ($now > $setting->jam_terlambat) {
            $status = "terlambat";
        }

        $absensi = Absensi::create([
            'user_id'      => $user->id,

            // Kunci kelas siswa SAAT absen ini dibuat. Kolom ini sengaja
            // TIDAK ikut membaca $user->kelas_id secara live di tempat
            // lain (misal saat ditampilkan), karena kalau siswa pindah
            // kelas setelah ini, baris absensi lama harus tetap tercatat
            // di kelas lamanya. Absensi baru yang dibuat setelah pindah
            // otomatis akan memakai kelas_id yang baru di sini.
            'kelas_id'     => $user->kelas_id,

            'tanggal'      => $today,
            'jam_masuk'    => now()->format('H:i:s'),
            'status'       => $status,

            'latitude'     => $request->latitude,
            'longitude'    => $request->longitude,

            'accuracy'     => $request->accuracy,
            'wifi_bssid'   => $request->wifi_bssid,
            'is_mocked'    => $request->boolean('is_mocked'),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Absensi berhasil.',
            'similarity' => $faceResult['similarity'],
            'status' => $status,
            'data' => $absensi
        ]);
    }

    public function pulang(Request $request)
    {
        $request->validate([
            'photo' => 'required|image',
            'latitude' => 'required|numeric',
            'longitude' => 'required|numeric',
            'accuracy' => 'required|numeric',
        ]);

        $user = $request->user();

        if (empty($user->face_id)) {
            return response()->json([
                'success' => false,
                'message' => 'Face ID belum terdaftar.'
            ],400);
        }

        $today = now()->toDateString();

        $absensi = Absensi::where('user_id',$user->id)
            ->whereDate('tanggal',$today)
            ->first();

        if (!$absensi) {
            return response()->json([
                'success'=>false,
                'message'=>'Silakan lakukan absen masuk terlebih dahulu.'
            ],400);
        }

        if ($absensi->jam_keluar) {
            return response()->json([
                'success'=>false,
                'message'=>'Anda sudah melakukan absen pulang.'
            ],400);
        }

        $setting = AbsensiSetting::first();

        if (!$setting) {
            return response()->json([
                'success'=>false,
                'message'=>'Pengaturan absensi belum dibuat.'
            ],500);
        }

        $now = now()->format('H:i:s');

        if ($now < $setting->jam_pulang_mulai) {
            return response()->json([
                'success'=>false,
                'message'=>'Absen pulang belum dibuka.'
            ],400);
        }

        if ($now > $setting->jam_pulang_selesai) {
            return response()->json([
                'success'=>false,
                'message'=>'Jam absen pulang telah berakhir.'
            ],400);
        }

        if ($request->accuracy > 75) {
            return response()->json([
                'success'=>false,
                'message'=>'Sinyal GPS kurang akurat.'
            ],400);
        }

        $distance = self::calculateDistance(
            $request->latitude,
            $request->longitude,
            $setting->latitude,
            $setting->longitude
        );

        if ($distance > $setting->radius) {
            return response()->json([
                'success'=>false,
                'message'=>'Anda berada di luar area absensi.'
            ],400);
        }

        if ($setting->wifi_required) {

            $request->validate([
                'wifi_bssid'=>'required|string'
            ]);

            if (
                strtolower(trim($request->wifi_bssid))
                != strtolower(trim($setting->wifi_bssid))
            ){
                return response()->json([
                    'success'=>false,
                    'message'=>'Anda harus menggunakan WiFi sekolah.'
                ],400);
            }
        }

        $faceResult = $this->verifyFace($user,$request);

        if ($faceResult instanceof \Illuminate\Http\JsonResponse) {
            return $faceResult;
        }

        // Catatan: absen pulang HANYA meng-update baris absensi yang
        // sudah ada (dibuat saat absen masuk). kelas_id-nya TIDAK
        // disentuh di sini, jadi tetap mengunci kelas yang sama dengan
        // saat siswa absen masuk tadi pagi.
        $absensi->update([
            'jam_keluar'       => now()->format('H:i:s'),

            'latitude_pulang'  => $request->latitude,
            'longitude_pulang' => $request->longitude,

            'accuracy'         => $request->accuracy,
            'wifi_bssid'       => $request->wifi_bssid,
            'is_mocked'        => $request->boolean('is_mocked'),
        ]);

        return response()->json([
            'success'=>true,
            'message'=>'Absen pulang berhasil.',
            'similarity'=>$faceResult['similarity'],
            'data'=>$absensi
        ]);
    }

    public function today(Request $request)
    {
        $user = $request->user();

        $today = now()->toDateString();

        $absensi = Absensi::where('user_id', $user->id)
            ->whereDate('tanggal', $today)
            ->first();

        return response()->json([
            'success' => true,
            'data' => $absensi,
        ]);
    }

    public function riwayat(Request $request)
    {
        $user = $request->user();

        $riwayat = Absensi::where('user_id', $user->id)
            ->orderByDesc('tanggal')
            ->limit(30)
            ->get();

        return response()->json([
            'success' => true,
            'data' => $riwayat,
        ]);
    }

    private function verifyFace($user, Request $request)
    {
        $faceController = new FaceController();

        $verifyRequest = new Request();
        $verifyRequest->merge([
            'user_id' => $user->id
        ]);

        $verifyRequest->files->set(
            'photo',
            $request->file('photo')
        );

        $verifyResponse = $faceController->verify($verifyRequest);

        $verify = json_decode(
            $verifyResponse->getContent(),
            true
        );

        if (!$verify['success']) {
            return response()->json($verify);
        }

        if (!$verify['result']['success']) {
            return response()->json([
                'success' => false,
                'message' => $verify['result']['message']
            ],400);
        }

        // ==========================
        // Kasus spoofing (foto-dari-foto / replay attack)
        // ==========================
        // WAJIB dicek SEBELUM pengecekan "match" biasa, karena kalau
        // spoof_detected == true, FaceController sudah memaksa
        // match == false juga -> tanpa pengecekan terpisah ini, pesan
        // spesifik dari FaceController akan tertimpa jadi "Wajah tidak
        // cocok." generik di bawah, dan admin tidak akan bisa
        // membedakan "orangnya salah" vs "ini percobaan spoofing".
        if (($verify['result']['spoof_detected'] ?? false) === true) {
            return response()->json([
                'success' => false,
                'message' => $verify['result']['message']
                    ?? 'Terdeteksi kemungkinan foto tidak asli. Pastikan Anda mengambil foto langsung dari kamera.',
                'spoof_detected' => true,
            ], 400);
        }

        if (!$verify['result']['match']) {
            return response()->json([
                'success'=>false,
                'message'=>'Wajah tidak cocok.'
            ],400);
        }

        return [
            'similarity'=>$verify['result']['similarity']
        ];
    }

    /**
     * Sinkronisasi absensi offline (dikirim oleh SyncService di Flutter
     * setelah HP kembali online).
     *
     * ==========================================================
     * PERUBAHAN (fix)
     * ==========================================================
     * Endpoint ini sekarang menjalankan validasi yang SAMA PERSIS
     * dengan jalur online (store()/pulang()): jendela waktu absen,
     * akurasi GPS, radius lokasi, WiFi sekolah, dan verifikasi wajah
     * (termasuk anti-spoof). Satu-satunya beda: perbandingan waktu
     * memakai client_captured_at (waktu HP saat foto diambil, sudah
     * dikoreksi offset), BUKAN now(), karena data ini historis (baru
     * terkirim setelah HP online lagi).
     *
     * TIDAK ADA LAGI status "pending_review menunggu admin". Kalau
     * semua validasi lolos -> langsung tersimpan (sync_status:
     * 'synced'), identik hasil akhirnya dengan absen online. Kalau ada
     * satu saja validasi yang gagal (jam/GPS/radius/WiFi/wajah) ->
     * ditolak FINAL, response membawa flag `rejected: true` supaya
     * client (SyncService) tahu ini keputusan final dan tidak boleh
     * di-retry otomatis.
     *
     * Kegagalan TEKNIS (setting belum dibuat, BSSID sekolah belum
     * diatur oleh admin, exception tak terduga saat simpan) TIDAK
     * membawa flag `rejected` -> client akan menandainya `failed`
     * (boleh dicoba lagi nanti), karena ini bukan penolakan atas data
     * absensinya, melainkan masalah konfigurasi/sistem.
     */
    public function sync(Request $request)
    {
        $request->validate([
            'client_uuid' => 'required|string',
            'tanggal' => 'required|date',
            'type' => 'required|in:masuk,pulang',

            'latitude' => 'required|numeric',
            'longitude' => 'required|numeric',
            'accuracy' => 'required|numeric',

            'client_captured_at' => 'required|date',

            // ✅ tambahan: umur verifikasi NTP terakhir di HP (detik),
            // dikirim Flutter dari LocalDbService.getTimeOffsetAge().
            // -1 = device belum pernah verifikasi NTP sejak install.
            'time_offset_age_seconds' => 'nullable|integer',

            'photo' => 'required|image',

            'wifi_bssid' => 'nullable|string',
            'is_mocked' => 'nullable|boolean',
        ]);

        $user = $request->user();

        // ==========================
        // Idempotensi: kalau client_uuid ini sudah pernah masuk,
        // jangan diproses ulang (mencegah duplikasi kalau request
        // terkirim dua kali / response sebelumnya gagal diterima
        // client walau sebenarnya sudah tersimpan di server).
        // ==========================
        $existing = Absensi::where(
            'client_uuid',
            $request->client_uuid
        )->first();

        if ($existing) {
            return response()->json([
                'success' => true,
                'sync_status' => 'synced',
                'message' => 'Sudah pernah disinkronkan.'
            ]);
        }

        $setting = AbsensiSetting::first();

        if (!$setting) {
            // Kegagalan teknis (konfigurasi belum ada), bukan
            // penolakan data -> boleh di-retry.
            return response()->json([
                'success' => false,
                'message' => 'Pengaturan absensi belum dibuat.'
            ], 500);
        }

        $capturedAt = \Carbon\Carbon::parse($request->client_captured_at);
        $capturedTime = $capturedAt->format('H:i:s');

        // ==========================
        // ✅ tambahan: validasi tanggal/jam perangkat vs waktu server.
        // ==========================
        // Ini penutup celah utama: sebelumnya jendela waktu absen di
        // bawah dicek memakai client_captured_at APA ADANYA tanpa
        // pernah dibandingkan ke jam server sungguhan. Kalau user
        // memundurkan tanggal HP sebelum offline lalu absen, data yang
        // disinkronkan nanti tetap dianggap "tepat waktu" walau
        // sebenarnya diambil di luar jendela absen yang sebenarnya.
        //
        // Aturan:
        // 1. Kalau device belum pernah verifikasi NTP sama sekali
        //    sejak install (time_offset_age_seconds null / -1) ->
        //    tidak ada dasar kepercayaan apa pun terhadap jam device
        //    ini -> tolak final.
        // 2. Kalau client_captured_at menyimpang dari jam server SAAT
        //    request diterima lebih dari toleransi offline yang wajar
        //    -> tolak final. Toleransi disusun dari: sedikit slack
        //    untuk latensi/jam server (beberapa menit) DITAMBAH
        //    perkiraan lama HP offline (time_offset_age_seconds),
        //    tapi tetap dibatasi maksimum supaya tidak bisa
        //    "menabung" absensi berhari-hari.
        $offsetAgeSeconds = $request->time_offset_age_seconds;

        if ($offsetAgeSeconds === null || $offsetAgeSeconds < 0) {
            return response()->json([
                'success' => false,
                'rejected' => true,
                'message' => 'Tanggal/jam perangkat Anda belum pernah terverifikasi ke server. Sambungkan internet lalu buka ulang aplikasi sebelum absen.'
            ], 400);
        }

        $maxOfflineSeconds = 60 * 60 * 24; // maksimum toleransi offline: 24 jam
        $baseSlackSeconds = 5 * 60; // slack dasar untuk latensi/jitter NTP

        $allowedDriftSeconds = min(
            $baseSlackSeconds + $offsetAgeSeconds,
            $baseSlackSeconds + $maxOfflineSeconds
        );

        $driftSeconds = abs(now()->diffInSeconds($capturedAt));

        if ($driftSeconds > $allowedDriftSeconds) {
            return response()->json([
                'success' => false,
                'rejected' => true,
                'message' => 'Tanggal/jam perangkat Anda tidak sesuai dengan waktu server saat absensi diambil. Silakan atur tanggal & jam perangkat secara otomatis, lalu absen ulang.'
            ], 400);
        }

        // ==========================
        // Cek jendela waktu absen, berdasarkan waktu foto diambil
        // (client_captured_at), BUKAN waktu server sekarang.
        // Identik ambang batas dengan store()/pulang().
        // ==========================
        if ($request->type == 'masuk') { 
            if ($capturedTime < $setting->jam_absen_mulai) {
                return response()->json([
                    'success' => false,
                    'rejected' => true,
                    'message' => 'Absensi belum dibuka.'
                ], 400);
            }

            if ($capturedTime > $setting->jam_absen_selesai) {
                return response()->json([
                    'success' => false,
                    'rejected' => true,
                    'message' => 'Jam absensi sudah berakhir.'
                ], 400);
            }
        } else {
            if ($capturedTime < $setting->jam_pulang_mulai) {
                return response()->json([
                    'success' => false,
                    'rejected' => true,
                    'message' => 'Absen pulang belum dibuka.'
                ], 400);
            }

            if ($capturedTime > $setting->jam_pulang_selesai) {
                return response()->json([
                    'success' => false,
                    'rejected' => true,
                    'message' => 'Jam absen pulang telah berakhir.'
                ], 400);
            }
        }

        // ==========================
        // Cek akurasi GPS
        // ==========================
        if ($request->accuracy > 75) {
            return response()->json([
                'success' => false,
                'rejected' => true,
                'message' => 'Sinyal GPS kurang akurat (± ' . round($request->accuracy) . ' meter).'
            ], 400);
        }

        // ==========================
        // Cek radius lokasi
        // ==========================
        $distance = self::calculateDistance(
            $request->latitude,
            $request->longitude,
            $setting->latitude,
            $setting->longitude
        );

        if ($distance > $setting->radius) {
            return response()->json([
                'success' => false,
                'rejected' => true,
                'message' => 'Anda berada di luar area absensi. Jarak: ' . round($distance) . ' meter.'
            ], 400);
        }

        // ==========================
        // Cek WiFi sekolah
        // ==========================
        if ($setting->wifi_required) {
            $userBssid = strtolower(trim($request->wifi_bssid ?? ''));
            $schoolBssid = strtolower(trim($setting->wifi_bssid ?? ''));

            if (empty($schoolBssid)) {
                // Kesalahan konfigurasi admin, bukan penolakan data
                // user -> boleh di-retry.
                return response()->json([
                    'success' => false,
                    'message' => 'BSSID WiFi sekolah belum diatur oleh admin.'
                ], 500);
            }

            if ($userBssid !== $schoolBssid) {
                return response()->json([
                    'success' => false,
                    'rejected' => true,
                    'message' => 'Anda harus terhubung ke jaringan WiFi sekolah untuk melakukan absensi.'
                ], 400);
            }
        }

        // ==========================
        // Face ID harus sudah ada
        // ==========================
        if (empty($user->face_id)) {
            return response()->json([
                'success' => false,
                'rejected' => true,
                'message' => 'Face ID belum terdaftar.'
            ], 400);
        }

        $today = $request->tanggal;

        $absensi = Absensi::where('user_id', $user->id)
            ->whereDate('tanggal', $today)
            ->first();

        // ==========================
        // Cek status absen hari ini, identik logika store()/pulang().
        // Kalau ternyata sudah ada record (mis. sudah absen dari
        // device lain / sudah tersinkron sebelumnya), ini BUKAN
        // penolakan data -> anggap saja sudah sinkron, bukan rejected.
        // ==========================
        if ($request->type == 'masuk') {
            if ($absensi) {
                return response()->json([
                    'success' => true,
                    'sync_status' => 'synced',
                    'message' => 'Sudah melakukan absensi hari ini.'
                ]);
            }
        } else {
            if (!$absensi) {
                return response()->json([
                    'success' => false,
                    'rejected' => true,
                    'message' => 'Silakan lakukan absen masuk terlebih dahulu.'
                ], 400);
            }

            if ($absensi->jam_keluar) {
                return response()->json([
                    'success' => true,
                    'sync_status' => 'synced',
                    'message' => 'Sudah melakukan absen pulang.'
                ]);
            }
        }

        // ==========================
        // Verifikasi wajah (identik jalur online, termasuk anti-spoof).
        // Gagal di sini = ditolak FINAL, bukan pending_review.
        // ==========================
        $faceResult = $this->verifyFace($user, $request);

        if ($faceResult instanceof \Illuminate\Http\JsonResponse) {
            $verify = json_decode($faceResult->getContent(), true);

            return response()->json([
                'success' => false,
                'rejected' => true,
                'message' => $verify['message'] ?? 'Wajah tidak cocok.',
                'spoof_detected' => $verify['spoof_detected'] ?? false,
            ], 400);
        }

        // ==========================
        // Semua validasi lolos -> simpan, identik hasil akhirnya
        // dengan absen online.
        // ==========================
        DB::beginTransaction();

        try {

            if ($request->type == 'masuk') {

                $jamMasuk = $capturedAt->format('H:i:s');

                $status = "hadir";

                if ($jamMasuk > $setting->jam_terlambat) {
                    $status = "terlambat";
                }

                $absensi = Absensi::create([

                    'user_id' => $user->id,

                    // Sama seperti store(): kunci kelas siswa PADA SAAT
                    // absen masuk ini terjadi (pakai client_captured_at,
                    // bukan waktu sync), bukan kelas siswa saat ini.
                    'kelas_id' => $user->kelas_id,

                    'tanggal' => $today,

                    'jam_masuk' => $jamMasuk,

                    'status' => $status,

                    'latitude' => $request->latitude,
                    'longitude' => $request->longitude,

                    'accuracy' => $request->accuracy,
                    'wifi_bssid' => $request->wifi_bssid,
                    'is_mocked' => $request->boolean('is_mocked'),

                    'client_uuid' => $request->client_uuid,
                    'client_captured_at' => $request->client_captured_at,
                    'server_received_at' => now(),
                ]);

            } else {

                // Absen pulang: hanya update baris yang sudah ada,
                // kelas_id yang sudah terkunci sejak absen masuk TIDAK
                // ikut diubah di sini.
                $absensi->update([

                    'jam_keluar' => $capturedAt->format('H:i:s'),

                    'latitude_pulang' => $request->latitude,
                    'longitude_pulang' => $request->longitude,

                    'accuracy' => $request->accuracy,
                    'wifi_bssid' => $request->wifi_bssid,
                    'is_mocked' => $request->boolean('is_mocked'),

                    'client_uuid' => $request->client_uuid,
                    'client_captured_at' => $request->client_captured_at,
                    'server_received_at' => now(),
                ]);
            }

            DB::commit();

            return response()->json([
                'success' => true,
                'sync_status' => 'synced',
                'similarity' => $faceResult['similarity'],
                'message' => 'Sinkronisasi berhasil.'
            ]);

        } catch (\Throwable $e) {

            DB::rollBack();

            // Kegagalan tak terduga saat menyimpan -> teknis, bukan
            // penolakan data -> boleh di-retry.
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 500);
        }
    }

    private static function calculateDistance($lat1, $lon1, $lat2, $lon2)
    {
        $earthRadius = 6371000; // meter

        $latDiff = deg2rad($lat2 - $lat1);
        $lonDiff = deg2rad($lon2 - $lon1);

        $a = sin($latDiff / 2) * sin($latDiff / 2) +
             cos(deg2rad($lat1)) * cos(deg2rad($lat2)) *
             sin($lonDiff / 2) * sin($lonDiff / 2);

        $c = 2 * atan2(sqrt($a), sqrt(1 - $a));

        return $earthRadius * $c;
    }


}

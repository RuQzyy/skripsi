<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Absensi;
use App\Models\Kelas;
use Illuminate\Http\Request;
use App\Exports\AbsensiExport;
use Maatwebsite\Excel\Facades\Excel;

class GuruController extends Controller
{
    // ==========================
    // Info kelas yang diwali guru
    // ==========================
    public function kelasSaya(Request $request)
    {
        $guru = $request->user();

        $kelas = Kelas::with('siswa')
            ->where('wali_kelas_id', $guru->id)
            ->first();

        if (!$kelas) {
            return response()->json([
                'success' => false,
                'message' => 'Anda belum menjadi wali kelas.',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data' => [
                'id'         => $kelas->id,
                'nama_kelas' => $kelas->nama_kelas,
                'total_siswa' => $kelas->siswa->count(),
            ],
        ]);
    }

    // ==========================
    // Rekap kehadiran hari ini
    // ==========================
    public function kehadiranHariIni(Request $request)
    {
        $guru = $request->user();

        $kelas = Kelas::with([
            'siswa.absensis' => function ($q) {
                $q->whereDate('tanggal', today());
            }
        ])
        ->where('wali_kelas_id', $guru->id)
        ->first();

        if (!$kelas) {
            return response()->json([
                'success' => false,
                'message' => 'Anda belum menjadi wali kelas.',
            ], 404);
        }

        $today = now()->toDateString();

        $siswaList = $kelas->siswa->map(function ($siswa) use ($today) {
            $absensi = $siswa->absensis->first();

            return [
                'id'       => $siswa->id,
                'name'     => $siswa->name,
                'nisn'     => $siswa->nisn,
                'photo'    => $siswa->photo,
                'status'   => $absensi ? $absensi->status : 'Belum Absen',
                'jam_masuk' => $absensi ? $absensi->jam_masuk : null,
                'catatan'  => $absensi ? $absensi->catatan : null,
            ];
        });

        $hadir     = $siswaList->filter(fn($s) => strtolower(trim($s['status'])) === 'hadir')->count();
        $terlambat = $siswaList->filter(fn($s) => strtolower(trim($s['status'])) === 'terlambat')->count();
        $alpha     = $siswaList->filter(fn($s) => strtolower(trim($s['status'])) === 'alpha')->count();
        $izin      = $siswaList->filter(fn($s) => strtolower(trim($s['status'])) === 'izin')->count();
        $sakit     = $siswaList->filter(fn($s) => strtolower(trim($s['status'])) === 'sakit')->count();
        $bolos     = $siswaList->filter(fn($s) => strtolower(trim($s['status'])) === 'bolos')->count();
        $belum     = $siswaList->filter(fn($s) => strtolower(trim($s['status'])) === 'belum absen')->count();

        return response()->json([
            'success' => true,
            'data' => [
                'tanggal'    => $today,
                'nama_kelas' => $kelas->nama_kelas,
                'statistik'  => [
                    'hadir'       => $hadir,
                    'terlambat'   => $terlambat,
                    'alpha'       => $alpha,
                    'izin'        => $izin,
                    'sakit'       => $sakit,
                    'bolos'       => $bolos,
                    'belum_absen' => $belum,
                    'total'       => $siswaList->count(),
                ],
                'siswa' => $siswaList->values(),
            ],
        ]);
    }

    // ==========================
    // Riwayat absensi per siswa
    // ==========================
    public function riwayatSiswa(Request $request, $siswaId)
    {
        $guru = $request->user();

        $kelas = Kelas::where('wali_kelas_id', $guru->id)->first();

        if (!$kelas) {
            return response()->json([
                'success' => false,
                'message' => 'Anda belum menjadi wali kelas.',
            ], 404);
        }

        // Pastikan siswa memang di kelas ini
        $siswa = $kelas->siswa()->where('id', $siswaId)->first();

        if (!$siswa) {
            return response()->json([
                'success' => false,
                'message' => 'Siswa tidak ditemukan di kelas Anda.',
            ], 404);
        }

        // Statistik dihitung dari SELURUH data (bukan per-halaman), pakai query terpisah + ringan
        $statistikRaw = Absensi::where('user_id', $siswaId)
            ->selectRaw('LOWER(TRIM(status)) as status_key, COUNT(*) as jumlah')
            ->groupBy('status_key')
            ->pluck('jumlah', 'status_key');

        $hadir     = $statistikRaw['hadir'] ?? 0;
        $terlambat = $statistikRaw['terlambat'] ?? 0;
        $alpha     = $statistikRaw['alpha'] ?? 0;
        $izin      = $statistikRaw['izin'] ?? 0;
        $sakit     = $statistikRaw['sakit'] ?? 0;
        $bolos     = $statistikRaw['bolos'] ?? 0;
        $total     = $statistikRaw->sum();

        // Data riwayat diambil per-halaman (paginasi)
        $riwayatPaginated = Absensi::where('user_id', $siswaId)
            ->orderByDesc('tanggal')
            ->paginate(20); // 20 data per halaman, sesuaikan kalau perlu

        $riwayat = $riwayatPaginated->getCollection()->map(function ($a) {
            return [
                'id'        => $a->id,
                'tanggal'   => $a->tanggal,
                'jam_masuk' => $a->jam_masuk,
                'status'    => $a->status,
                'catatan'   => $a->catatan,
            ];
        });

        return response()->json([
            'success' => true,
            'data' => [
                'siswa' => [
                    'id'    => $siswa->id,
                    'name'  => $siswa->name,
                    'nisn'  => $siswa->nisn,
                    'photo' => $siswa->photo,
                ],
                'statistik' => [
                    'hadir'     => $hadir,
                    'terlambat' => $terlambat,
                    'alpha'     => $alpha,
                    'izin'      => $izin,
                    'sakit'     => $sakit,
                    'bolos'     => $bolos,
                    'total'     => $total,
                ],
                'riwayat'      => $riwayat->values(),
                'current_page' => $riwayatPaginated->currentPage(),
                'last_page'    => $riwayatPaginated->lastPage(),
            ],
        ]);
    }

    // ==========================
    // Rekap kehadiran per tanggal
    // ==========================
    public function kehadiranPerTanggal(Request $request)
    {
        $guru = $request->user();

        $kelas = Kelas::with('siswa')
            ->where('wali_kelas_id', $guru->id)
            ->first();

        if (!$kelas) {
            return response()->json([
                'success' => false,
                'message' => 'Anda belum menjadi wali kelas.',
            ], 404);
        }

        $siswaIds = $kelas->siswa->pluck('id');

        // Ambil semua tanggal unik sebagai string (bukan Carbon)
        $tanggalList = Absensi::whereIn('user_id', $siswaIds)
            ->selectRaw('DATE(tanggal) as tanggal')
            ->distinct()
            ->orderByDesc('tanggal')
            ->pluck('tanggal'); // sudah string karena selectRaw

        $result = $tanggalList->map(function ($tanggal) use ($kelas) {

            $siswaList = $kelas->siswa->map(function ($siswa) use ($tanggal) {
                $absensi = Absensi::where('user_id', $siswa->id)
                    ->whereRaw('DATE(tanggal) = ?', [$tanggal])
                    ->first();

                return [
                    'id'        => $siswa->id,
                    'name'      => $siswa->name,
                    'nisn'      => $siswa->nisn,
                    'photo'     => $siswa->photo,
                    'status'    => $absensi ? $absensi->status : 'Belum Absen',
                    'jam_masuk' => $absensi ? $absensi->jam_masuk : null,
                    'catatan'   => $absensi ? $absensi->catatan : null,
                ];
            });

            $hadir     = $siswaList->filter(fn($s) => strtolower(trim($s['status'])) === 'hadir')->count();
            $terlambat = $siswaList->filter(fn($s) => strtolower(trim($s['status'])) === 'terlambat')->count();
            $alpha     = $siswaList->filter(fn($s) => strtolower(trim($s['status'])) === 'alpha')->count();
            $izin      = $siswaList->filter(fn($s) => strtolower(trim($s['status'])) === 'izin')->count();
            $sakit     = $siswaList->filter(fn($s) => strtolower(trim($s['status'])) === 'sakit')->count();
            $bolos     = $siswaList->filter(fn($s) => strtolower(trim($s['status'])) === 'bolos')->count();
            $belum     = $siswaList->filter(fn($s) => strtolower(trim($s['status'])) === 'belum absen')->count();

            return [
                'tanggal'   => $tanggal,
                'statistik' => [
                    'hadir'       => $hadir,
                    'terlambat'   => $terlambat,
                    'alpha'       => $alpha,
                    'izin'        => $izin,
                    'sakit'       => $sakit,
                    'bolos'       => $bolos,
                    'belum_absen' => $belum,
                    'total'       => $siswaList->count(),
                ],
                'siswa' => $siswaList->values(),
            ];
        });

        return response()->json([
            'success'    => true,
            'nama_kelas' => $kelas->nama_kelas,
            'data'       => $result->values(),
        ]);
    }

    // ==========================
    // Download rekap absensi (Excel)
    // ==========================
    public function laporanAbsensi(Request $request)
    {
        $request->validate([
            'bulan_awal'  => 'required|date_format:Y-m',
            'bulan_akhir' => 'required|date_format:Y-m',
        ]);

        $guru = $request->user();

        $kelas = Kelas::with('siswa')
            ->where('wali_kelas_id', $guru->id)
            ->first();

        if (!$kelas) {
            return response()->json([
                'success' => false,
                'message' => 'Anda belum menjadi wali kelas.',
            ], 404);
        }

        $siswaIds = $kelas->siswa->pluck('id');

        $fileName = 'Rekap-Absensi-' . str_replace(' ', '_', $kelas->nama_kelas)
            . '-' . $request->bulan_awal . '_sd_' . $request->bulan_akhir . '.xlsx';

        return Excel::download(
            new AbsensiExport($siswaIds, $request->bulan_awal, $request->bulan_akhir, $kelas->nama_kelas),
            $fileName
        );
    }

    // ==========================
    // Ubah status kehadiran siswa
    // ==========================
    public function updateStatusAbsensi(Request $request, $absensiId)
    {
        $request->validate([
            'status'  => 'required|in:Hadir,Terlambat,Alpha,Izin,Sakit,Bolos',
            'catatan' => 'nullable|required_if:status,Izin|string|max:255',
        ]);

        $guru = $request->user();

        $kelas = Kelas::with('siswa')->where('wali_kelas_id', $guru->id)->first();

        if (!$kelas) {
            return response()->json([
                'success' => false,
                'message' => 'Anda belum menjadi wali kelas.',
            ], 404);
        }

        $siswaIds = $kelas->siswa->pluck('id');

        $absensi = Absensi::where('id', $absensiId)
            ->whereIn('user_id', $siswaIds)
            ->first();

        if (!$absensi) {
            return response()->json([
                'success' => false,
                'message' => 'Data absensi tidak ditemukan atau bukan milik siswa di kelas Anda.',
            ], 404);
        }

        $absensi->status = $request->status;
        // Kalau bukan Izin, catatan dikosongkan supaya tidak nyangkut dari status sebelumnya
        $absensi->catatan = $request->status === 'Izin' ? $request->catatan : null;
        $absensi->save();

        return response()->json([
            'success' => true,
            'message' => 'Status kehadiran berhasil diubah.',
            'data' => $absensi,
        ]);
    }
}

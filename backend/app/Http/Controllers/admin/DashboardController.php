<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Pengumuman;
use App\Models\User;
use App\Models\Kelas;
use App\Models\Absensi;
use Carbon\Carbon;

class DashboardController extends Controller
{
    public function index()
    {
        // ==========================
        // Statistik utama (card atas)
        // ==========================
        $totalSiswa = User::where('role', 'siswa')->count();
        $totalGuru  = User::where('role', 'guru')->count();
        $totalKelas = Kelas::count();

        $absensiHariIni = Absensi::whereDate('tanggal', today())->get();
        $totalAbsenHariIni = $absensiHariIni->count();
        $hadirHariIni = $absensiHariIni->whereIn('status', ['Hadir', 'Terlambat'])->count();

        $persenKehadiranHariIni = $totalAbsenHariIni > 0
            ? round(($hadirHariIni / $totalAbsenHariIni) * 100)
            : 0;

        // ==========================
        // Grafik bar 6 bulan terakhir
        // ==========================
        $bulanLabels = [];
        $dataHadir = [];
        $dataTidakHadir = [];

        for ($i = 5; $i >= 0; $i--) {
            $bulan = Carbon::now()->subMonths($i);
            $bulanLabels[] = $bulan->translatedFormat('M');

            $absensiBulan = Absensi::whereMonth('tanggal', $bulan->month)
                ->whereYear('tanggal', $bulan->year)
                ->get();

            $totalBulan = $absensiBulan->count();
            $hadirBulan = $absensiBulan->whereIn('status', ['Hadir', 'Terlambat'])->count();

            $persenHadir = $totalBulan > 0 ? round(($hadirBulan / $totalBulan) * 100) : 0;
            $persenTidakHadir = 100 - $persenHadir;

            $dataHadir[] = $totalBulan > 0 ? $persenHadir : 0;
            $dataTidakHadir[] = $totalBulan > 0 ? $persenTidakHadir : 0;
        }

        // ==========================
        // Ringkasan kehadiran bulan berjalan
        // ==========================
        $absensiBulanIni = Absensi::whereMonth('tanggal', now()->month)
            ->whereYear('tanggal', now()->year)
            ->get();

        $totalBulanIni = $absensiBulanIni->count();

        $ringkasan = [
            'hadir' => 0,
            'izin'  => 0,
            'sakit' => 0,
            'alpha' => 0,
        ];

        if ($totalBulanIni > 0) {
            $ringkasan['hadir'] = round(
                ($absensiBulanIni->whereIn('status', ['Hadir', 'Terlambat'])->count() / $totalBulanIni) * 100
            );
            $ringkasan['izin'] = round(
                ($absensiBulanIni->where('status', 'Izin')->count() / $totalBulanIni) * 100
            );
            $ringkasan['sakit'] = round(
                ($absensiBulanIni->where('status', 'Sakit')->count() / $totalBulanIni) * 100
            );
            $ringkasan['alpha'] = round(
                ($absensiBulanIni->where('status', 'Alpha')->count() / $totalBulanIni) * 100
            );
        }

        // ==========================
        // Pengumuman terbaru
        // ==========================
        $pengumumanTerbaru = Pengumuman::latest()
            ->take(3)
            ->get();

        return view('admin.dashboard', compact(
            'pengumumanTerbaru',
            'totalSiswa',
            'totalGuru',
            'totalKelas',
            'persenKehadiranHariIni',
            'bulanLabels',
            'dataHadir',
            'dataTidakHadir',
            'ringkasan'
        ));
    }
}

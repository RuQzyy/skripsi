<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Kelas;
use App\Models\Absensi;
use Illuminate\Http\Request;
use App\Exports\AbsensiExport;
use App\Exports\LaporanAbsensiSemuaKelasExport;
use Maatwebsite\Excel\Facades\Excel;

class LaporanAbsensiController extends Controller
{
    // ==========================
    // Halaman utama laporan
    // ==========================
    public function index(Request $request)
    {
        $bulanAwal  = $request->bulan_awal;
        $bulanAkhir = $request->bulan_akhir;

        $rekap = null;

        if ($bulanAwal && $bulanAkhir) {
            $awal  = $bulanAwal . '-01';
            $akhir = date('Y-m-t', strtotime($bulanAkhir . '-01'));

            $rekap = Kelas::with('siswa')
                ->orderBy('nama_kelas')
                ->get()
                ->map(function ($kelas) use ($awal, $akhir) {
                    $siswaIds = $kelas->siswa->pluck('id');

                    $absensi = Absensi::whereIn('user_id', $siswaIds)
                        ->whereBetween('tanggal', [$awal, $akhir])
                        ->get();

                    return [
                        'id'          => $kelas->id,
                        'nama_kelas'  => $kelas->nama_kelas,
                        'total_siswa' => $siswaIds->count(),
                        'hadir'       => $absensi->where('status', 'Hadir')->count(),
                        'terlambat'   => $absensi->where('status', 'Terlambat')->count(),
                        'izin'        => $absensi->where('status', 'Izin')->count(),
                        'sakit'       => $absensi->where('status', 'Sakit')->count(),
                        'alpha'       => $absensi->where('status', 'Alpha')->count(),
                    ];
                });
        }

        return view('admin.laporan', compact('rekap', 'bulanAwal', 'bulanAkhir'));
    }

    // ==========================
    // Download 1 kelas
    // ==========================
    public function downloadKelas(Request $request, $kelasId)
    {
        $request->validate([
            'bulan_awal'  => 'required|date_format:Y-m',
            'bulan_akhir' => 'required|date_format:Y-m',
        ]);

        $kelas = Kelas::with('siswa')->findOrFail($kelasId);
        $siswaIds = $kelas->siswa->pluck('id');

        $fileName = 'Rekap-Absensi-' . str_replace(' ', '_', $kelas->nama_kelas)
            . '-' . $request->bulan_awal . '_sd_' . $request->bulan_akhir . '.xlsx';

        return Excel::download(
            new AbsensiExport($siswaIds, $request->bulan_awal, $request->bulan_akhir, $kelas->nama_kelas),
            $fileName
        );
    }

    // ==========================
    // Download semua kelas (1 file, sheet per kelas)
    // ==========================
    public function downloadSemua(Request $request)
    {
        $request->validate([
            'bulan_awal'  => 'required|date_format:Y-m',
            'bulan_akhir' => 'required|date_format:Y-m',
        ]);

        $fileName = 'Rekap-Absensi-Semua-Kelas-' . $request->bulan_awal . '_sd_' . $request->bulan_akhir . '.xlsx';

        return Excel::download(
            new LaporanAbsensiSemuaKelasExport($request->bulan_awal, $request->bulan_akhir),
            $fileName
        );
    }
}

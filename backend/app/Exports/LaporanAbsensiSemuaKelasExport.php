<?php

namespace App\Exports;

use App\Models\Kelas;
use Maatwebsite\Excel\Concerns\WithMultipleSheets;

class LaporanAbsensiSemuaKelasExport implements WithMultipleSheets
{
    protected $bulanAwal;
    protected $bulanAkhir;

    public function __construct($bulanAwal, $bulanAkhir)
    {
        $this->bulanAwal  = $bulanAwal;
        $this->bulanAkhir = $bulanAkhir;
    }

    public function sheets(): array
    {
        $sheets = [];

        $kelasList = Kelas::with('siswa')->orderBy('nama_kelas')->get();

        foreach ($kelasList as $kelas) {
            $siswaIds = $kelas->siswa->pluck('id');

            $sheets[] = new AbsensiExport(
                $siswaIds,
                $this->bulanAwal,
                $this->bulanAkhir,
                $kelas->nama_kelas
            );
        }

        return $sheets;
    }
}

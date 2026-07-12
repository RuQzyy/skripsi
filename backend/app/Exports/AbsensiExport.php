<?php

namespace App\Exports;

use App\Models\Absensi;
use Carbon\Carbon;
use Maatwebsite\Excel\Concerns\FromCollection;
use Maatwebsite\Excel\Concerns\WithHeadings;
use Maatwebsite\Excel\Concerns\WithMapping;
use Maatwebsite\Excel\Concerns\WithTitle;
use Maatwebsite\Excel\Concerns\WithStyles;
use PhpOffice\PhpSpreadsheet\Worksheet\Worksheet;

class AbsensiExport implements FromCollection, WithHeadings, WithMapping, WithTitle, WithStyles
{
    protected $siswaIds;
    protected $bulanAwal;
    protected $bulanAkhir;
    protected $namaKelas;

    public function __construct($siswaIds, $bulanAwal, $bulanAkhir, $namaKelas)
    {
        $this->siswaIds  = $siswaIds;
        $this->bulanAwal = $bulanAwal;
        $this->bulanAkhir = $bulanAkhir;
        $this->namaKelas = $namaKelas;
    }

    public function collection()
    {
        $awal  = $this->bulanAwal . '-01';
        $akhir = date('Y-m-t', strtotime($this->bulanAkhir . '-01')); // tanggal terakhir bulan itu

        return Absensi::with('user')
            ->whereIn('user_id', $this->siswaIds)
            ->whereBetween('tanggal', [$awal, $akhir])
            ->orderBy('tanggal')
            ->orderBy('user_id')
            ->get();
    }

    public function headings(): array
    {
        return ['No', 'Tanggal', 'Nama Siswa', 'NISN', 'Jam Masuk', 'Status'];
    }

    public function map($absensi): array
    {
        static $no = 0;
        $no++;

        return [
            $no,
            Carbon::parse($absensi->tanggal)->format('d-m-Y'),
            $absensi->user->name ?? '-',
            $absensi->user->nisn ?? '-',
            $absensi->jam_masuk ?? '-',
            ucfirst(strtolower($absensi->status)),
        ];
    }

    public function title(): string
    {
        return 'Rekap Absensi';
    }

    public function styles(Worksheet $sheet)
    {
        return [1 => ['font' => ['bold' => true]]];
    }
}

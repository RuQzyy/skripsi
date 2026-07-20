<?php

namespace App\Exports;

use App\Models\Absensi;
use Carbon\Carbon;
use Maatwebsite\Excel\Concerns\FromCollection;
use Maatwebsite\Excel\Concerns\WithHeadings;
use Maatwebsite\Excel\Concerns\WithMapping;
use Maatwebsite\Excel\Concerns\WithTitle;
use Maatwebsite\Excel\Concerns\WithStyles;
use Maatwebsite\Excel\Concerns\WithColumnWidths;
use Maatwebsite\Excel\Concerns\WithEvents;
use Maatwebsite\Excel\Events\AfterSheet;
use PhpOffice\PhpSpreadsheet\Worksheet\Worksheet;
use PhpOffice\PhpSpreadsheet\Style\Alignment;
use PhpOffice\PhpSpreadsheet\Style\Border;
use PhpOffice\PhpSpreadsheet\Style\Fill;

class AbsensiExport implements
    FromCollection,
    WithHeadings,
    WithMapping,
    WithTitle,
    WithStyles,
    WithColumnWidths,
    WithEvents
{
    protected $siswaIds;
    protected $bulanAwal;
    protected $bulanAkhir;
    protected $namaKelas;

    // Menyimpan data hasil query supaya bisa dipakai lagi untuk ringkasan
    protected $records;

    // Baris tempat header tabel berada (akan diisi otomatis di AfterSheet)
    protected $headerRow = 6;

    // Nomor urut baris, per-instance (bukan static) supaya tidak lanjut ke sheet lain
    protected $rowNumber = 0;

    // Warna tema (samakan dengan warna aplikasi: hijau tua)
    const COLOR_PRIMARY = '1E5631';
    const COLOR_PRIMARY_LIGHT = 'E8F0EA';

    public function __construct($siswaIds, $bulanAwal, $bulanAkhir, $namaKelas)
    {
        $this->siswaIds   = $siswaIds;
        $this->bulanAwal  = $bulanAwal;
        $this->bulanAkhir = $bulanAkhir;
        $this->namaKelas  = $namaKelas;
    }

    // ==========================
    // Data
    // ==========================
    public function collection()
    {
        if ($this->records) {
            return $this->records;
        }

        $awal  = $this->bulanAwal . '-01';
        $akhir = date('Y-m-t', strtotime($this->bulanAkhir . '-01'));

        $this->records = Absensi::with('user')
            ->whereIn('user_id', $this->siswaIds)
            ->whereBetween('tanggal', [$awal, $akhir])
            ->orderBy('tanggal')
            ->orderBy('user_id')
            ->get();

        return $this->records;
    }

    public function headings(): array
    {
        return ['No', 'Tanggal', 'Nama Siswa', 'NISN', 'Jam Masuk', 'Status', 'Catatan'];
    }

    public function map($absensi): array
    {
        $this->rowNumber++;

        return [
            $this->rowNumber,
            Carbon::parse($absensi->tanggal)->format('d-m-Y'),
            $absensi->user->name ?? '-',
            $absensi->user->nisn ?? '-',
            $absensi->jam_masuk ?? '-',
            ucfirst(strtolower($absensi->status)),
            $absensi->catatan ?? '-',
        ];
    }

    public function title(): string
    {
        // Nama sheet Excel maksimal 31 karakter
        return substr('Rekap - ' . $this->namaKelas, 0, 31);
    }

    // ==========================
    // Lebar kolom
    // ==========================
    public function columnWidths(): array
    {
        return [
            'A' => 6,   // No
            'B' => 14,  // Tanggal
            'C' => 26,  // Nama Siswa
            'D' => 16,  // NISN
            'E' => 12,  // Jam Masuk
            'F' => 13,  // Status
            'G' => 32,  // Catatan
        ];
    }

    // ==========================
    // Style dasar heading (akan disempurnakan lagi di AfterSheet)
    // ==========================
    public function styles(Worksheet $sheet)
    {
        return [];
    }

    // ==========================
    // Format periode jadi "Januari 2026 s/d Maret 2026"
    // ==========================
    protected function formatPeriode(): string
    {
        $awal  = Carbon::createFromFormat('Y-m', $this->bulanAwal)->translatedFormat('F Y');
        $akhir = Carbon::createFromFormat('Y-m', $this->bulanAkhir)->translatedFormat('F Y');

        return $awal === $akhir ? $awal : "{$awal} s/d {$akhir}";
    }

    // ==========================
    // Event utama: susun layout profesional
    // ==========================
    public function registerEvents(): array
    {
        return [
            AfterSheet::class => function (AfterSheet $event) {
                $sheet = $event->sheet->getDelegate();
                $lastCol = 'G';
                $totalDataRows = $this->collection()->count();

                // ---------------------------------
                // 1. Sisipkan 5 baris kosong di atas untuk judul & info
                // ---------------------------------
                $sheet->insertNewRowBefore(1, 5);

                // Baris 1: Judul
                $sheet->mergeCells("A1:{$lastCol}1");
                $sheet->setCellValue('A1', 'REKAP ABSENSI SISWA');
                $sheet->getStyle('A1')->getFont()->setBold(true)->setSize(14);
                $sheet->getStyle('A1')->getAlignment()
                    ->setHorizontal(Alignment::HORIZONTAL_CENTER);

                // Baris 2: Nama kelas
                $sheet->mergeCells("A2:{$lastCol}2");
                $sheet->setCellValue('A2', 'Kelas: ' . $this->namaKelas);
                $sheet->getStyle('A2')->getFont()->setBold(true)->setSize(11);
                $sheet->getStyle('A2')->getAlignment()
                    ->setHorizontal(Alignment::HORIZONTAL_CENTER);

                // Baris 3: Periode
                $sheet->mergeCells("A3:{$lastCol}3");
                $sheet->setCellValue('A3', 'Periode: ' . $this->formatPeriode());
                $sheet->getStyle('A3')->getFont()->setSize(11);
                $sheet->getStyle('A3')->getAlignment()
                    ->setHorizontal(Alignment::HORIZONTAL_CENTER);

                // Baris 4: kosong (spasi)
                // Baris 5: kosong (spasi)

                // ---------------------------------
                // 2. Style header tabel (sekarang di baris 6 setelah geser 5 baris)
                // ---------------------------------
                $this->headerRow = 6;
                $headerRange = "A{$this->headerRow}:{$lastCol}{$this->headerRow}";

                $sheet->getStyle($headerRange)->getFont()
                    ->setBold(true)
                    ->getColor()->setRGB('FFFFFF');

                $sheet->getStyle($headerRange)->getFill()
                    ->setFillType(Fill::FILL_SOLID)
                    ->getStartColor()->setRGB(self::COLOR_PRIMARY);

                $sheet->getStyle($headerRange)->getAlignment()
                    ->setHorizontal(Alignment::HORIZONTAL_CENTER)
                    ->setVertical(Alignment::VERTICAL_CENTER);

                $sheet->getRowDimension($this->headerRow)->setRowHeight(22);

                // ---------------------------------
                // 3. Border seluruh tabel (header + data)
                // ---------------------------------
                $firstDataRow = $this->headerRow + 1;
                $lastDataRow  = $this->headerRow + $totalDataRows;
                $tableRange   = "A{$this->headerRow}:{$lastCol}" . ($totalDataRows > 0 ? $lastDataRow : $this->headerRow);

                $sheet->getStyle($tableRange)->getBorders()
                    ->getAllBorders()
                    ->setBorderStyle(Border::BORDER_THIN)
                    ->getColor()->setRGB('B7B7B7');

                // ---------------------------------
                // 4. Alignment isi tabel & zebra striping
                // ---------------------------------
                if ($totalDataRows > 0) {
                    // No, Tanggal, Jam Masuk, Status -> center
                    foreach (['A', 'B', 'E', 'F'] as $col) {
                        $sheet->getStyle("{$col}{$firstDataRow}:{$col}{$lastDataRow}")
                            ->getAlignment()->setHorizontal(Alignment::HORIZONTAL_CENTER);
                    }
                    // NISN -> center juga
                    $sheet->getStyle("D{$firstDataRow}:D{$lastDataRow}")
                        ->getAlignment()->setHorizontal(Alignment::HORIZONTAL_CENTER);

                    // Nama & Catatan -> rata kiri, wrap text untuk catatan
                    $sheet->getStyle("G{$firstDataRow}:G{$lastDataRow}")
                        ->getAlignment()->setWrapText(true);

                    // Zebra striping (baris genap diberi warna terang)
                    for ($row = $firstDataRow; $row <= $lastDataRow; $row++) {
                        if (($row - $firstDataRow) % 2 === 1) {
                            $sheet->getStyle("A{$row}:{$lastCol}{$row}")->getFill()
                                ->setFillType(Fill::FILL_SOLID)
                                ->getStartColor()->setRGB('F5F5F5');
                        }
                    }

                    // Warnai teks status sesuai kondisi
                    for ($row = $firstDataRow; $row <= $lastDataRow; $row++) {
                        $statusValue = strtolower($sheet->getCell("F{$row}")->getValue());
                        $colorMap = [
                            'hadir'     => '1E5631',
                            'terlambat' => 'B8860B',
                            'izin'      => '1F6FB2',
                            'sakit'     => '7B2D9E',
                            'alpha'     => 'C0392B',
                        ];
                        if (isset($colorMap[$statusValue])) {
                            $sheet->getStyle("F{$row}")->getFont()
                                ->setBold(true)
                                ->getColor()->setRGB($colorMap[$statusValue]);
                        }
                    }
                }

                // ---------------------------------
                // 5. Freeze panes: header tetap terlihat saat scroll
                // ---------------------------------
                $sheet->freezePane("A" . ($this->headerRow + 1));

                // ---------------------------------
                // 6. Auto filter di header
                // ---------------------------------
                if ($totalDataRows > 0) {
                    $sheet->setAutoFilter("A{$this->headerRow}:{$lastCol}{$lastDataRow}");
                }

                // ---------------------------------
                // 7. Ringkasan rekap di bawah tabel
                // ---------------------------------
                $summaryStartRow = $lastDataRow + 2;

                $counts = [
                    'Hadir'     => 0,
                    'Terlambat' => 0,
                    'Izin'      => 0,
                    'Sakit'     => 0,
                    'Alpha'     => 0,
                ];
                foreach ($this->collection() as $absensi) {
                    $status = ucfirst(strtolower($absensi->status));
                    if (isset($counts[$status])) {
                        $counts[$status]++;
                    }
                }

                $sheet->setCellValue("A{$summaryStartRow}", 'Ringkasan');
                $sheet->getStyle("A{$summaryStartRow}")->getFont()->setBold(true);

                $row = $summaryStartRow + 1;
                foreach ($counts as $label => $jumlah) {
                    $sheet->setCellValue("A{$row}", $label);
                    $sheet->setCellValue("B{$row}", $jumlah);
                    $sheet->getStyle("A{$row}")->getFont()->setBold(false);
                    $row++;
                }
                $sheet->setCellValue("A{$row}", 'Total');
                $sheet->setCellValue("B{$row}", array_sum($counts));
                $sheet->getStyle("A{$row}:B{$row}")->getFont()->setBold(true);
                $sheet->getStyle("A{$summaryStartRow}:B{$row}")->getBorders()
                    ->getAllBorders()->setBorderStyle(Border::BORDER_THIN)
                    ->getColor()->setRGB('B7B7B7');

                // ---------------------------------
                // 8. Footer: info cetak & tanda tangan
                // ---------------------------------
                $footerRow = $row + 3;
                $sheet->setCellValue("A{$footerRow}", 'Dicetak pada: ' . Carbon::now()->translatedFormat('d F Y, H:i'));
                $sheet->getStyle("A{$footerRow}")->getFont()->setItalic(true)->setSize(9);

                $ttdRow = $footerRow + 2;
                $sheet->setCellValue("E{$ttdRow}", 'Wali Kelas ' . $this->namaKelas);
                $sheet->getStyle("E{$ttdRow}")->getAlignment()->setHorizontal(Alignment::HORIZONTAL_CENTER);

                $ttdSignRow = $ttdRow + 4;
                $sheet->setCellValue("E{$ttdSignRow}", '(________________________)');
                $sheet->getStyle("E{$ttdSignRow}")->getAlignment()->setHorizontal(Alignment::HORIZONTAL_CENTER);
            },
        ];
    }
}

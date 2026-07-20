<?php

namespace App\Exports;

use Maatwebsite\Excel\Concerns\FromArray;
use Maatwebsite\Excel\Concerns\WithHeadings;

class GuruTemplateExport implements FromArray, WithHeadings
{
    public function array(): array
    {
        return [
            ['Contoh Nama Guru', '198501012010011001', 'guru@email.com', '081234567890', 'password123'],
        ];
    }

    public function headings(): array
    {
        return ['name', 'nip', 'email', 'phone', 'password'];
    }
}

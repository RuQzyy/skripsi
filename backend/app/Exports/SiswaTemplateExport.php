<?php

namespace App\Exports;

use Maatwebsite\Excel\Concerns\FromArray;

class SiswaTemplateExport implements FromArray
{
    public function array(): array
    {
        return [

            // HEADER
            [
                'name',
                'nisn',
                'kelas_id',
                'email',
                'phone',
                'password',
            ],

            // CONTOH DATA
            [
                'Ahmad Fauzan',
                '2201001',
                '1',
                'ahmad@gmail.com',
                '08123456789',
                '12345678',
            ],

            [
                'Budi Santoso',
                '2201002',
                '1',
                'budi@gmail.com',
                '08129876543',
                '12345678',
            ],

        ];
    }
}

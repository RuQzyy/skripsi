<?php

namespace App\Imports;

use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Maatwebsite\Excel\Concerns\ToModel;
use Maatwebsite\Excel\Concerns\WithHeadingRow;

class SiswaImport implements ToModel, WithHeadingRow
{
    public function model(array $row)
    {
        return new User([
            'name'      => $row['name'],
            'nisn'      => $row['nisn'],
            'kelas_id'  => $row['kelas_id'],
            'email'     => $row['email'],
            'phone'     => $row['phone'],
            'password'  => Hash::make($row['password']),
            'role'      => 'siswa',
            'photo'     => 'default.png',
        ]);
    }
}

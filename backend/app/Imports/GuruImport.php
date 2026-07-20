<?php

namespace App\Imports;

use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Maatwebsite\Excel\Concerns\ToModel;
use Maatwebsite\Excel\Concerns\WithHeadingRow;
use Maatwebsite\Excel\Concerns\WithValidation;
use Maatwebsite\Excel\Concerns\SkipsOnFailure;
use Maatwebsite\Excel\Concerns\SkipsFailures;

class GuruImport implements ToModel, WithHeadingRow, WithValidation, SkipsOnFailure
{
    use SkipsFailures;

    public function model(array $row)
    {
        return new User([
            'name'     => $row['name'],
            'nip'      => $row['nip'],
            'email'    => $row['email'],
            'phone'    => $row['phone'],
            'password' => Hash::make($row['password']),
            'role'     => 'guru',
            'photo'    => 'default.png',
        ]);
    }

    public function rules(): array
    {
        return [
            'name'     => 'required|string|max:255',
            'nip'      => 'required|string|unique:users,nip',
            'email'    => 'required|email|unique:users,email',
            'phone'    => 'required|string',
            'password' => 'required|string|min:6',
        ];
    }
}

<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

class UserSeeder extends Seeder
{
    public function run(): void
    {
        DB::table('users')->insert([

            // GURU
            [
                'name' => 'Budi Santoso',
                'photo' => 'default.png',
                'nip' => '1987654321',
                'kelas' => 'xi ipa 3',
                'nisn' => null,
                'email' => 'guru@gmail.com',
                'phone' => '081234567890',
                'password' => Hash::make('password123'),
                'google_id' => null,
                'face_id' => null,
                'role' => 'guru',
                'created_at' => now(),
                'updated_at' => now(),
            ],

            // SISWA
            [
                'name' => 'Muhammad Al-Faruq',
                'photo' => 'default.png',
                'nip' => null,
                'nisn' => '220102044',
                'kelas' => 'xi ipa 3',
                'email' => 'siswa@gmail.com',
                'phone' => '081298765432',
                'password' => Hash::make('password123'),
                'google_id' => null,
                'face_id' => null,
                'role' => 'siswa',
                'created_at' => now(),
                'updated_at' => now(),
            ],

        ]);
    }
}

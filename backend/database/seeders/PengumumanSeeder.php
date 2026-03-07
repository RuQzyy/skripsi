<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Pengumuman;

class PengumumanSeeder extends Seeder
{
    public function run(): void
    {
        Pengumuman::create([
            'judul' => 'Hari Sumpah Pemuda',
            'tanggal' => '2024-10-28',
            'deskripsi' => 'Peringatan Hari Sumpah Pemuda akan dilaksanakan pada tanggal 28 Oktober di aula sekolah.',
            'foto' => 'pengumuman.jpg'
        ]);

        Pengumuman::create([
            'judul' => 'Libur Nasional',
            'tanggal' => '2024-08-17',
            'deskripsi' => 'Sekolah diliburkan pada tanggal 17 Agustus dalam rangka memperingati Hari Kemerdekaan Indonesia.',
            'foto' => 'pengumuman.jpg'
        ]);

        Pengumuman::create([
            'judul' => 'Kegiatan Pramuka',
            'tanggal' => '2024-09-01',
            'deskripsi' => 'Kegiatan pramuka akan dilaksanakan setiap hari Jumat sore.',
            'foto' => 'pengumuman.jpg'
        ]);
    }
}

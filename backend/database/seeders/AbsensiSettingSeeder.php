<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\AbsensiSetting;

class AbsensiSettingSeeder extends Seeder
{
    public function run(): void
    {
        AbsensiSetting::create([
            'jam_absen_mulai'   => '06:30:00',
            'jam_terlambat'     => '07:00:00',
            'jam_absen_selesai' => '08:00:00',

            'nama_lokasi' => 'SMA 15 Ambon',

            'latitude'  => -3.6951234,
            'longitude' => 128.1812345,

            'radius' => 100,

            'is_active' => true,
        ]);
    }
}

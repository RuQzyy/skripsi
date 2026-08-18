<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class AbsensiSetting extends Model
{
    protected $fillable = [
        'jam_absen_mulai',
        'jam_terlambat',
        'jam_absen_selesai',

        // Tambahan
        'jam_pulang_mulai',
        'jam_pulang_selesai',

        'nama_lokasi',
        'latitude',
        'longitude',
        'radius',
        'is_active',

        'wifi_bssid',
        'wifi_required',
    ];

    protected $casts = [
        'wifi_required' => 'boolean',
        'is_active' => 'boolean',
    ];
}

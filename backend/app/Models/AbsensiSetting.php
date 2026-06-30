<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class AbsensiSetting extends Model
{
    protected $fillable = [
        'jam_absen_mulai',
        'jam_terlambat',
        'jam_absen_selesai',
        'nama_lokasi',
        'latitude',
        'longitude',
        'radius',
        'is_active',
    ];
}

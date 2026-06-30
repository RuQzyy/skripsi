<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AbsensiSetting;

class AbsensiSettingController extends Controller
{
    public function index()
    {
        $setting = AbsensiSetting::first();

        if (!$setting) {
            return response()->json([
                'success' => false,
                'message' => 'Pengaturan absensi belum tersedia'
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data' => [
                'jam_absen_mulai' => $setting->jam_absen_mulai,
                'jam_terlambat' => $setting->jam_terlambat,
                'jam_absen_selesai' => $setting->jam_absen_selesai,

                'nama_lokasi' => $setting->nama_lokasi,
                'latitude' => $setting->latitude,
                'longitude' => $setting->longitude,
                'radius' => $setting->radius,

                'is_active' => $setting->is_active,
            ]
        ]);
    }
}

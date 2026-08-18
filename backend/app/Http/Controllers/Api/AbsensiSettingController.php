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
                // Jam Absen Masuk
                'jam_absen_mulai'   => $setting->jam_absen_mulai,
                'jam_terlambat'     => $setting->jam_terlambat,
                'jam_absen_selesai' => $setting->jam_absen_selesai,

                // Jam Absen Pulang
                'jam_pulang_mulai'   => $setting->jam_pulang_mulai,
                'jam_pulang_selesai' => $setting->jam_pulang_selesai,

                // Lokasi
                'nama_lokasi' => $setting->nama_lokasi,
                'latitude'    => (float) $setting->latitude,
                'longitude'   => (float) $setting->longitude,
                'radius'      => (float) $setting->radius,

                // Status
                'is_active' => (bool) $setting->is_active,

                // WiFi
                'wifi_required' => (bool) $setting->wifi_required,
                'wifi_bssid'    => $setting->wifi_bssid,
            ]
        ]);
    }
}

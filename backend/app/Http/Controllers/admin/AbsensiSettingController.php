<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\AbsensiSetting;
use Illuminate\Http\Request;

class AbsensiSettingController extends Controller
{
    public function index()
    {
        $setting = AbsensiSetting::first();

        if (!$setting) {
            $setting = AbsensiSetting::create([
                'jam_absen_mulai'    => '07:00:00',
                'jam_terlambat'      => '07:30:00',
                'jam_absen_selesai'  => '08:00:00',

                'jam_pulang_mulai'   => '13:00:00',
                'jam_pulang_selesai' => '14:00:00',

                'nama_lokasi' => '',
                'latitude'    => -3.6951234,
                'longitude'   => 128.1812345,
                'radius'      => 100,

                'is_active' => true,

                'wifi_required' => false,
                'wifi_bssid'    => null,
            ]);
        }

        return view('admin.absensi-setting', compact('setting'));
    }

    public function update(Request $request)
    {
        $request->validate([
            'jam_absen_mulai'   => 'required',
            'jam_terlambat'     => 'required',
            'jam_absen_selesai' => 'required',

            'jam_pulang_mulai'   => 'required',
            'jam_pulang_selesai' => 'required',

            'nama_lokasi' => 'required|string|max:255',
            'latitude'    => 'required|numeric',
            'longitude'   => 'required|numeric',
            'radius'      => 'required|numeric|min:1',

            'is_active' => 'required|boolean',

            'wifi_required' => 'required|boolean',
            'wifi_bssid'    => 'nullable|string|max:255',
        ]);

        $setting = AbsensiSetting::first();

        if (!$setting) {
            $setting = new AbsensiSetting();
        }

        $setting->jam_absen_mulai   = $request->jam_absen_mulai;
        $setting->jam_terlambat     = $request->jam_terlambat;
        $setting->jam_absen_selesai = $request->jam_absen_selesai;

        $setting->jam_pulang_mulai   = $request->jam_pulang_mulai;
        $setting->jam_pulang_selesai = $request->jam_pulang_selesai;

        $setting->nama_lokasi = $request->nama_lokasi;
        $setting->latitude    = $request->latitude;
        $setting->longitude   = $request->longitude;
        $setting->radius      = $request->radius;

        $setting->is_active = $request->boolean('is_active');

        $setting->wifi_required = $request->boolean('wifi_required');
        $setting->wifi_bssid = $request->filled('wifi_bssid')
            ? strtolower(trim($request->wifi_bssid))
            : null;

        $setting->save();

        return back()->with('success', 'Pengaturan absensi berhasil diperbarui.');
    }
}

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

        return view('admin.absensi-setting', compact('setting'));
    }

    public function update(Request $request)
    {
        $request->validate([
            'jam_absen_mulai' => 'required',
            'jam_terlambat' => 'required',
            'jam_absen_selesai' => 'required',

            'nama_lokasi' => 'required',
            'latitude' => 'required',
            'longitude' => 'required',

            'radius' => 'required|numeric|min:1',
            'is_active' => 'required'
        ]);

        $setting = AbsensiSetting::first();

        $setting->update([
            'jam_absen_mulai' => $request->jam_absen_mulai,
            'jam_terlambat' => $request->jam_terlambat,
            'jam_absen_selesai' => $request->jam_absen_selesai,

            'nama_lokasi' => $request->nama_lokasi,
            'latitude' => $request->latitude,
            'longitude' => $request->longitude,

            'radius' => $request->radius,
            'is_active' => $request->is_active,
        ]);

        return back()->with(
            'success',
            'Pengaturan absensi berhasil diperbarui'
        );
    }
}

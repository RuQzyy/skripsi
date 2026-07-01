<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Absensi;
use App\Models\AbsensiSetting;
use App\Models\User;

class AttendanceController extends Controller
{
    public function store(Request $request)
    {
        $request->validate([
            'photo' => 'required|image'
        ]);

        $user = $request->user();

        // ==========================
        // Face ID harus sudah ada
        // ==========================

        if (empty($user->face_id)) {
            return response()->json([
                'success' => false,
                'message' => 'Face ID belum terdaftar.'
            ], 400);
        }

        // ==========================
        // Sudah absen hari ini?
        // ==========================

        $today = now()->toDateString();

        $check = Absensi::where('user_id', $user->id)
            ->whereDate('tanggal', $today)
            ->first();

        if ($check) {
            return response()->json([
                'success' => false,
                'message' => 'Anda sudah melakukan absensi hari ini.'
            ], 400);
        }

        // ==========================
        // Cek jam absensi
        // ==========================

        $setting = AbsensiSetting::first();

        if (!$setting) {
            return response()->json([
                'success' => false,
                'message' => 'Pengaturan absensi belum dibuat.'
            ], 500);
        }

       $now = now()->format('H:i:s');

        if ($now < $setting->jam_absen_mulai) {
            return response()->json([
                'success' => false,
                'message' => 'Absensi belum dibuka.'
            ], 400);
        }

        if ($now > $setting->jam_absen_selesai) {
            return response()->json([
                'success' => false,
                'message' => 'Jam absensi sudah berakhir.'
            ], 400);
        }

        // ==========================
        // Verifikasi wajah
        // ==========================

        $faceController = new FaceController();

        $verifyRequest = Request::create(
            '/verify-face',
            'POST',
            [
                'user_id' => $user->id
            ],
            [],
            [
                'photo' => $request->file('photo')
            ]
        );

        $verifyResponse = $faceController->verify($verifyRequest);

        $verify = json_decode(
            $verifyResponse->getContent(),
            true
        );

        if (!$verify['success']) {
            return response()->json($verify);
        }

        if (!$verify['result']['success']) {
            return response()->json([
                'success' => false,
                'message' => $verify['result']['message']
            ], 400);
        }

        if (!$verify['result']['match']) {
            return response()->json([
                'success' => false,
                'message' => 'Wajah tidak cocok.'
            ], 400);
        }

        // ==========================
        // Simpan absensi
        // ==========================

       $status = "Hadir";

        if ($now > $setting->jam_terlambat) {
            $status = "Terlambat";
        }

        $absensi = Absensi::create([
            'user_id' => $user->id,
            'tanggal' => $today,
            'jam_masuk' => now()->format('H:i:s'),
            'status' => $status,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Absensi berhasil.',
            'similarity' => $verify['result']['similarity'],
            'status' => $status,
            'data' => $absensi
        ]);
    }

    public function today(Request $request)
    {
        $user = $request->user();

        $today = now()->toDateString();

        $absensi = Absensi::where('user_id', $user->id)
            ->whereDate('tanggal', $today)
            ->first();

        return response()->json([
            'success' => true,
            'data' => $absensi,
        ]);
    }

    public function riwayat(Request $request)
    {
        $user = $request->user();

        $riwayat = Absensi::where('user_id', $user->id)
            ->orderByDesc('tanggal')
            ->limit(30)
            ->get();

        return response()->json([
            'success' => true,
            'data' => $riwayat,
        ]);
    }
}

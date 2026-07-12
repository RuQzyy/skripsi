<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\Api\PengumumanController;
use Illuminate\Http\Request;
use App\Http\Controllers\Api\AbsensiSettingController;
use App\Http\Controllers\Api\FaceController;
use App\Http\Controllers\Api\AttendanceController;
use App\Http\Controllers\Api\PasswordResetController;
use App\Http\Controllers\Api\GuruController;

Route::post('/login', [AuthController::class, 'login']);


//  PROTECTED ROUTES Butuh Token

Route::middleware('auth:sanctum')->group(function () {

    Route::post('/logout', [AuthController::class, 'logout']);

    Route::get('/profile', function (Request $request) {

        return response()->json([
            'success' => true,
            'user' => $request->user()
        ]);

    });

    // TAMBAHKAN INI
    Route::get('/me', function (Request $request) {

        return response()->json(
            $request->user()->load('kelas')
        );

    });

    Route::middleware('auth:sanctum')->post(
        '/attendance',
        [AttendanceController::class, 'store']
    );

     Route::get('/attendance/today', [AttendanceController::class, 'today']);

     Route::get('/attendance/riwayat', [AttendanceController::class, 'riwayat']);

     Route::post('/update-photo', [AuthController::class, 'updatePhoto']);

       // Route khusus guru
    Route::get('/guru/kelas',                    [GuruController::class, 'kelasSaya']);
    Route::get('/guru/kehadiran-hari-ini',       [GuruController::class, 'kehadiranHariIni']);
    Route::get('/guru/riwayat-siswa/{siswaId}',  [GuruController::class, 'riwayatSiswa']);
    Route::get('/guru/kehadiran-per-tanggal', [GuruController::class, 'kehadiranPerTanggal']);
    Route::get('/guru/laporan-absensi', [GuruController::class, 'laporanAbsensi']);

});

Route::middleware('auth:sanctum')->post(
    '/connect-google',
    [AuthController::class, 'connectGoogle']
);

// pengumuman

Route::get('/pengumuman', [PengumumanController::class, 'index']);
Route::get('/pengumuman/{id}', [PengumumanController::class, 'show']);

Route::post('/pengumuman', [PengumumanController::class, 'store']);
Route::put('/pengumuman/{id}', [PengumumanController::class, 'update']);
Route::delete('/pengumuman/{id}', [PengumumanController::class, 'destroy']);

Route::middleware('auth:sanctum')->post('/update-password', [AuthController::class, 'updatePassword']);

Route::get(
    '/absensi-setting',
    [AbsensiSettingController::class, 'index']
);

// Route::middleware('auth:sanctum')->post(
//     '/register-face',
//     [FaceController::class, 'register']
// );

Route::middleware('auth:sanctum')->post(
    '/register-face',
    [FaceController::class, 'register']
);

Route::post('/verify-face', [FaceController::class, 'verify']);
Route::post('/forgot-password/send-otp',    [PasswordResetController::class, 'sendOtp']);
Route::post('/forgot-password/verify-otp',  [PasswordResetController::class, 'verifyOtp']);
Route::post('/forgot-password/reset',       [PasswordResetController::class, 'resetPassword']);

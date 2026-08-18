<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

use App\Http\Controllers\AuthController;
use App\Http\Controllers\Api\AttendanceController;
use App\Http\Controllers\Api\AbsensiSettingController;
use App\Http\Controllers\Api\FaceController;
use App\Http\Controllers\Api\GuruController;
use App\Http\Controllers\Api\PasswordResetController;
use App\Http\Controllers\Api\PengumumanController;

/*
|--------------------------------------------------------------------------
| Public Routes
|--------------------------------------------------------------------------
*/

// Login
Route::post('/login', [AuthController::class, 'login']);

// Pengaturan absensi
Route::get('/absensi-setting', [AbsensiSettingController::class, 'index']);

// Pengumuman
Route::get('/pengumuman', [PengumumanController::class, 'index']);
Route::get('/pengumuman/{id}', [PengumumanController::class, 'show']);

// Face Verification
Route::post('/verify-face', [FaceController::class, 'verify']);

// Reset Password
Route::post('/forgot-password/send-otp', [PasswordResetController::class, 'sendOtp']);
Route::post('/forgot-password/verify-otp', [PasswordResetController::class, 'verifyOtp']);
Route::post('/forgot-password/reset', [PasswordResetController::class, 'resetPassword']);


/*
|--------------------------------------------------------------------------
| Protected Routes
|--------------------------------------------------------------------------
*/

Route::middleware('auth:sanctum')->group(function () {

    /*
    |--------------------------------------------------------------------------
    | Authentication
    |--------------------------------------------------------------------------
    */

    Route::post('/logout', [AuthController::class, 'logout']);

    Route::post('/connect-google', [AuthController::class, 'connectGoogle']);

    Route::post('/update-photo', [AuthController::class, 'updatePhoto']);

    Route::post('/update-password', [AuthController::class, 'updatePassword']);

    /*
    |--------------------------------------------------------------------------
    | Profile
    |--------------------------------------------------------------------------
    */

    Route::get('/profile', function (Request $request) {
        return response()->json([
            'success' => true,
            'user' => $request->user(),
        ]);
    });

    Route::get('/me', function (Request $request) {
        return response()->json(
            $request->user()->load('kelas')
        );
    });

    /*
    |--------------------------------------------------------------------------
    | Face ID
    |--------------------------------------------------------------------------
    */

    Route::post('/register-face', [FaceController::class, 'register']);

    /*
    |--------------------------------------------------------------------------
    | Attendance
    |--------------------------------------------------------------------------
    */

    // Absen Masuk
    Route::post('/attendance', [AttendanceController::class, 'store']);

    // Absen Pulang
    Route::post('/attendance/pulang', [AttendanceController::class, 'pulang']);

    // Sinkronisasi Absensi Offline
    Route::post('/attendance/sync', [AttendanceController::class, 'sync']);

    // Absensi Hari Ini
    Route::get('/attendance/today', [AttendanceController::class, 'today']);

    // Riwayat Absensi
    Route::get('/attendance/riwayat', [AttendanceController::class, 'riwayat']);

    /*
    |--------------------------------------------------------------------------
    | Guru
    |--------------------------------------------------------------------------
    */

    Route::get('/guru/kelas', [GuruController::class, 'kelasSaya']);

    Route::get('/guru/kehadiran-hari-ini', [GuruController::class, 'kehadiranHariIni']);

    Route::get('/guru/riwayat-siswa/{siswaId}', [GuruController::class, 'riwayatSiswa']);

    Route::get('/guru/kehadiran-per-tanggal', [GuruController::class, 'kehadiranPerTanggal']);

    Route::get('/guru/laporan-absensi', [GuruController::class, 'laporanAbsensi']);

    Route::put('/guru/absensi/{id}/status', [GuruController::class, 'updateStatusAbsensi']);
});


Route::middleware(['auth:sanctum', 'admin'])->group(function () {
    Route::post('/pengumuman', [PengumumanController::class, 'store']);
    Route::put('/pengumuman/{id}', [PengumumanController::class, 'update']);
    Route::delete('/pengumuman/{id}', [PengumumanController::class, 'destroy']);
});

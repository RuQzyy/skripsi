<?php

use App\Http\Controllers\ProfileController;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Admin\DashboardController;
use App\Http\Controllers\Admin\PengumumanController;
use App\Http\Controllers\Admin\SiswaController;
use App\Http\Controllers\Admin\GuruController;
use App\Http\Controllers\Admin\KelasController;
use App\Http\Controllers\Admin\AbsensiSettingController;

Route::get('/', function () {
    return redirect()->route('login');
});

Route::get('/dashboard', function () {
    return view('dashboard');
})->middleware(['auth', 'verified'])->name('dashboard');

Route::middleware('auth')->group(function () {
    Route::get('/profile', [ProfileController::class, 'edit'])->name('profile.edit');
    Route::patch('/profile', [ProfileController::class, 'update'])->name('profile.update');
    Route::delete('/profile', [ProfileController::class, 'destroy'])->name('profile.destroy');
});

Route::middleware(['auth', 'admin'])
    ->prefix('admin')
    ->name('admin.')
    ->group(function () {

        Route::get('/dashboard', [DashboardController::class, 'index'])
            ->name('dashboard');

        // ================= PENGUMUMAN =================
        Route::resource('pengumuman', PengumumanController::class);

        // ================= SISWA =================
        Route::resource('siswa', SiswaController::class);

        // ================= GURU =================
        Route::resource('guru', GuruController::class);

        // ================= KELAS =================
        Route::resource('kelas', KelasController::class)
        ->names('kelas');

        Route::post('/siswa/import', [SiswaController::class, 'import'])
        ->name('siswa.import');

        Route::get('/siswa/template/download',
            [SiswaController::class, 'downloadTemplate'])
            ->name('siswa.template');

            Route::get(
            '/pengaturan-absensi',
            [AbsensiSettingController::class, 'index']
        )->name('absensi.setting');

        Route::put(
            '/pengaturan-absensi',
            [AbsensiSettingController::class, 'update']
        )->name('absensi.setting.update');

       Route::post(
            '/siswa/{id}/reset-face',
            [SiswaController::class, 'resetFaceId']
        )->name('siswa.resetFace');

    });

require __DIR__.'/auth.php';

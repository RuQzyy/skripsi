<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\Api\PengumumanController;
use Illuminate\Http\Request;

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

});

// pengumuman

Route::get('/pengumuman', [PengumumanController::class, 'index']);
Route::get('/pengumuman/{id}', [PengumumanController::class, 'show']);

Route::post('/pengumuman', [PengumumanController::class, 'store']);
Route::put('/pengumuman/{id}', [PengumumanController::class, 'update']);
Route::delete('/pengumuman/{id}', [PengumumanController::class, 'destroy']);

Route::middleware('auth:sanctum')->post('/update-password', [AuthController::class, 'updatePassword']);

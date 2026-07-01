<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\PasswordResetOtp;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Hash;

class PasswordResetController extends Controller
{
    // ==========================
    // 1. Kirim OTP ke Email
    // ==========================
    public function sendOtp(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
        ]);

        $user = User::where('email', $request->email)->first();

        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'Email tidak ditemukan.',
            ], 404);
        }

        // Hapus OTP lama
        PasswordResetOtp::where('email', $request->email)->delete();

        // Buat OTP baru 6 digit
        $otp = str_pad(random_int(0, 999999), 6, '0', STR_PAD_LEFT);

        PasswordResetOtp::create([
            'email' => $request->email,
            'otp' => $otp,
            'expires_at' => now()->addMinutes(10),
        ]);

        // Kirim email
        Mail::raw(
            "Kode OTP reset password kamu adalah: $otp\n\nKode ini berlaku selama 10 menit.",
            function ($message) use ($request, $otp) {
                $message->to($request->email)
                        ->subject('Kode OTP Reset Password');
            }
        );

        return response()->json([
            'success' => true,
            'message' => 'OTP telah dikirim ke email kamu.',
        ]);
    }

    // ==========================
    // 2. Verifikasi OTP
    // ==========================
    public function verifyOtp(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'otp'   => 'required|string|size:6',
        ]);

        $record = PasswordResetOtp::where('email', $request->email)
            ->where('otp', $request->otp)
            ->first();

        if (!$record) {
            return response()->json([
                'success' => false,
                'message' => 'OTP salah.',
            ], 400);
        }

        if (now()->gt($record->expires_at)) {
            $record->delete();
            return response()->json([
                'success' => false,
                'message' => 'OTP sudah kadaluarsa.',
            ], 400);
        }

        return response()->json([
            'success' => true,
            'message' => 'OTP valid.',
        ]);
    }

    // ==========================
    // 3. Reset Password
    // ==========================
    public function resetPassword(Request $request)
    {
        $request->validate([
            'email'    => 'required|email',
            'otp'      => 'required|string|size:6',
            'password' => 'required|min:6',
        ]);

        $record = PasswordResetOtp::where('email', $request->email)
            ->where('otp', $request->otp)
            ->first();

        if (!$record || now()->gt($record->expires_at)) {
            return response()->json([
                'success' => false,
                'message' => 'OTP tidak valid atau sudah kadaluarsa.',
            ], 400);
        }

        $user = User::where('email', $request->email)->first();

        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'User tidak ditemukan.',
            ], 404);
        }

        $user->update([
            'password' => Hash::make($request->password),
        ]);

        // Hapus OTP setelah berhasil
        $record->delete();

        return response()->json([
            'success' => true,
            'message' => 'Password berhasil direset.',
        ]);
    }
}

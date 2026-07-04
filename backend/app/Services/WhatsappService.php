<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class WhatsappService
{
    public static function send(string $phone, string $message): bool
    {
        $phone = self::formatPhone($phone);

        if (!$phone) {
            Log::warning("Nomor WA tidak valid, notifikasi dibatalkan: {$phone}");
            return false;
        }

        try {
            $response = Http::withHeaders([
                'Authorization' => config('services.fonnte.token'),
            ])->post('https://api.fonnte.com/send', [
                'target'  => $phone,
                'message' => $message,
            ]);

            if ($response->successful() && ($response->json('status') ?? false)) {
                Log::info("WA terkirim ke {$phone}");
                return true;
            }

            Log::warning("WA gagal terkirim ke {$phone}: " . $response->body());
            return false;

        } catch (\Exception $e) {
            Log::error("Error kirim WA ke {$phone}: " . $e->getMessage());
            return false;
        }
    }

    /**
     * Format nomor ke standar internasional (62xxx) yang dibutuhkan Fonnte.
     */
    private static function formatPhone(?string $phone): ?string
    {
        if (empty($phone)) {
            return null;
        }

        $phone = preg_replace('/[^0-9]/', '', $phone); // hapus karakter non-angka

        if (str_starts_with($phone, '0')) {
            $phone = '62' . substr($phone, 1);
        } elseif (str_starts_with($phone, '+62')) {
            $phone = substr($phone, 1);
        } elseif (!str_starts_with($phone, '62')) {
            $phone = '62' . $phone;
        }

        return $phone;
    }
}

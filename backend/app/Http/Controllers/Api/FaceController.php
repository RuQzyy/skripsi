<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\User;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class FaceController extends Controller
{
    const FACE_SERVICE_URL = 'http://127.0.0.1:5001';
    const MIN_SAMPLES = 3; // jumlah foto minimal saat registrasi

    public function register(Request $request)
    {
        $request->validate([
            'photo' => 'required|image'
        ]);

        $file = $request->file('photo');
        $path = $file->store('faceid', 'public');
        $fullPath = storage_path('app/public/' . $path);

        $response = Http::timeout(45)->post(self::FACE_SERVICE_URL . '/represent', [
            'image_path' => $fullPath
        ]);

        unlink($fullPath); // foto tidak perlu disimpan permanen

        $result = $response->json();

        if (!$result['success']) {
            Log::warning('Face embedding failed', [
                'detail' => $result['message'] ?? null
            ]);

            return response()->json([
                'success' => false,
                'message' => 'Wajah tidak terdeteksi pada foto ini. Pastikan pencahayaan cukup terang dan wajah menghadap kamera dengan jelas, lalu coba ambil foto ulang.'
            ], 400);
        }

        $user = $request->user();

        // Ambil embedding lama (kalau ada), tambahkan yang baru
        $existing = $user->face_id ? json_decode($user->face_id, true) : [];

        // Kalau format lama cuma 1 embedding flat, bungkus jadi array of array
        if (!empty($existing) && !is_array($existing[0])) {
            $existing = [$existing];
        }

        $existing[] = $result['embedding'];

        // Batasi maksimal, misal simpan 5 sample terbaru
        if (count($existing) > 5) {
            $existing = array_slice($existing, -5);
        }

        $user->face_id = json_encode($existing);
        $user->save();

        return response()->json([
            'success' => true,
            'sample_count' => count($existing),
            'saved_to_user' => $user->id,
            'message' => count($existing) < self::MIN_SAMPLES
                ? 'Foto tersimpan. Silakan ambil ' . (self::MIN_SAMPLES - count($existing)) . ' foto lagi untuk hasil terbaik.'
                : 'Registrasi wajah selesai.'
        ]);
    }

    public function verify(Request $request)
    {
        $request->validate([
            'photo' => 'required|image',
            'user_id' => 'required|exists:users,id'
        ]);

        $user = User::findOrFail($request->user_id);

        if (empty($user->face_id)) {
            return response()->json([
                'success' => false,
                'message' => 'User belum memiliki data wajah.'
            ], 400);
        }

        $storedEmbeddings = json_decode($user->face_id, true);

        // Dukung format lama (1 embedding flat) maupun baru (array of embeddings)
        if (!is_array($storedEmbeddings[0])) {
            $storedEmbeddings = [$storedEmbeddings];
        }

        $file = $request->file('photo');
        $path = $file->store('faceid', 'public');
        $fullPath = storage_path('app/public/' . $path);

        $response = Http::timeout(60)->post(self::FACE_SERVICE_URL . '/verify', [
            'image_path' => $fullPath,
            'stored_embeddings' => $storedEmbeddings,
            'threshold' => 0.78
        ]);

        unlink($fullPath);

        $result = $response->json();

        if (!$result['success']) {
            return response()->json([
                'success' => false,
                'message' => 'Wajah tidak terdeteksi. Pastikan pencahayaan cukup dan wajah menghadap kamera.'
            ], 400);
        }

        // ==========================
        // Deteksi spoofing (foto-dari-foto / replay attack)
        // ==========================
        // face_service.py mengembalikan flag spoof_detected == true kalau
        // MiniFASNet menilai wajah pada foto BUKAN wajah asli langsung dari
        // kamera (misal foto hasil jepretan dari HP lain, print-out, atau
        // ditampilkan lewat layar). Kasus ini WAJIB ditolak di sini,
        // terpisah dari kasus "wajah tidak cocok", supaya:
        // - pesan ke user jelas & tidak membingungkan (bukan salah orang,
        //   tapi terdeteksi bukan wajah asli)
        // - log/riwayat bisa membedakan percobaan spoofing dari sekadar
        //   wajah tidak dikenali
        if (($result['spoof_detected'] ?? false) === true) {
            Log::warning('Face spoof detected', [
                'user_id' => $user->id,
                'antispoof_score' => $result['antispoof_score'] ?? null,
            ]);

            return response()->json([
                'success' => true,
                'result' => [
                    'success' => true,
                    'match' => false,
                    'spoof_detected' => true,
                    'antispoof_score' => $result['antispoof_score'] ?? null,
                    'message' => 'Terdeteksi kemungkinan foto tidak asli. Pastikan Anda mengambil foto langsung dari kamera, bukan memotret foto/layar lain.',
                ]
            ]);
        }

        return response()->json([
            'success' => true,
            'result' => $result
        ]);
    }
}

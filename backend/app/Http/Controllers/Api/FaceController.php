<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\User;

class FaceController extends Controller
{
    public function register(Request $request)
    {
        $request->validate([
            'photo' => 'required|image'
        ]);

        $file = $request->file('photo');

        $path = $file->store('faceid', 'public');

        $fullPath = storage_path('app/public/' . $path);

        $pythonScript = base_path('python/register_face.py');

        $command = 'python "' . $pythonScript . '" "' . $fullPath . '" 2>&1';

        $result = shell_exec($command);

        // Cari awal JSON array
        $start = strpos($result, '[');

        if ($start !== false) {
            $json = substr($result, $start);
            $embedding = json_decode($json, true);
        } else {
            $embedding = null;
        }

        // Gagal membaca embedding
        if (!$embedding) {
            return response()->json([
                'success' => false,
                'message' => 'Embedding gagal dibuat',
                'python_output' => $result
            ], 500);
        }

       // Ambil user yang sedang login
        $user = $request->user();

        $user->face_id = json_encode($embedding);

        $user->save();

        return response()->json([
            'success' => true,
            'embedding_count' => count($embedding),
            'saved_to_user' => $user->id
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

    // Simpan foto sementara
    $file = $request->file('photo');
    $path = $file->store('faceid', 'public');
    $fullPath = storage_path('app/public/' . $path);

    // Simpan embedding ke file JSON sementara
    $tempEmbedding = storage_path('app/temp_embedding.json');

    file_put_contents(
        $tempEmbedding,
        $user->face_id
    );

    $pythonScript = base_path('python/verify_face.py');

    $command =
        'python "' .
        $pythonScript .
        '" "' .
        $fullPath .
        '" "' .
        $tempEmbedding .
        '" 2>&1';

    $result = shell_exec($command);

    // Hapus file sementara
    if (file_exists($tempEmbedding)) {
        unlink($tempEmbedding);
    }

    if (file_exists($fullPath)) {
        unlink($fullPath);
    }

    // Ambil semua JSON dari output Python
    preg_match_all('/\{[^}]*\}/', $result, $matches);

    if (empty($matches[0])) {
        return response()->json([
            'success' => false,
            'message' => 'Output Python bukan JSON.',
            'python_output' => $result
        ], 500);
    }

    // Ambil JSON terakhir
    $lastJson = end($matches[0]);

    $response = json_decode($lastJson, true);

    if (json_last_error() !== JSON_ERROR_NONE) {
        return response()->json([
            'success' => false,
            'message' => 'JSON tidak bisa dibaca.',
            'python_output' => $result
        ], 500);
    }

    return response()->json([
        'success' => true,
        'result' => $response
    ]);
}
}

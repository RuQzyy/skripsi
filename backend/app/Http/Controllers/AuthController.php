<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\User;
use Illuminate\Support\Facades\Hash;

class AuthController extends Controller
{

    // login

    public function login(Request $request)
    {

        $request->validate([
            'nisn_nip' => 'required',
            'password' => 'required'
        ]);


        // cari user berdasarkan NISN atau NIP
        $user = User::where('nisn', $request->nisn_nip)
                    ->orWhere('nip', $request->nisn_nip)
                    ->first();


        // jika user tidak ditemukan
        if (!$user) {

            return response()->json([
                'success' => false,
                'message' => 'User tidak ditemukan'
            ], 404);

        }


        // cek password
        if (!Hash::check($request->password, $user->password)) {

            return response()->json([
                'success' => false,
                'message' => 'Password salah'
            ], 401);

        }


        // buat token sanctum
        $token = $user->createToken('auth_token')->plainTextToken;


        return response()->json([

            'success' => true,
            'message' => 'Login berhasil',

            'token' => $token,

            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'nisn' => $user->nisn,
                'kelas' => $user->kelas,
                'nip' => $user->nip,
                'email' => $user->email,
                'photo' => $user->photo,
                'phone' => $user->phone,
                'role' => $user->role,
            ]

        ]);

    }


    // logout

    public function logout(Request $request)
    {

        $request->user()->currentAccessToken()->delete();

        return response()->json([

            'success' => true,
            'message' => 'Logout berhasil'

        ]);

    }

    public function updatePassword(Request $request)
{

    $request->validate([
        'password' => 'required|min:6'
    ]);

    $user = $request->user();

    $user->password = Hash::make($request->password);
    $user->save();

    return response()->json([
        'success' => true,
        'message' => 'Password berhasil diubah'
    ]);

}

}

<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Kelas;
use App\Models\User;
use Illuminate\Http\Request;

class KelasController extends Controller
{
    public function index()
    {
        $kelas = Kelas::with('waliKelas')
            ->latest()
            ->get();

        $guru = User::where('role', 'guru')
            ->orderBy('name')
            ->get();

        return view('admin.kelas', compact(
            'kelas',
            'guru'
        ));
    }

    public function store(Request $request)
    {
        $request->validate([
            'nama_kelas' => 'required',
            'wali_kelas_id' => 'nullable|exists:users,id',
        ]);

        Kelas::create([
            'nama_kelas' => $request->nama_kelas,
            'wali_kelas_id' => $request->wali_kelas_id,
        ]);

        return back()->with(
            'success',
            'Kelas berhasil ditambahkan'
        );
    }

    public function update(Request $request, $id)
    {
        $kelas = Kelas::findOrFail($id);

        $request->validate([
            'nama_kelas' => 'required',
            'wali_kelas_id' => 'nullable|exists:users,id',
        ]);

        $kelas->update([
            'nama_kelas' => $request->nama_kelas,
            'wali_kelas_id' => $request->wali_kelas_id,
        ]);

        return back()->with(
            'success',
            'Kelas berhasil diupdate'
        );
    }

    public function destroy($id)
    {
        $kelas = Kelas::findOrFail($id);

        $kelas->delete();

        return back()->with(
            'success',
            'Kelas berhasil dihapus'
        );
    }
}

<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;

class SiswaController extends Controller
{
    public function index(Request $request)
    {
        $kelas = $request->kelas;
        $search = $request->search;

        $siswa = User::where('role', 'siswa')

            ->when($kelas, function ($query) use ($kelas) {
                $query->where('kelas', $kelas);
            })

            ->when($search, function ($query) use ($search) {
                $query->where('name', 'like', "%{$search}%")
                    ->orWhere('nisn', 'like', "%{$search}%");
            })

            ->latest()
            ->get();

        $listKelas = User::where('role', 'siswa')
            ->select('kelas')
            ->distinct()
            ->pluck('kelas');

        return view('admin.siswa', compact(
            'siswa',
            'listKelas'
        ));
    }

    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required',
            'nisn' => 'required|unique:users',
            'kelas' => 'required',
            'email' => 'required|email|unique:users',
            'phone' => 'required',
            'password' => 'required|min:6',
            'photo' => 'nullable|image'
        ]);

        $photo = 'default.png';

        if ($request->hasFile('photo')) {

            $file = $request->file('photo');

            $filename = time() . '_' . $file->getClientOriginalName();

            $file->storeAs('siswa', $filename, 'public');

            $photo = $filename;
        }

        User::create([
            'name' => $request->name,
            'nisn' => $request->nisn,
            'kelas' => $request->kelas,
            'email' => $request->email,
            'phone' => $request->phone,
            'password' => Hash::make($request->password),
            'photo' => $photo,
            'role' => 'siswa',
        ]);

        return back()->with('success', 'Siswa berhasil ditambahkan');
    }

    public function update(Request $request, $id)
    {
        $siswa = User::findOrFail($id);

        $request->validate([
            'name' => 'required',
            'nisn' => 'required|unique:users,nisn,' . $id,
            'kelas' => 'required',
            'email' => 'required|email|unique:users,email,' . $id,
            'phone' => 'required',
        ]);

        $photo = $siswa->photo;

        if ($request->hasFile('photo')) {

            if ($photo != 'default.png') {
                Storage::disk('public')->delete('siswa/' . $photo);
            }

            $file = $request->file('photo');

            $filename = time() . '_' . $file->getClientOriginalName();

            $file->storeAs('siswa', $filename, 'public');

            $photo = $filename;
        }

        $siswa->update([
            'name' => $request->name,
            'nisn' => $request->nisn,
            'kelas' => $request->kelas,
            'email' => $request->email,
            'phone' => $request->phone,
            'photo' => $photo,
        ]);

        return back()->with('success', 'Siswa berhasil diupdate');
    }

    public function destroy($id)
    {
        $siswa = User::findOrFail($id);

        if ($siswa->photo != 'default.png') {
            Storage::disk('public')->delete('siswa/' . $siswa->photo);
        }

        $siswa->delete();

        return back()->with('success', 'Siswa berhasil dihapus');
    }
}

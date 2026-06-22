<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\Kelas;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;
use App\Imports\SiswaImport;
use Maatwebsite\Excel\Facades\Excel;
use App\Exports\SiswaTemplateExport;

class SiswaController extends Controller
{
    public function index(Request $request)
    {
        $kelas = Kelas::latest()->get();

        $siswa = User::with('kelas')
            ->where('role', 'siswa')

            ->when($request->kelas, function ($query) use ($request) {

                $query->where('kelas_id', $request->kelas);

            })

            ->when($request->search, function ($query) use ($request) {

                $query->where(function ($q) use ($request) {

                    $q->where('name', 'like', '%' . $request->search . '%')
                      ->orWhere('nisn', 'like', '%' . $request->search . '%');

                });

            })

            ->latest()
            ->get();

        return view('admin.siswa', compact(
            'siswa',
            'kelas'
        ));
    }

    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required',
            'nisn' => 'required|unique:users',
            'kelas_id' => 'required',
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
            'kelas_id' => $request->kelas_id,
            'email' => $request->email,
            'phone' => $request->phone,
            'password' => Hash::make($request->password),
            'photo' => $photo,
            'role' => 'siswa',
        ]);

        return back()->with(
            'success',
            'Siswa berhasil ditambahkan'
        );
    }

    public function update(Request $request, $id)
    {
        $siswa = User::findOrFail($id);

        $request->validate([
            'name' => 'required',
            'nisn' => 'required|unique:users,nisn,' . $id,
            'kelas_id' => 'required',
            'email' => 'required|email|unique:users,email,' . $id,
            'phone' => 'required',
        ]);

        $photo = $siswa->photo;

        if ($request->hasFile('photo')) {

            if ($photo != 'default.png') {

                Storage::disk('public')
                    ->delete('siswa/' . $photo);

            }

            $file = $request->file('photo');

            $filename = time() . '_' . $file->getClientOriginalName();

            $file->storeAs('siswa', $filename, 'public');

            $photo = $filename;
        }

        $data = [
            'name' => $request->name,
            'nisn' => $request->nisn,
            'kelas_id' => $request->kelas_id,
            'email' => $request->email,
            'phone' => $request->phone,
            'photo' => $photo,
        ];

        // UPDATE PASSWORD JIKA DIISI
        if ($request->password) {

            $data['password'] =
                Hash::make($request->password);

        }

        $siswa->update($data);

        return back()->with(
            'success',
            'Siswa berhasil diupdate'
        );
    }

    public function destroy($id)
    {
        $siswa = User::findOrFail($id);

        if ($siswa->photo != 'default.png') {

            Storage::disk('public')
                ->delete('siswa/' . $siswa->photo);

        }

        $siswa->delete();

        return back()->with(
            'success',
            'Siswa berhasil dihapus'
        );
    }

    public function import(Request $request)
    {
        $request->validate([
            'file' => 'required|mimes:xlsx,xls,csv'
        ]);

        Excel::import(new SiswaImport, $request->file('file'));

        return back()->with('success', 'Import siswa berhasil');
    }

    public function downloadTemplate()
    {
        return Excel::download(
            new SiswaTemplateExport,
            'template_siswa.xlsx'
        );
    }
}

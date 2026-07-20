<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use App\Imports\GuruImport;
use App\Exports\GuruTemplateExport;
use Maatwebsite\Excel\Facades\Excel;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;

class GuruController extends Controller
{
    public function index(Request $request)
    {
        $search = $request->search;

        $guru = User::where('role', 'guru')

            ->when($search, function ($query) use ($search) {

                $query->where(function ($q) use ($search) {

                    $q->where('name', 'like', "%{$search}%")
                        ->orWhere('nip', 'like', "%{$search}%")
                        ->orWhere('email', 'like', "%{$search}%");

                });

            })

            ->latest()
            ->get();

        return view('admin.guru', compact(
            'guru'
        ));
    }

    public function store(Request $request)
    {
        $request->validate([

            'name' => 'required',
            'email' => 'required|email|unique:users',
            'nip' => 'required|unique:users',
            'phone' => 'required',
            'password' => 'required|min:6',
            'photo' => 'nullable|image'

        ]);

        $photo = 'default.png';

        if ($request->hasFile('photo')) {

            $file = $request->file('photo');

            $filename = time() . '_' . $file->getClientOriginalName();

            $file->storeAs('guru', $filename, 'public');

            $photo = $filename;
        }

        User::create([

            'name' => $request->name,
            'email' => $request->email,
            'nip' => $request->nip,
            'phone' => $request->phone,
            'password' => Hash::make($request->password),
            'photo' => $photo,
            'role' => 'guru'

        ]);

        return back()->with(
            'success',
            'Data guru berhasil ditambahkan'
        );
    }

    public function update(Request $request, $id)
    {
        $guru = User::findOrFail($id);

        $request->validate([

            'name' => 'required',
            'email' => 'required|email|unique:users,email,' . $id,
            'nip' => 'required|unique:users,nip,' . $id,
            'phone' => 'required',
            'photo' => 'nullable|image'

        ]);

        $photo = $guru->photo;

        if ($request->hasFile('photo')) {

            if (
                $photo &&
                $photo != 'default.png'
            ) {

                Storage::disk('public')
                    ->delete('guru/' . $photo);

            }

            $file = $request->file('photo');

            $filename = time() . '_' . $file->getClientOriginalName();

            $file->storeAs('guru', $filename, 'public');

            $photo = $filename;
        }

        $data = [

            'name' => $request->name,
            'email' => $request->email,
            'nip' => $request->nip,
            'phone' => $request->phone,
            'photo' => $photo

        ];

        if ($request->password) {

            $data['password'] = Hash::make(
                $request->password
            );
        }

        $guru->update($data);

        return back()->with(
            'success',
            'Data guru berhasil diupdate'
        );
    }

    public function destroy($id)
    {
        $guru = User::findOrFail($id);

        if (
            $guru->photo &&
            $guru->photo != 'default.png'
        ) {

            Storage::disk('public')
                ->delete('guru/' . $guru->photo);

        }

        $guru->delete();

        return back()->with(
            'success',
            'Data guru berhasil dihapus'
        );
    }

    // ==========================
    // Import Excel Guru
    // ==========================
    public function import(Request $request)
    {
        $request->validate([
            'file' => 'required|mimes:xlsx,xls,csv',
        ]);

        $import = new GuruImport();
        Excel::import($import, $request->file('file'));

        if ($import->failures()->isNotEmpty()) {
            $pesanGagal = $import->failures()->map(function ($failure) {
                return 'Baris ' . $failure->row() . ': ' . implode(', ', $failure->errors());
            })->implode(' | ');

            return redirect()
                ->route('admin.guru.index')
                ->with('error', 'Sebagian data gagal diimport: ' . $pesanGagal);
        }

        return redirect()
            ->route('admin.guru.index')
            ->with('success', 'Data guru berhasil diimport.');
    }

    // ==========================
    // Download Template Excel Guru
    // ==========================
    public function downloadTemplate()
    {
        return Excel::download(new GuruTemplateExport(), 'Template-Import-Guru.xlsx');
    }

}

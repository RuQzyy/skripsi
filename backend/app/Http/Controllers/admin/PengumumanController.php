<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Pengumuman;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class PengumumanController extends Controller
{
    public function index()
    {
        $pengumuman = Pengumuman::latest()->get();

        return view(
            'admin.pengumuman',
            compact('pengumuman')
        );
    }

    public function store(Request $request)
    {
        $request->validate([
            'judul' => 'required',
            'deskripsi' => 'required',
            'tanggal' => 'required|date',
            'foto' => 'required|image|mimes:jpg,jpeg,png|max:2048'
        ]);

        $foto = null;

        if ($request->hasFile('foto')) {

            $file = $request->file('foto');

            $foto = time().'_'.$file->getClientOriginalName();

            $file->storeAs(
                'pengumuman',
                $foto,
                'public'
            );
        }

        Pengumuman::create([
            'judul' => $request->judul,
            'deskripsi' => $request->deskripsi,
            'tanggal' => $request->tanggal,
            'foto' => $foto
        ]);

        return redirect()
            ->back()
            ->with('success', 'Pengumuman berhasil ditambahkan');
    }

    public function update(Request $request, Pengumuman $pengumuman)
    {
        $request->validate([
            'judul' => 'required',
            'deskripsi' => 'required',
            'tanggal' => 'required|date'
        ]);

        $foto = $pengumuman->foto;

        if ($request->hasFile('foto')) {

            if (
                $pengumuman->foto &&
                Storage::disk('public')->exists(
                    'pengumuman/'.$pengumuman->foto
                )
            ) {

                Storage::disk('public')->delete(
                    'pengumuman/'.$pengumuman->foto
                );
            }

            $file = $request->file('foto');

            $foto = time().'_'.$file->getClientOriginalName();

            $file->storeAs(
                'pengumuman',
                $foto,
                'public'
            );
        }

        $pengumuman->update([
            'judul' => $request->judul,
            'deskripsi' => $request->deskripsi,
            'tanggal' => $request->tanggal,
            'foto' => $foto
        ]);

        return redirect()
            ->back()
            ->with('success', 'Pengumuman berhasil diupdate');
    }

    public function destroy(Pengumuman $pengumuman)
    {
        if (
            $pengumuman->foto &&
            Storage::disk('public')->exists(
                'pengumuman/'.$pengumuman->foto
            )
        ) {

            Storage::disk('public')->delete(
                'pengumuman/'.$pengumuman->foto
            );
        }

        $pengumuman->delete();

        return redirect()
            ->back()
            ->with('success', 'Pengumuman berhasil dihapus');
    }
}

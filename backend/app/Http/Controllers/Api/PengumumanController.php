<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Pengumuman;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class PengumumanController extends Controller
{

    // ================= LIST PENGUMUMAN =================
   public function index(Request $request)
{
    $limit = $request->limit;

    // ================= DASHBOARD (LIMIT) =================
    if ($limit) {

        $pengumuman = Pengumuman::latest()->limit($limit)->get();

        $data = $pengumuman->map(function ($item) {
            return [
                'id' => $item->id,
                'judul' => $item->judul,
                'deskripsi' => $item->deskripsi,
                'tanggal' => $item->tanggal,
                'foto' => url('storage/pengumuman/' . $item->foto),
            ];
        });

        return response()->json([
            'success' => true,
            'data' => $data
        ]);
    }

    // ================= PAGINATION =================
    $pengumuman = Pengumuman::latest()->paginate(5);

    $data = collect($pengumuman->items())->map(function ($item) {
        return [
            'id' => $item->id,
            'judul' => $item->judul,
            'deskripsi' => $item->deskripsi,
            'tanggal' => $item->tanggal,
            'foto' => url('storage/pengumuman/' . $item->foto),
        ];
    });

    return response()->json([
        'success' => true,
        'data' => $data,
        'current_page' => $pengumuman->currentPage(),
        'last_page' => $pengumuman->lastPage()
    ]);
}


    // ================= DETAIL PENGUMUMAN =================
    public function show($id)
    {
        $item = Pengumuman::find($id);

        if (!$item) {
            return response()->json([
                "success" => false,
                "message" => "Pengumuman tidak ditemukan"
            ], 404);
        }

        $data = [
            'id' => $item->id,
            'judul' => $item->judul,
            'deskripsi' => $item->deskripsi,
            'tanggal' => $item->tanggal,
            'foto' => url('storage/pengumuman/' . $item->foto),
        ];

        return response()->json([
            "success" => true,
            "data" => $data
        ]);
    }


    // ================= TAMBAH PENGUMUMAN =================
    public function store(Request $request)
    {
        $request->validate([
            'judul' => 'required',
            'deskripsi' => 'required',
            'tanggal' => 'required|date',
            'foto' => 'image|mimes:jpg,jpeg,png|max:2048'
        ]);

        $foto = null;

        if ($request->hasFile('foto')) {
            $file = $request->file('foto');
            $filename = time().'_'.$file->getClientOriginalName();
            $file->storeAs('pengumuman', $filename, 'public');
            $foto = $filename;
        }

        $data = Pengumuman::create([
            'judul' => $request->judul,
            'deskripsi' => $request->deskripsi,
            'tanggal' => $request->tanggal,
            'foto' => $foto
        ]);

        return response()->json([
            "success" => true,
            "message" => "Pengumuman berhasil ditambahkan",
            "data" => $data
        ]);
    }


    // ================= UPDATE PENGUMUMAN =================
    public function update(Request $request, $id)
    {
        $data = Pengumuman::find($id);

        if (!$data) {
            return response()->json([
                "success" => false,
                "message" => "Pengumuman tidak ditemukan"
            ], 404);
        }

        $foto = $data->foto;

        if ($request->hasFile('foto')) {

            // hapus foto lama
            if ($foto && Storage::disk('public')->exists('pengumuman/'.$foto)) {
                Storage::disk('public')->delete('pengumuman/'.$foto);
            }

            $file = $request->file('foto');
            $filename = time().'_'.$file->getClientOriginalName();
            $file->storeAs('pengumuman', $filename, 'public');

            $foto = $filename;
        }

        $data->update([
            'judul' => $request->judul,
            'deskripsi' => $request->deskripsi,
            'tanggal' => $request->tanggal,
            'foto' => $foto
        ]);

        return response()->json([
            "success" => true,
            "message" => "Pengumuman berhasil diupdate"
        ]);
    }


    // ================= HAPUS PENGUMUMAN =================
    public function destroy($id)
    {
        $data = Pengumuman::find($id);

        if (!$data) {
            return response()->json([
                "success" => false,
                "message" => "Pengumuman tidak ditemukan"
            ], 404);
        }

        // hapus foto
        if ($data->foto && Storage::disk('public')->exists('pengumuman/'.$data->foto)) {
            Storage::disk('public')->delete('pengumuman/'.$data->foto);
        }

        $data->delete();

        return response()->json([
            "success" => true,
            "message" => "Pengumuman berhasil dihapus"
        ]);
    }
}

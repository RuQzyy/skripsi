<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Imports\GuruImport;
use App\Exports\GuruTemplateExport;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\Rule;
use Maatwebsite\Excel\Facades\Excel;

class GuruController extends Controller
{
    /**
     * Panjang digit minimal untuk NIP/NUPTK.
     * NUPTK = 16 digit.
     */
    private const NIP_MIN_LENGTH = 16;

    /**
     * Panjang digit maksimal untuk NIP/NUPTK.
     * NIP PNS = 18 digit.
     */
    private const NIP_MAX_LENGTH = 18;

    /**
     * Panjang minimal password.
     */
    private const PASSWORD_MIN_LENGTH = 8;

    /**
     * Menampilkan data guru.
     */
    public function index(Request $request)
    {
        $search  = $request->search;
        $perPage = (int) $request->input('per_page', 10);

        // Batasi pilihan per_page agar tidak disalahgunakan
        if (! in_array($perPage, [10, 25, 50, 100])) {
            $perPage = 10;
        }

        $guru = User::where('role', 'guru')
            ->when($search, function ($query) use ($search) {
                $query->where(function ($q) use ($search) {
                    $q->where('name', 'like', '%' . $search . '%')
                        ->orWhere('nip', 'like', '%' . $search . '%')
                        ->orWhere('email', 'like', '%' . $search . '%');
                });
            })
            ->latest()
            ->paginate($perPage)
            ->withQueryString();

        return view('admin.guru', compact('guru', 'search', 'perPage'));
    }


    /**
     * Aturan validasi untuk form tambah/edit guru.
     * Dipusatkan di satu method agar konsisten & mudah dirawat.
     */
    private function rules(?int $ignoreId = null): array
    {
        return [
            'name' => ['required', 'string', 'min:3', 'max:100'],

            'email' => [
                'required',
                'email',
                Rule::unique('users', 'email')->ignore($ignoreId),
            ],

            // NIP (18 digit) atau NUPTK (16 digit), keduanya disimpan di kolom yang sama
            'nip' => [
                'required',
                'digits_between:' . self::NIP_MIN_LENGTH . ',' . self::NIP_MAX_LENGTH,
                Rule::unique('users', 'nip')->ignore($ignoreId),
            ],

            'phone' => ['required', 'digits_between:9,15'],

            'password' => $ignoreId
                // Saat edit: boleh kosong, tapi jika diisi wajib ikut aturan kekuatan password
                ? ['nullable', 'string', 'min:' . self::PASSWORD_MIN_LENGTH, 'regex:/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).+$/']
                // Saat tambah: wajib diisi
                : ['required', 'string', 'min:' . self::PASSWORD_MIN_LENGTH, 'regex:/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).+$/'],

            'photo' => ['nullable', 'image', 'max:2048'],
        ];
    }

    /**
     * Pesan error kustom (dipakai untuk store & update).
     */
    private function messages(): array
    {
        return [
            'name.required' => 'Nama guru wajib diisi.',
            'name.min'      => 'Nama guru minimal 3 karakter.',
            'name.max'      => 'Nama guru maksimal 100 karakter.',

            'email.required' => 'Email wajib diisi.',
            'email.email'    => 'Format email tidak valid.',
            'email.unique'   => 'Email tersebut sudah digunakan.',

            'nip.required'       => 'NIP/NUPTK wajib diisi.',
            'nip.digits_between' => 'NIP/NUPTK harus berupa angka, 16 digit (NUPTK) atau 18 digit (NIP).',
            'nip.unique'         => 'NIP/NUPTK tersebut sudah terdaftar.',

            'phone.required'       => 'Nomor HP wajib diisi.',
            'phone.digits_between' => 'Nomor HP harus berupa angka, 9-15 digit.',

            'password.required' => 'Password wajib diisi.',
            'password.min'      => 'Password minimal ' . self::PASSWORD_MIN_LENGTH . ' karakter.',
            'password.regex'    => 'Password harus mengandung huruf besar, huruf kecil, dan angka.',

            'photo.image' => 'File foto harus berupa gambar.',
            'photo.max'   => 'Ukuran foto maksimal 2MB.',
        ];
    }


    /**
     * Menyimpan data guru baru.
     */
    public function store(Request $request)
    {
        $validator = Validator::make(
            $request->all(),
            $this->rules(),
            $this->messages()
        );

        if ($validator->fails()) {
            return redirect()
                ->back()
                ->withErrors($validator)
                ->withInput();
        }


        /*
        |--------------------------------------------------------------------------
        | Upload Foto
        |--------------------------------------------------------------------------
        */

        $photo = 'default.png';

        if ($request->hasFile('photo')) {
            $file = $request->file('photo');

            $filename = time() . '_' . $file->getClientOriginalName();

            $file->storeAs(
                'guru',
                $filename,
                'public'
            );

            $photo = $filename;
        }


        /*
        |--------------------------------------------------------------------------
        | Simpan Guru
        |--------------------------------------------------------------------------
        */

        User::create([
            'name'     => $request->name,
            'email'    => $request->email,
            'nip'      => $request->nip,
            'phone'    => $request->phone,
            'password' => Hash::make($request->password),
            'photo'    => $photo,
            'role'     => 'guru',
        ]);


        return redirect()
            ->back()
            ->with(
                'success',
                'Data guru berhasil ditambahkan.'
            );
    }


    /**
     * Mengupdate data guru.
     */
    public function update(Request $request, int $id)
    {
        $guru = User::findOrFail($id);


        $validator = Validator::make(
            $request->all(),
            $this->rules($guru->id),
            $this->messages()
        );


        if ($validator->fails()) {
            return redirect()
                ->back()
                ->withErrors($validator)
                ->withInput();
        }


        /*
        |--------------------------------------------------------------------------
        | Foto Lama
        |--------------------------------------------------------------------------
        */

        $photo = $guru->photo;


        /*
        |--------------------------------------------------------------------------
        | Upload Foto Baru
        |--------------------------------------------------------------------------
        */

        if ($request->hasFile('photo')) {

            if (
                $photo &&
                $photo !== 'default.png'
            ) {
                Storage::disk('public')
                    ->delete('guru/' . $photo);
            }


            $file = $request->file('photo');

            $filename = time() . '_' . $file->getClientOriginalName();

            $file->storeAs(
                'guru',
                $filename,
                'public'
            );

            $photo = $filename;
        }


        /*
        |--------------------------------------------------------------------------
        | Data Update
        |--------------------------------------------------------------------------
        */

        $data = [
            'name'  => $request->name,
            'email' => $request->email,
            'nip'   => $request->nip,
            'phone' => $request->phone,
            'photo' => $photo,
        ];


        /*
        |--------------------------------------------------------------------------
        | Update Password Jika Diisi
        |--------------------------------------------------------------------------
        */

        if ($request->filled('password')) {
            $data['password'] = Hash::make(
                $request->password
            );
        }


        $guru->update($data);


        return redirect()
            ->back()
            ->with(
                'success',
                'Data guru berhasil diupdate.'
            );
    }


    /**
     * Menghapus data guru.
     */
    public function destroy(int $id)
    {
        $guru = User::findOrFail($id);


        /*
        |--------------------------------------------------------------------------
        | Hapus Foto
        |--------------------------------------------------------------------------
        */

        if (
            $guru->photo &&
            $guru->photo !== 'default.png'
        ) {
            Storage::disk('public')
                ->delete('guru/' . $guru->photo);
        }


        /*
        |--------------------------------------------------------------------------
        | Hapus Data
        |--------------------------------------------------------------------------
        */

        $guru->delete();


        return redirect()
            ->back()
            ->with(
                'success',
                'Data guru berhasil dihapus.'
            );
    }


    /**
     * Import data guru dari Excel.
     */
    public function import(Request $request)
    {
        $validator = Validator::make(
            $request->all(),
            [
                'file' => 'required|mimes:xlsx,xls,csv',
            ],
            [
                'file.required' => 'File Excel wajib dipilih.',
                'file.mimes'    => 'File harus berformat XLSX, XLS, atau CSV.',
            ]
        );


        if ($validator->fails()) {
            return redirect()
                ->back()
                ->withErrors($validator);
        }


        try {

            $import = new GuruImport();

            Excel::import(
                $import,
                $request->file('file')
            );


            /*
            |--------------------------------------------------------------------------
            | Cek Data Gagal
            |--------------------------------------------------------------------------
            */

            if ($import->failures()->isNotEmpty()) {

                $pesanGagal = $import->failures()
                    ->map(function ($failure) {

                        return 'Baris ' .
                            $failure->row() .
                            ': ' .
                            implode(
                                ', ',
                                $failure->errors()
                            );
                    })
                    ->implode(' | ');


                return redirect()
                    ->route('admin.guru.index')
                    ->with(
                        'error',
                        'Sebagian data gagal diimport: ' .
                        $pesanGagal
                    );
            }


            /*
            |--------------------------------------------------------------------------
            | Import Berhasil
            |--------------------------------------------------------------------------
            */

            return redirect()
                ->route('admin.guru.index')
                ->with(
                    'success',
                    'Semua data guru berhasil diimport.'
                );

        } catch (\Throwable $e) {

            return redirect()
                ->route('admin.guru.index')
                ->with(
                    'error',
                    'Import gagal: ' .
                    $e->getMessage()
                );
        }
    }


    /**
     * Download template Excel.
     */
    public function downloadTemplate()
    {
        return Excel::download(
            new GuruTemplateExport(),
            'Template-Import-Guru.xlsx'
        );
    }
}

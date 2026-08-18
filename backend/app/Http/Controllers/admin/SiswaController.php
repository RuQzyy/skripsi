<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\Kelas;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\Rule;
use App\Imports\SiswaImport;
use Maatwebsite\Excel\Facades\Excel;
use App\Exports\SiswaTemplateExport;

class SiswaController extends Controller
{
    /**
     * Panjang digit NISN yang berlaku (standar nasional = 10 digit).
     * Ubah nilai ini di satu tempat jika kebijakan sekolah berbeda.
     */
    private const NISN_LENGTH = 10;

    /**
     * Panjang minimal password.
     */
    private const PASSWORD_MIN_LENGTH = 8;


    public function index(Request $request)
    {
        $kelas = Kelas::latest()->get();

        $perPage = (int) $request->input('per_page', 12);

        // Batasi pilihan per_page agar tidak disalahgunakan
        if (! in_array($perPage, [12, 24, 48, 96])) {
            $perPage = 12;
        }

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
            ->paginate($perPage)
            ->withQueryString();

        return view('admin.siswa', compact(
            'siswa',
            'kelas',
            'perPage'
        ));
    }


    /**
     * Aturan validasi untuk form tambah/edit siswa.
     * Dipusatkan di satu method agar konsisten & mudah dirawat.
     */
    private function rules(?int $ignoreId = null): array
    {
        return [
            'name' => ['required', 'string', 'min:3', 'max:100'],

            'nisn' => [
                'required',
                'digits:' . self::NISN_LENGTH,
                Rule::unique('users', 'nisn')->ignore($ignoreId),
            ],

            'kelas_id' => ['required', 'exists:kelas,id'],

            'email' => [
                'required',
                'email',
                Rule::unique('users', 'email')->ignore($ignoreId),
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
            'name.required' => 'Nama siswa wajib diisi.',
            'name.min'      => 'Nama siswa minimal 3 karakter.',
            'name.max'      => 'Nama siswa maksimal 100 karakter.',

            'nisn.required' => 'NISN wajib diisi.',
            'nisn.digits'   => 'NISN harus terdiri dari tepat ' . self::NISN_LENGTH . ' digit angka.',
            'nisn.unique'   => 'NISN tersebut sudah terdaftar.',

            'kelas_id.required' => 'Kelas wajib dipilih.',
            'kelas_id.exists'   => 'Kelas yang dipilih tidak valid.',

            'email.required' => 'Email wajib diisi.',
            'email.email'    => 'Format email tidak valid.',
            'email.unique'   => 'Email tersebut sudah digunakan.',

            'phone.required'       => 'Nomor HP wajib diisi.',
            'phone.digits_between' => 'Nomor HP harus berupa angka, 9-15 digit.',

            'password.required' => 'Password wajib diisi.',
            'password.min'      => 'Password minimal ' . self::PASSWORD_MIN_LENGTH . ' karakter.',
            'password.regex'    => 'Password harus mengandung huruf besar, huruf kecil, dan angka.',

            'photo.image' => 'File foto harus berupa gambar.',
            'photo.max'   => 'Ukuran foto maksimal 2MB.',
        ];
    }


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

        return redirect()
            ->back()
            ->with(
                'success',
                'Data siswa berhasil ditambahkan.'
            );
    }

    public function update(Request $request, $id)
    {
        $siswa = User::findOrFail($id);

        $validator = Validator::make(
            $request->all(),
            $this->rules($siswa->id),
            $this->messages()
        );

        if ($validator->fails()) {
            return redirect()
                ->back()
                ->withErrors($validator)
                ->withInput();
        }

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
        if ($request->filled('password')) {

            $data['password'] =
                Hash::make($request->password);

        }

        $siswa->update($data);

        return redirect()
            ->back()
            ->with(
                'success',
                'Data siswa berhasil diupdate.'
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

        return redirect()
            ->back()
            ->with(
                'success',
                'Data siswa berhasil dihapus.'
            );
    }

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

            $import = new SiswaImport();

            Excel::import(
                $import,
                $request->file('file')
            );

            if (method_exists($import, 'failures') && $import->failures()->isNotEmpty()) {

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
                    ->route('admin.siswa.index')
                    ->with(
                        'error',
                        'Sebagian data gagal diimport: ' .
                        $pesanGagal
                    );
            }

            return redirect()
                ->route('admin.siswa.index')
                ->with(
                    'success',
                    'Semua data siswa berhasil diimport.'
                );

        } catch (\Throwable $e) {

            return redirect()
                ->route('admin.siswa.index')
                ->with(
                    'error',
                    'Import gagal: ' .
                    $e->getMessage()
                );
        }
    }

    public function downloadTemplate()
    {
        return Excel::download(
            new SiswaTemplateExport,
            'Template-Import-Siswa.xlsx'
        );
    }

    public function resetFaceId($id)
    {
        $siswa = User::findOrFail($id);

        $siswa->update([
            'face_id' => null
        ]);

        return redirect()
            ->back()
            ->with(
                'success',
                'Face ID siswa berhasil direset.'
            );
    }
}

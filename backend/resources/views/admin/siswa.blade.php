@extends('admin.layouts.app')

@section('title', 'Data Siswa')
@section('page-title', 'Data Siswa')

@section('content')

    <script src="https://code.iconify.design/iconify-icon/1.0.8/iconify-icon.min.js"></script>

    <div class="space-y-6">

        {{-- HEADER --}}
        <div class="flex flex-col md:flex-row md:items-center md:justify-between gap-4">

            <div>

                <h1 class="text-2xl font-bold text-gray-800">
                    Data Siswa
                </h1>

                <p class="text-sm text-gray-500">
                    Kelola seluruh data siswa SMA 15 Ambon
                    <span class="text-gray-400">
                        &middot; {{ $siswa->total() }} total data
                    </span>
                </p>

            </div>

            <div class="flex gap-3">

                {{-- IMPORT EXCEL --}}
                <button onclick="openImportModal()"
                    class="bg-green-600 hover:bg-green-700 text-white px-5 py-3 rounded-xl flex items-center gap-2">

                    <iconify-icon icon="solar:upload-bold"></iconify-icon>

                    Import Excel

                </button>

                {{-- TAMBAH --}}
                <button onclick="openTambahModal()"
                    class="bg-primary hover:bg-secondary text-white px-5 py-3 rounded-xl flex items-center gap-2">

                    <iconify-icon icon="solar:add-circle-bold"></iconify-icon>

                    Tambah Siswa

                </button>

            </div>

        </div>

        {{-- FILTER --}}
        <div class="bg-white p-5 rounded-2xl shadow-sm">

            <form method="GET">

                <div class="grid grid-cols-1 md:grid-cols-4 gap-4">

                    {{-- SEARCH --}}
                    <div class="relative md:col-span-2">

                        <iconify-icon icon="solar:magnifer-linear"
                            class="absolute left-4 top-1/2 -translate-y-1/2 text-gray-400">
                        </iconify-icon>

                        <input type="text" name="search" value="{{ request('search') }}"
                            placeholder="Cari nama atau NISN..."
                            class="w-full border rounded-xl pl-12 pr-4 py-3 focus:outline-none focus:ring-2 focus:ring-primary">

                    </div>

                    {{-- FILTER KELAS --}}
                    <select name="kelas"
                        class="w-full border rounded-xl px-4 py-3 focus:outline-none focus:ring-2 focus:ring-primary">

                        <option value="">
                            Semua Kelas
                        </option>

                        @foreach ($kelas as $k)
                            <option value="{{ $k->id }}" {{ request('kelas') == $k->id ? 'selected' : '' }}>

                                {{ $k->nama_kelas }}

                            </option>
                        @endforeach

                    </select>

                    {{-- BUTTON --}}
                    <button class="bg-primary hover:bg-secondary text-white rounded-xl px-4 py-3">

                        Filter Data

                    </button>

                </div>

                {{-- PER PAGE --}}
                <div class="mt-4 flex items-center gap-2">

                    <label class="text-sm text-gray-500">
                        Tampilkan
                    </label>

                    <select name="per_page" onchange="this.form.submit()"
                        class="border rounded-xl px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primary">

                        @foreach ([12, 24, 48, 96] as $option)
                            <option value="{{ $option }}" @selected((int) request('per_page', 12) === $option)>
                                {{ $option }} data
                            </option>
                        @endforeach

                    </select>

                </div>

            </form>

        </div>

        {{-- ================= NOTIFIKASI ================= --}}

        @if (session('success'))
            <script>
                document.addEventListener('DOMContentLoaded', function() {
                    Swal.fire({
                        toast: true,
                        position: 'top-end',
                        icon: 'success',
                        title: 'Berhasil',
                        text: @json(session('success')),
                        showConfirmButton: false,
                        timer: 2500,
                        timerProgressBar: true,
                    });
                });
            </script>
        @endif

        @if (session('error'))
            <script>
                document.addEventListener('DOMContentLoaded', function() {
                    Swal.fire({
                        icon: 'error',
                        title: 'Proses Gagal',
                        text: @json(session('error')),
                        confirmButtonText: 'Mengerti',
                        confirmButtonColor: '#dc2626',
                    });
                });
            </script>
        @endif

        @if ($errors->any())
            <script>
                document.addEventListener('DOMContentLoaded', function() {

                    let errors = @json($errors->all());

                    Swal.fire({
                        icon: 'warning',
                        title: 'Periksa Kembali Data Anda',
                        html: `
                            <div class="text-left text-sm space-y-2 mt-2">
                                ${errors.map(error => `
                                    <div class="flex items-start gap-2">
                                        <span class="text-red-500 mt-0.5">&#10007;</span>
                                        <span>${error}</span>
                                    </div>
                                `).join('')}
                            </div>
                        `,
                        confirmButtonText: 'Perbaiki',
                        confirmButtonColor: '#dc2626',
                    });

                });
            </script>
        @endif

        {{--
            ================= TABLE =================
            PERBAIKAN UTAMA ADA DI SINI:
            - Kolom "Foto" dibuat sticky di kiri (sticky left-0)
            - Kolom "Aksi" dibuat sticky di kanan (sticky right-0)
            Sehingga kedua kolom ini SELALU terlihat walau tabel di-scroll
            horizontal karena banyak kolom (min-w-[1080px]). Sebelumnya
            kolom Aksi "hilang" bukan karena tidak ada di kode, tapi
            karena terdorong keluar layar dan scrollbar-nya tipis/tidak
            terlihat jelas.
        --}}
        <div class="bg-white rounded-2xl shadow-sm overflow-hidden">

            {{-- Container scroll: aman untuk data banyak, header tetap terlihat --}}
            <div class="overflow-x-auto overflow-y-auto max-h-[65vh] custom-scrollbar">

                <table class="w-full min-w-[1080px] border-separate border-spacing-0">

                    <thead class="bg-gray-50 sticky top-0 z-20 shadow-sm">

                        <tr class="text-left text-sm text-gray-600">

                            <th class="px-6 py-4 sticky left-0 z-30 bg-gray-50">
                                Foto
                            </th>

                            <th class="px-6 py-4">
                                Nama
                            </th>

                            <th class="px-6 py-4">
                                NISN
                            </th>

                            <th class="px-6 py-4">
                                Kelas
                            </th>

                            <th class="px-6 py-4">
                                Email
                            </th>

                            <th class="px-6 py-4">
                                No HP
                            </th>

                            <th class="px-6 py-4">
                                Face ID
                            </th>

                            <th class="px-6 py-4 text-center sticky right-0 z-30 bg-gray-50 min-w-[280px] shadow-[-6px_0_8px_-4px_rgba(0,0,0,0.12)]">
                                Aksi
                            </th>

                        </tr>

                    </thead>

                    <tbody class="divide-y">

                        @forelse($siswa as $item)
                            <tr class="hover:bg-gray-50 transition group/row">

                                <td class="px-6 py-4 sticky left-0 z-10 bg-white group-hover/row:bg-gray-50">

                                    <img src="{{ $item->photo == 'default.png' ? asset('images/default.png') : asset('storage/siswa/' . $item->photo) }}"
                                        class="w-14 h-14 rounded-xl object-cover border">

                                </td>

                                <td class="px-6 py-4">

                                    <h3 class="font-semibold text-gray-800">
                                        {{ $item->name }}
                                    </h3>

                                    <p class="text-sm text-gray-500">
                                        Siswa
                                    </p>

                                </td>

                                <td class="px-6 py-4 text-sm text-gray-600">
                                    {{ $item->nisn }}
                                </td>

                                <td class="px-6 py-4 text-sm whitespace-nowrap">

                                    <span class="inline-block bg-primary/10 text-primary text-xs font-medium px-3 py-1.5 rounded-full whitespace-nowrap">
                                        {{ optional($item->kelas)->nama_kelas ?? 'Belum Ada Kelas' }}
                                    </span>

                                </td>

                                <td class="px-6 py-4 text-sm text-gray-600">
                                    {{ $item->email }}
                                </td>

                                <td class="px-6 py-4 text-sm text-gray-600">
                                    {{ $item->phone }}
                                </td>

                                <td class="px-6 py-4 text-sm">

                                    @if ($item->face_id)
                                        <span class="inline-flex items-center gap-1 text-green-600 font-medium whitespace-nowrap">
                                            <iconify-icon icon="solar:shield-check-bold"></iconify-icon>
                                            Terdaftar
                                        </span>
                                    @else
                                        <span class="inline-flex items-center gap-1 text-red-600 font-medium whitespace-nowrap">
                                            <iconify-icon icon="solar:shield-cross-bold"></iconify-icon>
                                            Belum
                                        </span>
                                    @endif

                                </td>

                                <td class="px-6 py-4 sticky right-0 z-10 bg-white min-w-[280px] group-hover/row:bg-gray-50 shadow-[-6px_0_8px_-4px_rgba(0,0,0,0.12)]">

                                    <div class="flex items-center justify-center gap-2 flex-wrap">

                                        {{-- EDIT --}}
                                        <button
                                            onclick="openEditModal(
                                            '{{ $item->id }}',
                                            @js($item->name),
                                            '{{ $item->nisn }}',
                                            '{{ $item->kelas_id }}',
                                            '{{ $item->email }}',
                                            '{{ $item->phone }}',
                                            '{{ $item->photo == 'default.png' ? asset('images/default.png') : asset('storage/siswa/' . $item->photo) }}'
                                        )"
                                            class="bg-yellow-500 hover:bg-yellow-600 text-white px-3 py-2 rounded-lg text-sm whitespace-nowrap">

                                            Edit

                                        </button>

                                        {{-- DELETE --}}
                                        <form id="deleteForm{{ $item->id }}"
                                            action="{{ route('admin.siswa.destroy', $item->id) }}" method="POST">

                                            @csrf
                                            @method('DELETE')

                                            <button type="button" onclick="confirmDelete({{ $item->id }})"
                                                class="bg-red-500 hover:bg-red-600 text-white px-3 py-2 rounded-lg text-sm whitespace-nowrap">

                                                Hapus

                                            </button>

                                        </form>

                                        {{-- RESET FACE ID --}}
                                        @if ($item->face_id)
                                            <form action="{{ route('admin.siswa.resetFace', $item->id) }}" method="POST"
                                                onsubmit="return confirm('Reset Face ID siswa ini?')">

                                                @csrf

                                                <button
                                                    class="bg-blue-600 hover:bg-blue-700 text-white px-3 py-2 rounded-lg text-sm whitespace-nowrap">

                                                    Reset Face ID

                                                </button>

                                            </form>
                                        @endif

                                    </div>

                                </td>

                            </tr>

                        @empty

                            <tr>

                                <td colspan="8" class="text-center py-14">

                                    <iconify-icon icon="solar:users-group-rounded-bold" width="70" class="text-gray-300">
                                    </iconify-icon>

                                    <h3 class="mt-3 font-semibold text-gray-700">
                                        Data siswa belum tersedia
                                    </h3>

                                </td>

                            </tr>
                        @endforelse

                    </tbody>

                </table>

            </div>

            {{-- PAGINATION --}}
            @if ($siswa->hasPages())
                <div class="px-6 py-4 border-t bg-gray-50">
                    {{ $siswa->links() }}
                </div>
            @endif

        </div>

    </div>

    {{-- MODAL TAMBAH --}}
    <div id="tambahModal" class="fixed inset-0 bg-black/50 hidden items-center justify-center z-50 p-4">

        <div class="bg-white rounded-3xl w-full max-w-md overflow-hidden max-h-[90vh] flex flex-col">

            {{-- HEADER --}}
            <div class="flex justify-between items-center p-5 border-b">

                <h2 class="font-bold text-lg">
                    Tambah Siswa
                </h2>

                <button onclick="closeTambahModal()">

                    <iconify-icon icon="solar:close-circle-bold" width="28">
                    </iconify-icon>

                </button>

            </div>

            {{-- FORM --}}
            <form action="{{ route('admin.siswa.store') }}" method="POST" enctype="multipart/form-data"
                class="flex flex-col flex-1 overflow-hidden">

                @csrf

                <div class="p-5 space-y-4 overflow-y-auto flex-1">

                    {{-- FOTO --}}
                    <div>
                        <label class="block text-sm font-medium text-gray-700 mb-1">Foto Siswa</label>

                        {{-- Background abu-abu + object-contain supaya foto apa pun rasionya tidak terpotong --}}
                        <div id="previewTambahWrapper"
                            class="hidden w-full h-40 bg-gray-100 rounded-xl border overflow-hidden mb-2 items-center justify-center">
                            <img id="previewTambah" class="max-h-40 w-full object-contain">
                        </div>

                        <input type="file" name="photo" accept="image/*" onchange="previewTambah(event)"
                            class="w-full border rounded-xl p-3">
                    </div>

                    {{-- NAMA --}}
                    <div>
                        <label class="block text-sm font-medium text-gray-700 mb-1">Nama Siswa</label>
                        <input type="text" name="name" placeholder="Nama Siswa" required minlength="3" maxlength="100"
                            class="w-full border rounded-xl px-4 py-3">
                    </div>

                    {{-- NISN --}}
                    <div>
                        <label class="block text-sm font-medium text-gray-700 mb-1">NISN</label>
                        <input type="text" id="tambahNisn" name="nisn" placeholder="NISN (10 digit)" required
                            inputmode="numeric" pattern="\d{10}" minlength="10" maxlength="10"
                            oninput="checkTambahNisn()"
                            class="w-full border border-gray-300 rounded-xl px-4 py-3 transition-colors">
                        <p id="tambahNisnFeedback" class="text-xs mt-1">
                            <span class="text-gray-400">NISN harus 10 digit angka.</span>
                        </p>
                    </div>

                    {{-- KELAS --}}
                    <div>
                        <label class="block text-sm font-medium text-gray-700 mb-1">Kelas</label>
                        <select name="kelas_id" required class="w-full border rounded-xl px-4 py-3">

                            <option value="">
                                Pilih Kelas
                            </option>

                            @foreach ($kelas as $k)
                                <option value="{{ $k->id }}">

                                    {{ $k->nama_kelas }}

                                </option>
                            @endforeach

                        </select>
                    </div>

                    {{-- EMAIL --}}
                    <div>
                        <label class="block text-sm font-medium text-gray-700 mb-1">Email</label>
                        <input type="email" name="email" placeholder="Email" required
                            class="w-full border rounded-xl px-4 py-3">
                    </div>

                    {{-- NO HP --}}
                    <div>
                        <label class="block text-sm font-medium text-gray-700 mb-1">Nomor HP</label>
                        <input type="text" id="tambahPhone" name="phone" placeholder="Nomor HP" required
                            inputmode="numeric" pattern="\d{9,15}"
                            oninput="checkTambahPhone()"
                            class="w-full border border-gray-300 rounded-xl px-4 py-3 transition-colors">
                        <p id="tambahPhoneFeedback" class="text-xs mt-1">
                            <span class="text-gray-400">Nomor HP harus 9-15 digit angka.</span>
                        </p>
                    </div>

                    {{-- PASSWORD --}}
                    <div>
                        <label class="block text-sm font-medium text-gray-700 mb-1">Password</label>
                        <input type="password" id="tambahPassword" name="password" placeholder="Password" required
                            minlength="8" oninput="checkTambahPassword()"
                            class="w-full border border-gray-300 rounded-xl px-4 py-3 transition-colors">

                        <ul class="text-xs mt-2 space-y-1">
                            <li id="pwLenCheck" class="flex items-center gap-1.5">
                                <iconify-icon icon="solar:close-circle-linear" class="text-gray-400"></iconify-icon>
                                <span class="text-gray-500">Tambahkan minimal 8 karakter</span>
                            </li>
                            <li id="pwUpperCheck" class="flex items-center gap-1.5">
                                <iconify-icon icon="solar:close-circle-linear" class="text-gray-400"></iconify-icon>
                                <span class="text-gray-500">Tambahkan huruf besar (A-Z)</span>
                            </li>
                            <li id="pwLowerCheck" class="flex items-center gap-1.5">
                                <iconify-icon icon="solar:close-circle-linear" class="text-gray-400"></iconify-icon>
                                <span class="text-gray-500">Tambahkan huruf kecil (a-z)</span>
                            </li>
                            <li id="pwNumberCheck" class="flex items-center gap-1.5">
                                <iconify-icon icon="solar:close-circle-linear" class="text-gray-400"></iconify-icon>
                                <span class="text-gray-500">Tambahkan angka (0-9)</span>
                            </li>
                        </ul>
                    </div>

                </div>

                {{-- FOOTER --}}
                <div class="p-5 border-t flex justify-end gap-3 bg-gray-50">

                    <button type="button" onclick="closeTambahModal()" class="px-5 py-2 border rounded-xl">

                        Batal

                    </button>

                    <button type="submit" class="bg-primary text-white px-5 py-2 rounded-xl">

                        Simpan

                    </button>

                </div>

            </form>

        </div>

    </div>

    {{-- MODAL EDIT --}}
    <div id="editModal" class="fixed inset-0 bg-black/50 hidden items-center justify-center z-50 p-4">

        <div class="bg-white rounded-3xl w-full max-w-md overflow-hidden max-h-[90vh] flex flex-col">

            {{-- HEADER --}}
            <div class="flex justify-between items-center p-5 border-b">

                <h2 class="font-bold text-lg">
                    Edit Siswa
                </h2>

                <button onclick="closeEditModal()">

                    <iconify-icon icon="solar:close-circle-bold" width="28">
                    </iconify-icon>

                </button>

            </div>

            {{-- FORM --}}
            <form id="editForm" method="POST" enctype="multipart/form-data"
                class="flex flex-col flex-1 overflow-hidden">

                @csrf
                @method('PUT')

                <div class="p-5 space-y-4 overflow-y-auto flex-1">

                    {{-- FOTO --}}
                    <div>
                        <label class="block text-sm font-medium text-gray-700 mb-1">Foto Siswa</label>

                        {{-- Background abu-abu + object-contain supaya foto apa pun rasionya tidak terpotong --}}
                        <div class="w-full h-40 bg-gray-100 rounded-xl border flex items-center justify-center overflow-hidden mb-2">
                            <img id="editPreview" class="max-h-40 w-full object-contain">
                        </div>

                        <input type="file" name="photo" accept="image/*" onchange="previewEdit(event)"
                            class="w-full border rounded-xl p-3">
                    </div>

                    {{-- NAMA --}}
                    <div>
                        <label class="block text-sm font-medium text-gray-700 mb-1">Nama Siswa</label>
                        <input type="text" id="editName" name="name" required minlength="3" maxlength="100"
                            class="w-full border rounded-xl px-4 py-3">
                    </div>

                    {{-- NISN --}}
                    <div>
                        <label class="block text-sm font-medium text-gray-700 mb-1">NISN</label>
                        <input type="text" id="editNisn" name="nisn" required
                            inputmode="numeric" pattern="\d{10}" minlength="10" maxlength="10"
                            oninput="checkEditNisn()"
                            class="w-full border border-gray-300 rounded-xl px-4 py-3 transition-colors">
                        <p id="editNisnFeedback" class="text-xs mt-1">
                            <span class="text-gray-400">NISN harus 10 digit angka.</span>
                        </p>
                    </div>

                    {{-- KELAS --}}
                    <div>
                        <label class="block text-sm font-medium text-gray-700 mb-1">Kelas</label>
                        <select id="editKelas" name="kelas_id" required class="w-full border rounded-xl px-4 py-3">

                            <option value="">
                                Pilih Kelas
                            </option>

                            @foreach ($kelas as $k)
                                <option value="{{ $k->id }}">

                                    {{ $k->nama_kelas }}

                                </option>
                            @endforeach

                        </select>
                    </div>

                    {{-- EMAIL --}}
                    <div>
                        <label class="block text-sm font-medium text-gray-700 mb-1">Email</label>
                        <input type="email" id="editEmail" name="email" required
                            class="w-full border rounded-xl px-4 py-3">
                    </div>

                    {{-- NO HP --}}
                    <div>
                        <label class="block text-sm font-medium text-gray-700 mb-1">Nomor HP</label>
                        <input type="text" id="editPhone" name="phone" required
                            inputmode="numeric" pattern="\d{9,15}"
                            oninput="checkEditPhone()"
                            class="w-full border border-gray-300 rounded-xl px-4 py-3 transition-colors">
                        <p id="editPhoneFeedback" class="text-xs mt-1">
                            <span class="text-gray-400">Nomor HP harus 9-15 digit angka.</span>
                        </p>
                    </div>

                    {{-- PASSWORD --}}
                    <div>
                        <label class="block text-sm font-medium text-gray-700 mb-1">
                            Password Baru <span class="text-gray-400 font-normal">(opsional)</span>
                        </label>
                        <input type="password" id="editPassword" name="password" minlength="8"
                            oninput="checkEditPassword()"
                            class="w-full border border-gray-300 rounded-xl px-4 py-3 transition-colors">

                        <p class="text-xs text-gray-400 mt-1">
                            Kosongkan jika tidak ingin mengubah password.
                        </p>

                        <ul id="editPwChecklist" class="text-xs mt-2 space-y-1 hidden">
                            <li id="editPwLenCheck" class="flex items-center gap-1.5">
                                <iconify-icon icon="solar:close-circle-linear" class="text-gray-400"></iconify-icon>
                                <span class="text-gray-500">Tambahkan minimal 8 karakter</span>
                            </li>
                            <li id="editPwUpperCheck" class="flex items-center gap-1.5">
                                <iconify-icon icon="solar:close-circle-linear" class="text-gray-400"></iconify-icon>
                                <span class="text-gray-500">Tambahkan huruf besar (A-Z)</span>
                            </li>
                            <li id="editPwLowerCheck" class="flex items-center gap-1.5">
                                <iconify-icon icon="solar:close-circle-linear" class="text-gray-400"></iconify-icon>
                                <span class="text-gray-500">Tambahkan huruf kecil (a-z)</span>
                            </li>
                            <li id="editPwNumberCheck" class="flex items-center gap-1.5">
                                <iconify-icon icon="solar:close-circle-linear" class="text-gray-400"></iconify-icon>
                                <span class="text-gray-500">Tambahkan angka (0-9)</span>
                            </li>
                        </ul>
                    </div>

                </div>

                {{-- FOOTER --}}
                <div class="p-5 border-t flex justify-end gap-3 bg-gray-50">

                    <button type="button" onclick="closeEditModal()" class="px-5 py-2 border rounded-xl">

                        Batal

                    </button>

                    <button type="submit" class="bg-yellow-500 text-white px-5 py-2 rounded-xl">

                        Update

                    </button>

                </div>

            </form>

        </div>

    </div>

    {{-- MODAL IMPORT --}}
    <div id="importModal" class="fixed inset-0 bg-black/50 hidden items-center justify-center z-50 p-4">

        <div class="bg-white rounded-3xl w-full max-w-md overflow-hidden">

            {{-- HEADER --}}
            <div class="flex justify-between items-center p-5 border-b">

                <h2 class="font-bold text-lg">
                    Import Excel Siswa
                </h2>

                <button type="button" onclick="closeImportModal()">
                    <iconify-icon icon="solar:close-circle-bold" width="28">
                    </iconify-icon>
                </button>

            </div>

            {{-- FORM --}}
            <form action="{{ route('admin.siswa.import') }}" method="POST" enctype="multipart/form-data">

                @csrf

                <div class="p-5 space-y-4">

                    <div class="bg-yellow-50 border border-yellow-200 rounded-xl p-4">

                        <p class="font-semibold">
                            Format kolom:
                        </p>

                        <p class="text-sm mt-2">
                            name | nisn (10 digit) | kelas_id | email | phone | password (min. 8 karakter)
                        </p>

                        <a href="{{ route('admin.siswa.template') }}"
                            class="inline-flex items-center gap-2 mt-4 bg-green-600 text-white px-4 py-2 rounded-xl">

                            <iconify-icon icon="solar:download-bold"></iconify-icon>

                            Download Template

                        </a>

                    </div>

                    <div>

                        <label class="block mb-2 text-sm font-medium">
                            Pilih File Excel
                        </label>

                        <input type="file" name="file" accept=".xlsx,.xls,.csv" required
                            class="w-full border rounded-xl p-3">

                    </div>

                </div>

                <div class="p-5 border-t flex justify-end gap-3">

                    <button type="button" onclick="closeImportModal()" class="px-5 py-2 border rounded-xl">

                        Batal

                    </button>

                    <button type="submit" class="bg-green-600 text-white px-5 py-2 rounded-xl">

                        Import

                    </button>

                </div>

            </form>

        </div>

    </div>

    {{-- Scrollbar horizontal supaya terlihat jelas kalau tabel bisa digeser --}}
    <style>
        .custom-scrollbar::-webkit-scrollbar {
            height: 10px;
        }
        .custom-scrollbar::-webkit-scrollbar-track {
            background: #f1f5f9;
        }
        .custom-scrollbar::-webkit-scrollbar-thumb {
            background: #94a3b8;
            border-radius: 999px;
        }
        .custom-scrollbar::-webkit-scrollbar-thumb:hover {
            background: #64748b;
        }
    </style>

    <script>
        // ================= TAMBAH =================

        function openTambahModal() {

            document
                .getElementById('tambahModal')
                .classList.remove('hidden');

            document
                .getElementById('tambahModal')
                .classList.add('flex');
        }

        function closeTambahModal() {

            document
                .getElementById('tambahModal')
                .classList.add('hidden');
        }

        function previewTambah(event) {

            if (!event.target.files || !event.target.files[0]) return;

            let img =
                document.getElementById('previewTambah');

            img.src =
                URL.createObjectURL(event.target.files[0]);

            document.getElementById('previewTambahWrapper')
                .classList.remove('hidden');

            document.getElementById('previewTambahWrapper')
                .classList.add('flex');
        }

        // ================= VALIDASI REALTIME (UMUM) =================

        // Helper: ganti warna border input sesuai status validasi
        function setFieldStatus(input, status) {
            // status: 'empty' | 'invalid' | 'valid'
            input.classList.remove(
                'border-gray-300', 'border-red-400', 'border-green-500',
                'ring-2', 'ring-green-200', 'ring-red-100'
            );

            if (status === 'valid') {
                input.classList.add('border-green-500', 'ring-2', 'ring-green-200');
            } else if (status === 'invalid') {
                input.classList.add('border-red-400', 'ring-2', 'ring-red-100');
            } else {
                input.classList.add('border-gray-300');
            }
        }

        function evaluatePasswordChecklist(val, checks) {

            let allValid = true;

            checks.forEach((item) => {

                const ok = item.test(val);

                if (!ok) allValid = false;

                const el = document.getElementById(item.id);

                if (el) {
                    el.innerHTML = ok
                        ? `<iconify-icon icon="solar:check-circle-bold" class="text-green-600"></iconify-icon>
                           <span class="text-green-600">${item.done}</span>`
                        : `<iconify-icon icon="solar:close-circle-linear" class="text-gray-400"></iconify-icon>
                           <span class="text-gray-500">${item.missing}</span>`;
                }

            });

            return allValid;
        }

        const passwordChecks = [
            { id: 'pwLenCheck', test: (v) => v.length >= 8, missing: 'Tambahkan minimal 8 karakter', done: 'Sudah 8 karakter atau lebih' },
            { id: 'pwUpperCheck', test: (v) => /[A-Z]/.test(v), missing: 'Tambahkan huruf besar (A-Z)', done: 'Sudah ada huruf besar' },
            { id: 'pwLowerCheck', test: (v) => /[a-z]/.test(v), missing: 'Tambahkan huruf kecil (a-z)', done: 'Sudah ada huruf kecil' },
            { id: 'pwNumberCheck', test: (v) => /[0-9]/.test(v), missing: 'Tambahkan angka (0-9)', done: 'Sudah ada angka' },
        ];

        // ---- PASSWORD (TAMBAH) ----
        function checkTambahPassword() {

            const input = document.getElementById('tambahPassword');
            const val = input.value;

            const allValid = evaluatePasswordChecklist(val, passwordChecks);

            if (val.length === 0) {
                setFieldStatus(input, 'empty');
            } else if (allValid) {
                setFieldStatus(input, 'valid');
            } else {
                setFieldStatus(input, 'invalid');
            }

        }

        // ---- NISN (TAMBAH, 10 digit) ----
        function checkTambahNisn() {

            const input = document.getElementById('tambahNisn');
            const feedback = document.getElementById('tambahNisnFeedback');

            input.value = input.value.replace(/\D/g, '').slice(0, 10);

            const val = input.value;

            if (val.length === 0) {

                setFieldStatus(input, 'empty');

                feedback.innerHTML =
                    '<span class="text-gray-400">NISN harus 10 digit angka.</span>';

            } else if (val.length === 10) {

                setFieldStatus(input, 'valid');

                feedback.innerHTML =
                    `<iconify-icon icon="solar:check-circle-bold" class="text-green-600"></iconify-icon>
                     <span class="text-green-600">NISN sudah 10 digit</span>`;

            } else {

                setFieldStatus(input, 'invalid');

                feedback.innerHTML =
                    `<span class="text-red-500">Tambahkan ${10 - val.length} digit lagi (saat ini ${val.length}/10)</span>`;

            }

        }

        // ---- NO HP (TAMBAH, 9-15 digit) ----
        function checkTambahPhone() {

            const input = document.getElementById('tambahPhone');
            const feedback = document.getElementById('tambahPhoneFeedback');

            input.value = input.value.replace(/\D/g, '').slice(0, 15);

            const val = input.value;

            if (val.length === 0) {

                setFieldStatus(input, 'empty');

                feedback.innerHTML =
                    '<span class="text-gray-400">Nomor HP harus 9-15 digit angka.</span>';

            } else if (val.length >= 9 && val.length <= 15) {

                setFieldStatus(input, 'valid');

                feedback.innerHTML =
                    `<iconify-icon icon="solar:check-circle-bold" class="text-green-600"></iconify-icon>
                     <span class="text-green-600">Nomor HP valid</span>`;

            } else {

                setFieldStatus(input, 'invalid');

                feedback.innerHTML =
                    `<span class="text-red-500">Tambahkan ${9 - val.length} digit lagi (minimal 9 digit)</span>`;

            }

        }

        // ---- PASSWORD (EDIT, opsional) ----
        function checkEditPassword() {

            const input = document.getElementById('editPassword');
            const checklist = document.getElementById('editPwChecklist');
            const val = input.value;

            if (val.length === 0) {
                checklist.classList.add('hidden');
                setFieldStatus(input, 'empty');
                return;
            }

            checklist.classList.remove('hidden');

            const editPasswordChecks = [
                { id: 'editPwLenCheck', test: (v) => v.length >= 8, missing: 'Tambahkan minimal 8 karakter', done: 'Sudah 8 karakter atau lebih' },
                { id: 'editPwUpperCheck', test: (v) => /[A-Z]/.test(v), missing: 'Tambahkan huruf besar (A-Z)', done: 'Sudah ada huruf besar' },
                { id: 'editPwLowerCheck', test: (v) => /[a-z]/.test(v), missing: 'Tambahkan huruf kecil (a-z)', done: 'Sudah ada huruf kecil' },
                { id: 'editPwNumberCheck', test: (v) => /[0-9]/.test(v), missing: 'Tambahkan angka (0-9)', done: 'Sudah ada angka' },
            ];

            const allValid = evaluatePasswordChecklist(val, editPasswordChecks);

            setFieldStatus(input, allValid ? 'valid' : 'invalid');

        }

        // ---- NISN (EDIT, 10 digit) ----
        function checkEditNisn() {

            const input = document.getElementById('editNisn');
            const feedback = document.getElementById('editNisnFeedback');

            input.value = input.value.replace(/\D/g, '').slice(0, 10);

            const val = input.value;

            if (val.length === 0) {

                setFieldStatus(input, 'empty');

                feedback.innerHTML =
                    '<span class="text-gray-400">NISN harus 10 digit angka.</span>';

            } else if (val.length === 10) {

                setFieldStatus(input, 'valid');

                feedback.innerHTML =
                    `<iconify-icon icon="solar:check-circle-bold" class="text-green-600"></iconify-icon>
                     <span class="text-green-600">NISN sudah 10 digit</span>`;

            } else {

                setFieldStatus(input, 'invalid');

                feedback.innerHTML =
                    `<span class="text-red-500">Tambahkan ${10 - val.length} digit lagi (saat ini ${val.length}/10)</span>`;

            }

        }

        // ---- NO HP (EDIT, 9-15 digit) ----
        function checkEditPhone() {

            const input = document.getElementById('editPhone');
            const feedback = document.getElementById('editPhoneFeedback');

            input.value = input.value.replace(/\D/g, '').slice(0, 15);

            const val = input.value;

            if (val.length === 0) {

                setFieldStatus(input, 'empty');

                feedback.innerHTML =
                    '<span class="text-gray-400">Nomor HP harus 9-15 digit angka.</span>';

            } else if (val.length >= 9 && val.length <= 15) {

                setFieldStatus(input, 'valid');

                feedback.innerHTML =
                    `<iconify-icon icon="solar:check-circle-bold" class="text-green-600"></iconify-icon>
                     <span class="text-green-600">Nomor HP valid</span>`;

            } else {

                setFieldStatus(input, 'invalid');

                feedback.innerHTML =
                    `<span class="text-red-500">Tambahkan ${9 - val.length} digit lagi (minimal 9 digit)</span>`;

            }

        }

        // ================= EDIT =================

        function openEditModal(
            id,
            name,
            nisn,
            kelas_id,
            email,
            phone,
            photo
        ) {

            document
                .getElementById('editForm')
                .action = `/admin/siswa/${id}`;

            document
                .getElementById('editName')
                .value = name;

            document
                .getElementById('editNisn')
                .value = nisn;

            document
                .getElementById('editKelas')
                .value = kelas_id;

            document
                .getElementById('editEmail')
                .value = email;

            document
                .getElementById('editPhone')
                .value = phone;

            document
                .getElementById('editPreview')
                .src = photo;

            // Reset password baru setiap modal dibuka ulang
            document.getElementById('editPassword').value = '';
            document.getElementById('editPwChecklist').classList.add('hidden');
            setFieldStatus(document.getElementById('editPassword'), 'empty');

            // Sinkronkan status warna NISN & No HP dengan data yang sudah terisi
            checkEditNisn();
            checkEditPhone();

            document
                .getElementById('editModal')
                .classList.remove('hidden');

            document
                .getElementById('editModal')
                .classList.add('flex');
        }

        function closeEditModal() {

            document
                .getElementById('editModal')
                .classList.add('hidden');
        }

        function previewEdit(event) {

            if (!event.target.files || !event.target.files[0]) return;

            let image =
                document.getElementById('editPreview');

            image.src =
                URL.createObjectURL(event.target.files[0]);
        }

        // ================= DELETE =================

        function confirmDelete(id) {

            Swal.fire({
                title: 'Hapus siswa?',
                text: 'Data tidak dapat dikembalikan.',
                icon: 'warning',
                showCancelButton: true,
                confirmButtonColor: '#dc2626',
                cancelButtonColor: '#6b7280',
                confirmButtonText: 'Ya, Hapus',
                cancelButtonText: 'Batal'
            }).then((result) => {

                if (result.isConfirmed) {

                    const form =
                        document.getElementById(`deleteForm${id}`);

                    if (form) {
                        form.submit();
                    }

                }

            });

        }

        // ================= IMPORT =================

        function openImportModal() {

            document
                .getElementById('importModal')
                .classList.remove('hidden');

            document
                .getElementById('importModal')
                .classList.add('flex');
        }

        function closeImportModal() {

            document
                .getElementById('importModal')
                .classList.add('hidden');
        }
    </script>

@endsection

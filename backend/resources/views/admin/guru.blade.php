@extends('admin.layouts.app')

@section('title', 'Data Guru')
@section('page-title', 'Data Guru')

@section('content')

    <script src="https://code.iconify.design/iconify-icon/1.0.8/iconify-icon.min.js"></script>

    <div class="space-y-6">

        {{-- HEADER --}}
        <div class="flex flex-col md:flex-row md:items-center md:justify-between gap-4">

            <div>

                <h1 class="text-2xl font-bold text-gray-800">
                    Data Guru
                </h1>

                <p class="text-sm text-gray-500">
                    Kelola seluruh data guru SMA 15 Ambon
                    <span class="text-gray-400">
                        &middot; {{ $guru->total() }} total data
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

                    Tambah Guru

                </button>

            </div>

        </div>

        {{-- FILTER --}}
        <div class="bg-white rounded-2xl p-5 shadow-sm">

            <form method="GET">

                <div class="grid grid-cols-1 md:grid-cols-4 gap-4">

                    {{-- SEARCH --}}
                    <div class="relative md:col-span-2">

                        <iconify-icon icon="solar:magnifer-outline"
                            class="absolute left-4 top-1/2 -translate-y-1/2 text-gray-400">
                        </iconify-icon>

                        <input type="text" name="search" value="{{ request('search') }}"
                            placeholder="Cari nama / NIP / NUPTK / email..."
                            class="w-full border rounded-xl pl-12 pr-4 py-3 focus:outline-none focus:ring-2 focus:ring-primary">

                    </div>

                    {{-- PER PAGE --}}
                    <div>

                        <select name="per_page" onchange="this.form.submit()"
                            class="w-full border rounded-xl px-4 py-3 focus:outline-none focus:ring-2 focus:ring-primary">

                            @foreach ([10, 25, 50, 100] as $option)
                                <option value="{{ $option }}" @selected((int) request('per_page', 10) === $option)>
                                    {{ $option }} baris / halaman
                                </option>
                            @endforeach

                        </select>

                    </div>

                    {{-- BUTTON --}}
                    <button class="bg-primary hover:bg-secondary text-white rounded-xl px-5 py-3">

                        Filter Data

                    </button>

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


        {{-- TABLE --}}
        <div class="bg-white rounded-2xl shadow-sm overflow-hidden">

            {{-- Container scroll: aman untuk data banyak, header tetap terlihat --}}
            <div class="overflow-auto max-h-[65vh]">

                <table class="w-full min-w-[820px]">

                    <thead class="bg-gray-50 sticky top-0 z-10 shadow-sm">

                        <tr class="text-left text-sm text-gray-600">

                            <th class="px-6 py-4">
                                Foto
                            </th>

                            <th class="px-6 py-4">
                                Nama
                            </th>

                            <th class="px-6 py-4">
                                NIP / NUPTK
                            </th>

                            <th class="px-6 py-4">
                                Email
                            </th>

                            <th class="px-6 py-4">
                                No HP
                            </th>

                            <th class="px-6 py-4 text-center">
                                Aksi
                            </th>

                        </tr>

                    </thead>

                    <tbody class="divide-y">

                        @forelse($guru as $item)
                            <tr class="hover:bg-gray-50 transition">

                                <td class="px-6 py-4">

                                    <img src="{{ asset('storage/guru/' . $item->photo) }}"
                                        class="w-14 h-14 rounded-xl object-cover border">

                                </td>

                                <td class="px-6 py-4">

                                    <div>

                                        <h3 class="font-semibold text-gray-800">
                                            {{ $item->name }}
                                        </h3>

                                        <p class="text-sm text-gray-500">
                                            Guru
                                        </p>

                                    </div>

                                </td>

                                <td class="px-6 py-4 text-sm text-gray-600">
                                    {{ $item->nip }}
                                    <span class="block text-xs text-gray-400">
                                        {{ strlen((string) $item->nip) === 16 ? 'NUPTK' : 'NIP' }}
                                    </span>
                                </td>

                                <td class="px-6 py-4 text-sm text-gray-600">
                                    {{ $item->email }}
                                </td>

                                <td class="px-6 py-4 text-sm text-gray-600">
                                    {{ $item->phone }}
                                </td>

                                <td class="px-6 py-4">

                                    <div class="flex items-center justify-center gap-2">

                                        {{-- DETAIL --}}
                                        <button
                                            onclick="openDetailModal(
                                            '{{ $item->name }}',
                                            '{{ $item->nip }}',
                                            '{{ $item->email }}',
                                            '{{ $item->phone }}',
                                            '{{ asset('storage/guru/' . $item->photo) }}'
                                        )"
                                            class="bg-blue-500 hover:bg-blue-600 text-white px-3 py-2 rounded-lg text-sm">

                                            Detail

                                        </button>

                                        {{-- EDIT --}}
                                        <button
                                            onclick="openEditModal(
                                            '{{ $item->id }}',
                                            '{{ $item->name }}',
                                            '{{ $item->nip }}',
                                            '{{ $item->email }}',
                                            '{{ $item->phone }}',
                                            '{{ asset('storage/guru/' . $item->photo) }}'
                                        )"
                                            class="bg-yellow-500 hover:bg-yellow-600 text-white px-3 py-2 rounded-lg text-sm">

                                            Edit

                                        </button>

                                        {{-- DELETE --}}
                                        <form id="deleteForm{{ $item->id }}"
                                            action="{{ route('admin.guru.destroy', $item->id) }}" method="POST">

                                            @csrf
                                            @method('DELETE')

                                            <button type="button" onclick="confirmDelete({{ $item->id }})"
                                                class="bg-red-500 hover:bg-red-600 text-white px-3 py-2 rounded-lg text-sm">

                                                Hapus

                                            </button>

                                        </form>

                                    </div>

                                </td>

                            </tr>

                        @empty

                            <tr>

                                <td colspan="6" class="text-center py-14">

                                    <iconify-icon icon="solar:user-cross-outline" width="70" class="text-gray-300">
                                    </iconify-icon>

                                    <h3 class="mt-3 font-semibold text-gray-700">
                                        Data guru kosong
                                    </h3>

                                </td>

                            </tr>
                        @endforelse

                    </tbody>

                </table>

            </div>

            {{-- PAGINATION --}}
            @if ($guru->hasPages())
                <div class="px-6 py-4 border-t bg-gray-50">
                    {{ $guru->links() }}
                </div>
            @endif

        </div>

    </div>

    {{-- MODAL TAMBAH --}}
    <div id="tambahModal" class="fixed inset-0 bg-black/50 hidden items-center justify-center z-50 p-4 overflow-y-auto">

        <div class="bg-white rounded-3xl w-full max-w-xl my-10">

            {{-- HEADER --}}
            <div class="flex justify-between items-center p-5 border-b">

                <h2 class="font-bold text-lg">
                    Tambah Guru
                </h2>

                <button onclick="closeTambahModal()">

                    <iconify-icon icon="solar:close-circle-bold" width="28">
                    </iconify-icon>

                </button>

            </div>

            {{-- FORM --}}
            <form action="{{ route('admin.guru.store') }}" method="POST" enctype="multipart/form-data">

                @csrf

                <div class="p-5 space-y-4 max-h-[70vh] overflow-y-auto">

                    <div>
                        <label class="block text-sm font-medium text-gray-700 mb-1">Foto Guru</label>

                        <div id="previewTambahWrapper"
                            class="hidden w-full h-48 bg-gray-100 rounded-xl border flex items-center justify-center overflow-hidden mb-2">
                            <img id="previewTambah" class="max-h-48 w-full object-contain">
                        </div>

                        <input type="file" name="photo" accept="image/*" onchange="previewTambah(event)"
                            class="w-full border rounded-xl p-3">
                    </div>

                    <div>
                        <label class="block text-sm font-medium text-gray-700 mb-1">Nama Guru</label>
                        <input type="text" name="name" placeholder="Nama Guru" required minlength="3" maxlength="100"
                            class="w-full border rounded-xl px-4 py-3">
                    </div>

                    <div>
                        <label class="block text-sm font-medium text-gray-700 mb-1">NIP / NUPTK</label>
                        <input type="text" id="tambahNip" name="nip" placeholder="NIP (18 digit) atau NUPTK (16 digit)" required
                            inputmode="numeric" pattern="\d{16,18}" minlength="16" maxlength="18"
                            oninput="checkTambahNip()"
                            class="w-full border border-gray-300 rounded-xl px-4 py-3 transition-colors">
                        <p id="tambahNipFeedback" class="text-xs mt-1">
                            <span class="text-gray-400">Isi NUPTK (16 digit) atau NIP (18 digit) angka.</span>
                        </p>
                    </div>

                    <div>
                        <label class="block text-sm font-medium text-gray-700 mb-1">Email</label>
                        <input type="email" name="email" placeholder="Email" required
                            class="w-full border rounded-xl px-4 py-3">
                    </div>

                    <div>
                        <label class="block text-sm font-medium text-gray-700 mb-1">No HP</label>
                        <input type="text" id="tambahPhone" name="phone" placeholder="No HP" required
                            inputmode="numeric" pattern="\d{9,15}"
                            oninput="checkTambahPhone()"
                            class="w-full border border-gray-300 rounded-xl px-4 py-3 transition-colors">
                        <p id="tambahPhoneFeedback" class="text-xs mt-1">
                            <span class="text-gray-400">Nomor HP harus 9-15 digit angka.</span>
                        </p>
                    </div>

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
                <div class="p-5 border-t flex justify-end gap-3">

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

    {{-- MODAL DETAIL --}}
    <div id="detailModal" class="fixed inset-0 bg-black/50 hidden items-center justify-center z-50 p-4">

        <div class="bg-white rounded-3xl w-full max-w-md overflow-hidden">

            {{-- Foto: background abu-abu + object-contain supaya foto apa pun rasionya tidak terpotong --}}
            <div class="w-full h-64 bg-gray-100 flex items-center justify-center">
                <img id="detailPhoto" class="max-h-64 w-full object-contain">
            </div>

            <div class="p-6 space-y-4">

                <div>
                    <h2 id="detailNama" class="text-2xl font-bold text-gray-800"></h2>
                    <span class="inline-block mt-1 text-xs font-medium bg-primary/10 text-primary px-3 py-1 rounded-full">
                        Guru
                    </span>
                </div>

                <div class="space-y-3 text-sm">

                    <div class="flex items-start gap-3">
                        <iconify-icon icon="solar:document-text-bold" class="text-gray-400 text-lg mt-0.5"></iconify-icon>
                        <div>
                            <p id="detailNipLabel" class="text-xs text-gray-400">NIP / NUPTK</p>
                            <p id="detailNip" class="text-gray-700 font-medium"></p>
                        </div>
                    </div>

                    <div class="flex items-start gap-3">
                        <iconify-icon icon="solar:letter-bold" class="text-gray-400 text-lg mt-0.5"></iconify-icon>
                        <div>
                            <p class="text-xs text-gray-400">Email</p>
                            <p id="detailEmail" class="text-gray-700 font-medium"></p>
                        </div>
                    </div>

                    <div class="flex items-start gap-3">
                        <iconify-icon icon="solar:phone-bold" class="text-gray-400 text-lg mt-0.5"></iconify-icon>
                        <div>
                            <p class="text-xs text-gray-400">No HP</p>
                            <p id="detailPhone" class="text-gray-700 font-medium"></p>
                        </div>
                    </div>

                </div>

                <div class="flex justify-end pt-2">

                    <button onclick="closeDetailModal()" class="bg-primary text-white px-5 py-2 rounded-xl">

                        Tutup

                    </button>

                </div>

            </div>

        </div>

    </div>

    {{-- MODAL EDIT --}}
    <div id="editModal" class="fixed inset-0 bg-black/50 hidden items-center justify-center z-50 p-4 overflow-y-auto">

        <div class="bg-white rounded-3xl w-full max-w-xl my-10">

            {{-- HEADER --}}
            <div class="flex justify-between items-center p-5 border-b">

                <h2 class="font-bold text-lg">
                    Edit Guru
                </h2>

                <button onclick="closeEditModal()">

                    <iconify-icon icon="solar:close-circle-bold" width="28">
                    </iconify-icon>

                </button>

            </div>

            {{-- FORM --}}
            <form id="editForm" method="POST" enctype="multipart/form-data">

                @csrf
                @method('PUT')

                <div class="p-5 space-y-4 max-h-[70vh] overflow-y-auto">

                    {{-- FOTO --}}
                    <div>
                        <label class="block text-sm font-medium text-gray-700 mb-1">Foto Guru</label>

                        {{-- Background abu-abu + object-contain supaya foto tidak terpotong walau rasionya beda --}}
                        <div class="w-full h-48 bg-gray-100 rounded-xl border flex items-center justify-center overflow-hidden mb-2">
                            <img id="editPreview" class="max-h-48 w-full object-contain">
                        </div>

                        <input type="file" name="photo" accept="image/*" onchange="previewEdit(event)"
                            class="w-full border rounded-xl p-3">
                    </div>

                    {{-- NAMA --}}
                    <div>
                        <label class="block text-sm font-medium text-gray-700 mb-1">Nama Guru</label>
                        <input type="text" id="editNama" name="name" required minlength="3" maxlength="100"
                            class="w-full border rounded-xl px-4 py-3">
                    </div>

                    {{-- NIP / NUPTK --}}
                    <div>
                        <label class="block text-sm font-medium text-gray-700 mb-1">NIP / NUPTK</label>
                        <input type="text" id="editNip" name="nip" placeholder="NIP (18 digit) atau NUPTK (16 digit)" required
                            inputmode="numeric" pattern="\d{16,18}" minlength="16" maxlength="18"
                            oninput="checkEditNip()"
                            class="w-full border border-gray-300 rounded-xl px-4 py-3 transition-colors">
                        <p id="editNipFeedback" class="text-xs mt-1">
                            <span class="text-gray-400">Isi NUPTK (16 digit) atau NIP (18 digit) angka.</span>
                        </p>
                    </div>

                    {{-- EMAIL --}}
                    <div>
                        <label class="block text-sm font-medium text-gray-700 mb-1">Email</label>
                        <input type="email" id="editEmail" name="email" required
                            class="w-full border rounded-xl px-4 py-3">
                    </div>

                    {{-- NO HP --}}
                    <div>
                        <label class="block text-sm font-medium text-gray-700 mb-1">No HP</label>
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
                <div class="p-5 border-t flex justify-end gap-3">

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
                    Import Excel Guru
                </h2>

                <button type="button" onclick="closeImportModal()">
                    <iconify-icon icon="solar:close-circle-bold" width="28"></iconify-icon>
                </button>

            </div>

            {{-- FORM --}}
            <form action="{{ route('admin.guru.import') }}" method="POST" enctype="multipart/form-data">

                @csrf

                <div class="p-5 space-y-4">

                    <div class="bg-yellow-50 border border-yellow-200 rounded-xl p-4">

                        <p class="font-semibold">
                            Format kolom:
                        </p>

                        <p class="text-sm mt-2">
                            name | nip (16 digit NUPTK atau 18 digit NIP) | email | phone | password (min. 8 karakter)
                        </p>

                        <a href="{{ route('admin.guru.template') }}"
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

    <script>
        // ================= TAMBAH =================

        function openTambahModal() {

            document.getElementById('tambahModal')
                .classList.remove('hidden');

            document.getElementById('tambahModal')
                .classList.add('flex');

        }

        function closeTambahModal() {

            document.getElementById('tambahModal')
                .classList.add('hidden');

        }

        function previewTambah(event) {

            if (!event.target.files || !event.target.files[0]) return;

            let img = document.getElementById('previewTambah');

            img.src = URL.createObjectURL(event.target.files[0]);

            document.getElementById('previewTambahWrapper')
                .classList.remove('hidden');

        }

        // ================= VALIDASI REALTIME (TAMBAH GURU) =================

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

        // Helper: cek & tampilkan feedback untuk field NIP/NUPTK (dipakai di Tambah & Edit)
        function evaluateNipNuptk(input, feedback) {

            // Hanya izinkan angka, maksimal 18 digit
            input.value = input.value.replace(/\D/g, '').slice(0, 18);

            const val = input.value;

            if (val.length === 0) {

                setFieldStatus(input, 'empty');

                feedback.innerHTML =
                    '<span class="text-gray-400">Isi NUPTK (16 digit) atau NIP (18 digit) angka.</span>';

            } else if (val.length === 16) {

                setFieldStatus(input, 'valid');

                feedback.innerHTML =
                    `<iconify-icon icon="solar:check-circle-bold" class="text-green-600"></iconify-icon>
                     <span class="text-green-600">Pas 16 digit, terdeteksi sebagai NUPTK</span>`;

            } else if (val.length === 18) {

                setFieldStatus(input, 'valid');

                feedback.innerHTML =
                    `<iconify-icon icon="solar:check-circle-bold" class="text-green-600"></iconify-icon>
                     <span class="text-green-600">Pas 18 digit, terdeteksi sebagai NIP</span>`;

            } else if (val.length < 16) {

                setFieldStatus(input, 'invalid');

                feedback.innerHTML =
                    `<span class="text-red-500">Tambahkan ${16 - val.length} digit lagi untuk NUPTK (saat ini ${val.length}/16)</span>`;

            } else if (val.length === 17) {

                setFieldStatus(input, 'invalid');

                feedback.innerHTML =
                    `<span class="text-red-500">17 digit belum pas. Kurangi 1 digit untuk NUPTK (16) atau tambah 1 digit untuk NIP (18)</span>`;

            } else {

                setFieldStatus(input, 'invalid');

                feedback.innerHTML =
                    `<span class="text-red-500">Maksimal 18 digit.</span>`;

            }

        }

        // ---- PASSWORD ----
        const passwordChecks = [
            {
                id: 'pwLenCheck',
                test: (v) => v.length >= 8,
                missing: 'Tambahkan minimal 8 karakter',
                done: 'Sudah 8 karakter atau lebih',
            },
            {
                id: 'pwUpperCheck',
                test: (v) => /[A-Z]/.test(v),
                missing: 'Tambahkan huruf besar (A-Z)',
                done: 'Sudah ada huruf besar',
            },
            {
                id: 'pwLowerCheck',
                test: (v) => /[a-z]/.test(v),
                missing: 'Tambahkan huruf kecil (a-z)',
                done: 'Sudah ada huruf kecil',
            },
            {
                id: 'pwNumberCheck',
                test: (v) => /[0-9]/.test(v),
                missing: 'Tambahkan angka (0-9)',
                done: 'Sudah ada angka',
            },
        ];

        function checkTambahPassword() {

            const input = document.getElementById('tambahPassword');
            const val = input.value;
            let allValid = true;

            passwordChecks.forEach((item) => {

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

            if (val.length === 0) {
                setFieldStatus(input, 'empty');
            } else if (allValid) {
                setFieldStatus(input, 'valid');
            } else {
                setFieldStatus(input, 'invalid');
            }

        }

        // ---- NIP / NUPTK (16-18 digit) - TAMBAH ----
        function checkTambahNip() {

            const input = document.getElementById('tambahNip');
            const feedback = document.getElementById('tambahNipFeedback');

            evaluateNipNuptk(input, feedback);

        }

        // ---- NO HP (9-15 digit) ----
        function checkTambahPhone() {

            const input = document.getElementById('tambahPhone');
            const feedback = document.getElementById('tambahPhoneFeedback');

            // Hanya izinkan angka, maksimal 15 digit
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

        // ================= DETAIL =================

        function openDetailModal(name, nip, email, phone, photo) {

            document.getElementById('detailNama').innerText = name;
            document.getElementById('detailNip').innerText = nip;
            document.getElementById('detailEmail').innerText = email;
            document.getElementById('detailPhone').innerText = phone;
            document.getElementById('detailPhoto').src = photo;

            // Label otomatis: 16 digit = NUPTK, selain itu = NIP
            document.getElementById('detailNipLabel').innerText =
                String(nip).length === 16 ? 'NUPTK' : 'NIP';

            document.getElementById('detailModal')
                .classList.remove('hidden');

            document.getElementById('detailModal')
                .classList.add('flex');

        }

        function closeDetailModal() {

            document.getElementById('detailModal')
                .classList.add('hidden');

        }

        // ================= VALIDASI REALTIME (EDIT GURU) =================

        // ---- PASSWORD (opsional saat edit) ----
        function checkEditPassword() {

            const input = document.getElementById('editPassword');
            const checklist = document.getElementById('editPwChecklist');
            const val = input.value;

            // Checklist hanya muncul begitu user mulai mengetik password baru
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

            let allValid = true;

            editPasswordChecks.forEach((item) => {

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

            setFieldStatus(input, allValid ? 'valid' : 'invalid');

        }

        // ---- NIP / NUPTK (16-18 digit) - EDIT ----
        function checkEditNip() {

            const input = document.getElementById('editNip');
            const feedback = document.getElementById('editNipFeedback');

            evaluateNipNuptk(input, feedback);

        }

        // ---- NO HP (9-15 digit) ----
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

        function openEditModal(id, name, nip, email, phone, photo) {

            document.getElementById('editForm').action =
                `/admin/guru/${id}`;

            document.getElementById('editNama').value = name;
            document.getElementById('editNip').value = nip;
            document.getElementById('editEmail').value = email;
            document.getElementById('editPhone').value = phone;
            document.getElementById('editPreview').src = photo;

            // Reset password baru setiap modal dibuka ulang
            document.getElementById('editPassword').value = '';
            document.getElementById('editPwChecklist').classList.add('hidden');
            setFieldStatus(document.getElementById('editPassword'), 'empty');

            // Sinkronkan status warna NIP/NUPTK & No HP dengan data yang sudah terisi
            checkEditNip();
            checkEditPhone();

            document.getElementById('editModal')
                .classList.remove('hidden');

            document.getElementById('editModal')
                .classList.add('flex');

        }

        function closeEditModal() {

            document.getElementById('editModal')
                .classList.add('hidden');

        }

        function previewEdit(event) {

            let img = document.getElementById('editPreview');

            img.src = URL.createObjectURL(event.target.files[0]);

        }

        // ================= DELETE =================

        function confirmDelete(id) {

            Swal.fire({
                title: 'Hapus Guru?',
                text: 'Data yang dihapus tidak dapat dikembalikan.',
                icon: 'warning',
                showCancelButton: true,
                confirmButtonColor: '#dc2626',
                cancelButtonColor: '#6b7280',
                confirmButtonText: 'Ya, Hapus',
                cancelButtonText: 'Batal'
            }).then((result) => {

                if (result.isConfirmed) {

                    document
                        .getElementById(`deleteForm${id}`)
                        .submit();

                }

            });

        }

        // ================= IMPORT =================

        function openImportModal() {

            document.getElementById('importModal')
                .classList.remove('hidden');

            document.getElementById('importModal')
                .classList.add('flex');

        }

        function closeImportModal() {

            document.getElementById('importModal')
                .classList.add('hidden');

        }
    </script>

@endsection

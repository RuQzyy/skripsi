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
                Kelola seluruh data siswa MAN Ambon
            </p>

        </div>

        <button
            onclick="openTambahModal()"
            class="bg-primary hover:bg-secondary text-white px-5 py-3 rounded-xl flex items-center gap-2">

            <iconify-icon icon="solar:add-circle-bold"></iconify-icon>

            Tambah Siswa

        </button>

    </div>

    {{-- FILTER --}}
    <div class="bg-white p-5 rounded-2xl shadow-sm">

        <form method="GET">

            <div class="grid grid-cols-1 md:grid-cols-3 gap-4">

                {{-- SEARCH --}}
                <div class="relative">

                    <iconify-icon
                        icon="solar:magnifer-linear"
                        class="absolute left-4 top-1/2 -translate-y-1/2 text-gray-400">
                    </iconify-icon>

                    <input
                        type="text"
                        name="search"
                        value="{{ request('search') }}"
                        placeholder="Cari nama atau NISN..."
                        class="w-full border rounded-xl pl-12 pr-4 py-3 focus:outline-none focus:ring-2 focus:ring-primary">

                </div>

                {{-- FILTER KELAS --}}
                <select
                    name="kelas"
                    class="w-full border rounded-xl px-4 py-3 focus:outline-none focus:ring-2 focus:ring-primary">

                    <option value="">
                        Semua Kelas
                    </option>

                    @foreach($listKelas as $kelas)

                        <option
                            value="{{ $kelas }}"
                            {{ request('kelas') == $kelas ? 'selected' : '' }}>

                            {{ strtoupper($kelas) }}

                        </option>

                    @endforeach

                </select>

                {{-- BUTTON --}}
                <button
                    class="bg-primary hover:bg-secondary text-white rounded-xl px-4 py-3">

                    Filter Data

                </button>

            </div>

        </form>

    </div>

    {{-- SUCCESS --}}
    @if(session('success'))

        <script>
            Swal.fire({
                icon: 'success',
                title: 'Berhasil',
                text: '{{ session('success') }}',
                timer: 2000,
                showConfirmButton: false
            });
        </script>

    @endif

    {{-- LIST SISWA --}}
    <div class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-5">

        @forelse($siswa as $item)

            <div class="bg-white rounded-2xl shadow-sm overflow-hidden hover:shadow-lg transition">

                {{-- FOTO --}}
                <div class="relative">

                    <img
                        src="{{ $item->photo == 'default.png'
                            ? asset('images/default.png')
                            : asset('storage/siswa/' . $item->photo) }}"
                        class="w-full h-52 object-cover">

                    <div class="absolute top-3 right-3 bg-primary text-white text-xs px-3 py-1 rounded-full">

                        {{ strtoupper($item->kelas) }}

                    </div>

                </div>

                {{-- CONTENT --}}
                <div class="p-4">

                    <h3 class="font-bold text-gray-800 text-lg">

                        {{ $item->name }}

                    </h3>

                    <div class="space-y-2 mt-3 text-sm text-gray-500">

                        <div class="flex items-center gap-2">

                            <iconify-icon icon="solar:user-id-bold"></iconify-icon>

                            {{ $item->nisn }}

                        </div>

                        <div class="flex items-center gap-2">

                            <iconify-icon icon="solar:letter-bold"></iconify-icon>

                            <span class="truncate">
                                {{ $item->email }}
                            </span>

                        </div>

                        <div class="flex items-center gap-2">

                            <iconify-icon icon="solar:phone-bold"></iconify-icon>

                            {{ $item->phone }}

                        </div>

                    </div>

                    {{-- BUTTON --}}
                    <div class="grid grid-cols-2 gap-3 mt-5">

                        {{-- EDIT --}}
                        <button
                            onclick="openEditModal(
                                '{{ $item->id }}',
                                @js($item->name),
                                '{{ $item->nisn }}',
                                '{{ $item->kelas }}',
                                '{{ $item->email }}',
                                '{{ $item->phone }}',
                                '{{ $item->photo == 'default.png'
                                    ? asset('images/default.png')
                                    : asset('storage/siswa/' . $item->photo) }}'
                            )"
                            class="bg-yellow-500 hover:bg-yellow-600 text-white py-2 rounded-xl">

                            Edit

                        </button>

                        {{-- DELETE --}}
                        <form
                            id="deleteForm{{ $item->id }}"
                            action="{{ route('admin.siswa.destroy', $item->id) }}"
                            method="POST">

                            @csrf
                            @method('DELETE')

                            <button
                                type="button"
                                onclick="confirmDelete({{ $item->id }})"
                                class="w-full bg-red-500 hover:bg-red-600 text-white py-2 rounded-xl">

                                Hapus

                            </button>

                        </form>

                    </div>

                </div>

            </div>

        @empty

            <div class="col-span-full">

                <div class="bg-white rounded-2xl p-10 text-center">

                    <iconify-icon
                        icon="solar:users-group-rounded-bold"
                        width="70"
                        class="text-gray-300">
                    </iconify-icon>

                    <h3 class="mt-4 font-semibold text-gray-700">
                        Data siswa belum tersedia
                    </h3>

                </div>

            </div>

        @endforelse

    </div>

</div>

{{-- MODAL TAMBAH --}}
<div
    id="tambahModal"
    class="fixed inset-0 bg-black/50 hidden items-center justify-center z-50 p-4">

    <div class="bg-white rounded-3xl w-full max-w-md overflow-hidden max-h-[90vh] flex flex-col">

        {{-- HEADER --}}
        <div class="flex justify-between items-center p-5 border-b">

            <h2 class="font-bold text-lg">
                Tambah Siswa
            </h2>

            <button onclick="closeTambahModal()">

                <iconify-icon
                    icon="solar:close-circle-bold"
                    width="28">
                </iconify-icon>

            </button>

        </div>

        {{-- FORM --}}
        <form
            action="{{ route('admin.siswa.store') }}"
            method="POST"
            enctype="multipart/form-data"
            class="flex flex-col flex-1 overflow-hidden">

            @csrf

            <div class="p-5 space-y-4 overflow-y-auto flex-1">

                <img
                    id="previewTambah"
                    class="hidden w-full h-40 rounded-xl object-cover border">

                <input
                    type="file"
                    name="photo"
                    accept="image/*"
                    onchange="previewTambah(event)"
                    class="w-full border rounded-xl p-3">

                <input
                    type="text"
                    name="name"
                    placeholder="Nama Siswa"
                    required
                    class="w-full border rounded-xl px-4 py-3">

                <input
                    type="text"
                    name="nisn"
                    placeholder="NISN"
                    required
                    class="w-full border rounded-xl px-4 py-3">

                <input
                    type="text"
                    name="kelas"
                    placeholder="Kelas"
                    required
                    class="w-full border rounded-xl px-4 py-3">

                <input
                    type="email"
                    name="email"
                    placeholder="Email"
                    required
                    class="w-full border rounded-xl px-4 py-3">

                <input
                    type="text"
                    name="phone"
                    placeholder="Nomor HP"
                    required
                    class="w-full border rounded-xl px-4 py-3">

                <input
                    type="password"
                    name="password"
                    placeholder="Password"
                    required
                    class="w-full border rounded-xl px-4 py-3">

            </div>

            {{-- FOOTER --}}
            <div class="p-5 border-t flex justify-end gap-3 bg-gray-50">

                <button
                    type="button"
                    onclick="closeTambahModal()"
                    class="px-5 py-2 border rounded-xl">

                    Batal

                </button>

                <button
                    type="submit"
                    class="bg-primary text-white px-5 py-2 rounded-xl">

                    Simpan

                </button>

            </div>

        </form>

    </div>

</div>

{{-- MODAL EDIT --}}
<div
    id="editModal"
    class="fixed inset-0 bg-black/50 hidden items-center justify-center z-50 p-4">

    <div class="bg-white rounded-3xl w-full max-w-md overflow-hidden max-h-[90vh] flex flex-col">

        {{-- HEADER --}}
        <div class="flex justify-between items-center p-5 border-b">

            <h2 class="font-bold text-lg">
                Edit Siswa
            </h2>

            <button onclick="closeEditModal()">

                <iconify-icon
                    icon="solar:close-circle-bold"
                    width="28">
                </iconify-icon>

            </button>

        </div>

        {{-- FORM --}}
        <form
            id="editForm"
            method="POST"
            enctype="multipart/form-data"
            class="flex flex-col flex-1 overflow-hidden">

            @csrf
            @method('PUT')

            <div class="p-5 space-y-4 overflow-y-auto flex-1">

                <img
                    id="editPreview"
                    class="w-full h-40 rounded-xl object-cover border">

                <input
                    type="file"
                    name="photo"
                    accept="image/*"
                    onchange="previewEdit(event)"
                    class="w-full border rounded-xl p-3">

                <input
                    type="text"
                    id="editName"
                    name="name"
                    required
                    class="w-full border rounded-xl px-4 py-3">

                <input
                    type="text"
                    id="editNisn"
                    name="nisn"
                    required
                    class="w-full border rounded-xl px-4 py-3">

                <input
                    type="text"
                    id="editKelas"
                    name="kelas"
                    required
                    class="w-full border rounded-xl px-4 py-3">

                <input
                    type="email"
                    id="editEmail"
                    name="email"
                    required
                    class="w-full border rounded-xl px-4 py-3">

                <input
                    type="text"
                    id="editPhone"
                    name="phone"
                    required
                    class="w-full border rounded-xl px-4 py-3">

            </div>

            {{-- FOOTER --}}
            <div class="p-5 border-t flex justify-end gap-3 bg-gray-50">

                <button
                    type="button"
                    onclick="closeEditModal()"
                    class="px-5 py-2 border rounded-xl">

                    Batal

                </button>

                <button
                    type="submit"
                    class="bg-yellow-500 text-white px-5 py-2 rounded-xl">

                    Update

                </button>

            </div>

        </form>

    </div>

</div>

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

        let img =
            document.getElementById('previewTambah');

        img.src =
            URL.createObjectURL(event.target.files[0]);

        img.classList.remove('hidden');
    }

    // ================= EDIT =================

    function openEditModal(
        id,
        name,
        nisn,
        kelas,
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
            .value = kelas;

        document
            .getElementById('editEmail')
            .value = email;

        document
            .getElementById('editPhone')
            .value = phone;

        document
            .getElementById('editPreview')
            .src = photo;

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

</script>

@endsection

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
                Kelola seluruh data guru MAN Ambon
            </p>

        </div>

        <button
            onclick="openTambahModal()"
            class="bg-primary hover:bg-secondary text-white px-5 py-3 rounded-xl flex items-center gap-2">

            <iconify-icon icon="solar:add-circle-bold"></iconify-icon>

            Tambah Guru

        </button>

    </div>

    {{-- FILTER --}}
    <div class="bg-white rounded-2xl p-5 shadow-sm">

        <form method="GET">

            <div class="grid grid-cols-1 md:grid-cols-3 gap-4">

                {{-- SEARCH --}}
                <div class="relative">

                    <iconify-icon
                        icon="solar:magnifer-outline"
                        class="absolute left-4 top-1/2 -translate-y-1/2 text-gray-400">
                    </iconify-icon>

                    <input
                        type="text"
                        name="search"
                        value="{{ request('search') }}"
                        placeholder="Cari nama / nip..."
                        class="w-full border rounded-xl pl-12 pr-4 py-3 focus:outline-none focus:ring-2 focus:ring-primary">

                </div>

                {{-- BUTTON --}}
                <button
                    class="bg-primary hover:bg-secondary text-white rounded-xl px-5 py-3">

                    Filter Data

                </button>

            </div>

        </form>

    </div>

    {{-- TABLE --}}
    <div class="bg-white rounded-2xl shadow-sm overflow-hidden">

        <div class="overflow-x-auto">

            <table class="w-full">

                <thead class="bg-gray-50">

                    <tr class="text-left text-sm text-gray-600">

                        <th class="px-6 py-4">
                            Foto
                        </th>

                        <th class="px-6 py-4">
                            Nama
                        </th>

                        <th class="px-6 py-4">
                            NIP
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

                                <img
                                    src="{{ asset('storage/guru/' . $item->photo) }}"
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
                                    <form
                                        id="deleteForm{{ $item->id }}"
                                        action="{{ route('admin.guru.destroy', $item->id) }}"
                                        method="POST">

                                        @csrf
                                        @method('DELETE')

                                        <button
                                            type="button"
                                            onclick="confirmDelete({{ $item->id }})"
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

                                <iconify-icon
                                    icon="solar:user-cross-outline"
                                    width="70"
                                    class="text-gray-300">
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

    </div>

</div>

{{-- MODAL TAMBAH --}}
<div id="tambahModal"
    class="fixed inset-0 bg-black/50 hidden items-center justify-center z-50 p-4 overflow-y-auto">

    <div class="bg-white rounded-3xl w-full max-w-xl my-10">

        {{-- HEADER --}}
        <div class="flex justify-between items-center p-5 border-b">

            <h2 class="font-bold text-lg">
                Tambah Guru
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
            action="{{ route('admin.guru.store') }}"
            method="POST"
            enctype="multipart/form-data">

            @csrf

            <div class="p-5 space-y-4 max-h-[70vh] overflow-y-auto">

                <input
                    type="file"
                    name="photo"
                    accept="image/*"
                    onchange="previewTambah(event)"
                    class="w-full border rounded-xl p-3">

                <img
                    id="previewTambah"
                    class="hidden rounded-xl h-48 object-cover w-full">

                <input
                    type="text"
                    name="name"
                    placeholder="Nama Guru"
                    required
                    class="w-full border rounded-xl px-4 py-3">

                <input
                    type="text"
                    name="nip"
                    placeholder="NIP"
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
                    placeholder="No HP"
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
            <div class="p-5 border-t flex justify-end gap-3">

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

{{-- MODAL DETAIL --}}
<div id="detailModal"
    class="fixed inset-0 bg-black/50 hidden items-center justify-center z-50 p-4">

    <div class="bg-white rounded-3xl w-full max-w-md overflow-hidden">

        <img
            id="detailPhoto"
            class="w-full h-64 object-cover">

        <div class="p-6 space-y-3">

            <h2
                id="detailNama"
                class="text-2xl font-bold text-gray-800">
            </h2>

            <div class="space-y-2 text-sm text-gray-600">

                <p>
                    <span class="font-semibold">NIP :</span>
                    <span id="detailNip"></span>
                </p>

                <p>
                    <span class="font-semibold">Email :</span>
                    <span id="detailEmail"></span>
                </p>

                <p>
                    <span class="font-semibold">No HP :</span>
                    <span id="detailPhone"></span>
                </p>

            </div>

            <div class="flex justify-end pt-4">

                <button
                    onclick="closeDetailModal()"
                    class="bg-primary text-white px-5 py-2 rounded-xl">

                    Tutup

                </button>

            </div>

        </div>

    </div>

</div>

{{-- MODAL EDIT --}}
<div id="editModal"
    class="fixed inset-0 bg-black/50 hidden items-center justify-center z-50 p-4 overflow-y-auto">

    <div class="bg-white rounded-3xl w-full max-w-xl my-10">

        {{-- HEADER --}}
        <div class="flex justify-between items-center p-5 border-b">

            <h2 class="font-bold text-lg">
                Edit Guru
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
            enctype="multipart/form-data">

            @csrf
            @method('PUT')

            <div class="p-5 space-y-4 max-h-[70vh] overflow-y-auto">

                <input
                    type="file"
                    name="photo"
                    accept="image/*"
                    onchange="previewEdit(event)"
                    class="w-full border rounded-xl p-3">

                <img
                    id="editPreview"
                    class="rounded-xl h-48 object-cover w-full">

                <input
                    type="text"
                    id="editNama"
                    name="name"
                    required
                    class="w-full border rounded-xl px-4 py-3">

                <input
                    type="text"
                    id="editNip"
                    name="nip"
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

                <input
                    type="password"
                    name="password"
                    placeholder="Password baru (opsional)"
                    class="w-full border rounded-xl px-4 py-3">

            </div>

            {{-- FOOTER --}}
            <div class="p-5 border-t flex justify-end gap-3">

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

        let img = document.getElementById('previewTambah');

        img.src = URL.createObjectURL(event.target.files[0]);

        img.classList.remove('hidden');

    }

    // ================= DETAIL =================

    function openDetailModal(name, nip, email, phone, photo) {

        document.getElementById('detailNama').innerText = name;
        document.getElementById('detailNip').innerText = nip;
        document.getElementById('detailEmail').innerText = email;
        document.getElementById('detailPhone').innerText = phone;
        document.getElementById('detailPhoto').src = photo;

        document.getElementById('detailModal')
            .classList.remove('hidden');

        document.getElementById('detailModal')
            .classList.add('flex');

    }

    function closeDetailModal() {

        document.getElementById('detailModal')
            .classList.add('hidden');

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

</script>

@endsection

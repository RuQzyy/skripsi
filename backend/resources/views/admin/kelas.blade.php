@extends('admin.layouts.app')

@section('title', 'Data Kelas')
@section('page-title', 'Data Kelas')

@section('content')

<script src="https://code.iconify.design/iconify-icon/1.0.8/iconify-icon.min.js"></script>

<div class="space-y-6">

    {{-- HEADER --}}
    <div class="flex items-center justify-between">

        <div>

            <h1 class="text-2xl font-bold text-gray-800">
                Data Kelas
            </h1>

            <p class="text-sm text-gray-500">
                Kelola data kelas dan wali kelas
            </p>

        </div>

        <button
            onclick="openTambahModal()"
            class="bg-primary hover:bg-secondary text-white px-5 py-3 rounded-xl flex items-center gap-2">

            <iconify-icon icon="solar:add-circle-bold"></iconify-icon>

            Tambah Kelas

        </button>

    </div>

    {{-- TABLE --}}
    <div class="bg-white rounded-2xl shadow-sm overflow-hidden">

        <div class="overflow-x-auto">

            <table class="w-full text-sm">

                <thead class="bg-gray-50">

                    <tr>

                        <th class="px-6 py-4 text-left font-semibold text-gray-600">
                            No
                        </th>

                        <th class="px-6 py-4 text-left font-semibold text-gray-600">
                            Nama Kelas
                        </th>

                        <th class="px-6 py-4 text-left font-semibold text-gray-600">
                            Wali Kelas
                        </th>

                        <th class="px-6 py-4 text-center font-semibold text-gray-600">
                            Aksi
                        </th>

                    </tr>

                </thead>

                <tbody>

                    @forelse($kelas as $item)

                        <tr class="border-t hover:bg-gray-50">

                            <td class="px-6 py-4">
                                {{ $loop->iteration }}
                            </td>

                            <td class="px-6 py-4 font-medium text-gray-800">
                                {{ $item->nama_kelas }}
                            </td>

                            <td class="px-6 py-4">

                                @if($item->waliKelas)

                                    <div class="flex items-center gap-3">

                                        <img
                                            src="{{ asset('storage/guru/' . $item->waliKelas->photo) }}"
                                            class="w-10 h-10 rounded-full object-cover border">

                                        <div>

                                            <p class="font-semibold text-gray-800">
                                                {{ $item->waliKelas->name }}
                                            </p>

                                            <p class="text-xs text-gray-500">
                                                {{ $item->waliKelas->nip }}
                                            </p>

                                        </div>

                                    </div>

                                @else

                                    <span class="text-gray-400 italic">
                                        Belum ada wali kelas
                                    </span>

                                @endif

                            </td>

                            <td class="px-6 py-4">

                                <div class="flex justify-center gap-2">

                                    {{-- EDIT --}}
                                    <button
                                        onclick="openEditModal(
                                            '{{ $item->id }}',
                                            '{{ $item->nama_kelas }}',
                                            '{{ $item->wali_kelas_id }}'
                                        )"
                                        class="bg-yellow-500 hover:bg-yellow-600 text-white px-4 py-2 rounded-lg text-sm">

                                        Edit

                                    </button>

                                    {{-- DELETE --}}
                                    <form
                                        id="deleteForm{{ $item->id }}"
                                        action="{{ route('admin.kelas.destroy', $item->id) }}"
                                        method="POST">

                                        @csrf
                                        @method('DELETE')

                                        <button
                                            type="button"
                                            onclick="confirmDelete({{ $item->id }})"
                                            class="bg-red-500 hover:bg-red-600 text-white px-4 py-2 rounded-lg text-sm">

                                            Hapus

                                        </button>

                                    </form>

                                </div>

                            </td>

                        </tr>

                    @empty

                        <tr>

                            <td colspan="4" class="text-center py-14">

                                <iconify-icon
                                    icon="solar:folder-open-outline"
                                    width="70"
                                    class="text-gray-300">
                                </iconify-icon>

                                <h3 class="mt-4 font-semibold text-gray-700">
                                    Belum ada data kelas
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
<div
    id="tambahModal"
    class="fixed inset-0 bg-black/50 hidden items-center justify-center z-50 p-4">

    <div class="bg-white rounded-2xl w-full max-w-md">

        <div class="flex items-center justify-between p-5 border-b">

            <h2 class="font-bold text-lg">
                Tambah Kelas
            </h2>

            <button onclick="closeTambahModal()">

                <iconify-icon
                    icon="solar:close-circle-bold"
                    width="26">
                </iconify-icon>

            </button>

        </div>

        <form action="{{ route('admin.kelas.store') }}" method="POST">

            @csrf

            <div class="p-5 space-y-4">

                <div>

                    <label class="text-sm font-medium text-gray-700">
                        Nama Kelas
                    </label>

                    <input
                        type="text"
                        name="nama_kelas"
                        required
                        class="w-full border rounded-xl px-4 py-3 mt-1">

                </div>

                <div>

                    <label class="text-sm font-medium text-gray-700">
                        Wali Kelas
                    </label>

                    <select
                        name="wali_kelas_id"
                        class="w-full border rounded-xl px-4 py-3 mt-1">

                        <option value="">
                            -- Pilih Wali Kelas --
                        </option>

                        @foreach($guru as $g)

                            <option value="{{ $g->id }}">

                                {{ $g->name }} - {{ $g->nip }}

                            </option>

                        @endforeach

                    </select>

                </div>

            </div>

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

{{-- MODAL EDIT --}}
<div
    id="editModal"
    class="fixed inset-0 bg-black/50 hidden items-center justify-center z-50 p-4">

    <div class="bg-white rounded-2xl w-full max-w-md">

        <div class="flex items-center justify-between p-5 border-b">

            <h2 class="font-bold text-lg">
                Edit Kelas
            </h2>

            <button onclick="closeEditModal()">

                <iconify-icon
                    icon="solar:close-circle-bold"
                    width="26">
                </iconify-icon>

            </button>

        </div>

        <form
            id="editForm"
            method="POST">

            @csrf
            @method('PUT')

            <div class="p-5 space-y-4">

                <div>

                    <label class="text-sm font-medium text-gray-700">
                        Nama Kelas
                    </label>

                    <input
                        type="text"
                        id="editNamaKelas"
                        name="nama_kelas"
                        required
                        class="w-full border rounded-xl px-4 py-3 mt-1">

                </div>

                <div>

                    <label class="text-sm font-medium text-gray-700">
                        Wali Kelas
                    </label>

                    <select
                        id="editWaliKelas"
                        name="wali_kelas_id"
                        class="w-full border rounded-xl px-4 py-3 mt-1">

                        <option value="">
                            -- Pilih Wali Kelas --
                        </option>

                        @foreach($guru as $g)

                            <option value="{{ $g->id }}">

                                {{ $g->name }} - {{ $g->nip }}

                            </option>

                        @endforeach

                    </select>

                </div>

            </div>

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

    function openEditModal(id, nama, wali) {

        document
            .getElementById('editForm')
            .action = `/admin/kelas/${id}`;

        document
            .getElementById('editNamaKelas')
            .value = nama;

        document
            .getElementById('editWaliKelas')
            .value = wali;

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

    function confirmDelete(id) {

        Swal.fire({
            title: 'Hapus Kelas?',
            text: 'Data kelas akan dihapus permanen.',
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

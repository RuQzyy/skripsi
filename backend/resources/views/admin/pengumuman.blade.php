@extends('admin.layouts.app')

@section('title', 'Pengumuman')
@section('page-title', 'Pengumuman')

@section('content')

    <script src="https://code.iconify.design/iconify-icon/1.0.8/iconify-icon.min.js"></script>

    <div class="space-y-6">

        {{-- HEADER --}}
        <div class="flex justify-between items-center">

            <div>

                <h1 class="text-2xl font-bold text-gray-800">
                    Pengumuman
                </h1>

                <p class="text-gray-500 text-sm">
                    Kelola seluruh pengumuman aplikasi Smart Attendance MAN Ambon
                </p>

            </div>

            <button onclick="openTambahModal()"
                class="bg-primary hover:bg-secondary text-white px-5 py-3 rounded-xl flex items-center gap-2">

                <iconify-icon icon="solar:add-circle-bold"></iconify-icon>

                Tambah Pengumuman

            </button>

        </div>

        {{-- ALERT --}}
        @if (session('success'))
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

        {{-- LIST --}}
        <div class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-5">

            @forelse($pengumuman as $item)
                <div class="bg-white rounded-2xl shadow-sm overflow-hidden hover:shadow-lg transition">

                    <img src="{{ asset('storage/pengumuman/' . $item->foto) }}" class="w-full h-40 object-cover">

                    <div class="p-4">

                        <h3 class="font-semibold text-gray-800 line-clamp-2 min-h-[50px]">

                            {{ $item->judul }}

                        </h3>

                        <div class="flex items-center gap-2 text-xs text-gray-500 mt-2">

                            <iconify-icon icon="solar:calendar-bold"></iconify-icon>

                            {{ \Carbon\Carbon::parse($item->tanggal)->format('d M Y') }}

                        </div>

                        <div class="grid grid-cols-3 gap-2 mt-4">

                            {{-- DETAIL --}}
                            <button
                                onclick="openDetailModal(
                                @js($item->judul),
                                @js($item->deskripsi),
                                '{{ \Carbon\Carbon::parse($item->tanggal)->format('d M Y') }}',
                                '{{ asset('storage/pengumuman/' . $item->foto) }}'
                            )"
                                class="bg-blue-500 hover:bg-blue-600 text-white py-2 rounded-lg text-sm">

                                Detail

                            </button>

                            {{-- EDIT --}}
                            <button
                                onclick="openEditModal(
        '{{ $item->id }}',
        @js($item->judul),
        @js($item->deskripsi),
        '{{ $item->tanggal }}',
        '{{ asset('storage/pengumuman/' . $item->foto) }}'
    )"
                                class="bg-yellow-500 hover:bg-yellow-600 text-white py-2 rounded-lg text-sm">

                                Edit

                            </button>

                            {{-- DELETE --}}
                            <form id="deleteForm{{ $item->id }}"
                                action="{{ route('admin.pengumuman.destroy', $item->id) }}" method="POST">

                                @csrf
                                @method('DELETE')

                                <button type="button" onclick="confirmDelete({{ $item->id }})"
                                    class="w-full bg-red-500 hover:bg-red-600 text-white py-2 rounded-lg text-sm">

                                    Hapus

                                </button>

                            </form>

                        </div>

                    </div>

                </div>

            @empty

                <div class="col-span-full">

                    <div class="bg-white rounded-2xl p-12 text-center">

                        <iconify-icon icon="solar:document-text-outline" width="70" class="text-gray-300">
                        </iconify-icon>

                        <h3 class="mt-4 font-semibold text-gray-700">
                            Belum ada pengumuman
                        </h3>

                    </div>

                </div>
            @endforelse

        </div>

    </div>

    {{-- MODAL TAMBAH --}}
    <div id="tambahModal" class="fixed inset-0 bg-black/50 hidden items-center justify-center z-50 p-4">

        <div class="bg-white rounded-3xl w-full max-w-xl">

            <div class="flex justify-between items-center p-5 border-b">

                <h2 class="font-bold text-lg">
                    Tambah Pengumuman
                </h2>

                <button onclick="closeTambahModal()">

                    <iconify-icon icon="solar:close-circle-bold" width="28">
                    </iconify-icon>

                </button>

            </div>

            <form action="{{ route('admin.pengumuman.store') }}" method="POST" enctype="multipart/form-data">

                @csrf

                <div class="p-5 space-y-4">

                    <input type="file" name="foto" accept="image/*" onchange="previewTambah(event)"
                        class="w-full border rounded-xl p-3">

                    <img id="previewTambah" class="hidden rounded-xl h-48 object-cover w-full">

                    <input type="text" name="judul" placeholder="Judul Pengumuman" required
                        class="w-full border rounded-xl px-4 py-3">

                    <input type="date" name="tanggal" required class="w-full border rounded-xl px-4 py-3">

                    <textarea name="deskripsi" rows="5" placeholder="Deskripsi Pengumuman" required
                        class="w-full border rounded-xl px-4 py-3"></textarea>

                </div>

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

        <div class="bg-white rounded-3xl max-w-2xl w-full overflow-hidden">

            <img id="detailFoto" class="w-full h-72 object-cover">

            <div class="p-6">

                <h2 id="detailJudul" class="text-2xl font-bold text-gray-800">
                </h2>

                <p id="detailTanggal" class="text-sm text-gray-500 mt-2">
                </p>

                <div id="detailDeskripsi" class="mt-5 text-gray-700 leading-relaxed">
                </div>

                <div class="flex justify-end mt-6">

                    <button onclick="closeDetailModal()" class="bg-primary text-white px-5 py-2 rounded-xl">

                        Tutup

                    </button>

                </div>

            </div>

        </div>

    </div>

    <div id="editModal" class="fixed inset-0 bg-black/50 hidden items-center justify-center z-50 p-4">

        <div class="bg-white rounded-2xl w-full max-w-md shadow-2xl overflow-hidden flex flex-col max-h-[90vh]">

            {{-- HEADER --}}
            <div class="flex items-center justify-between px-5 py-4 border-b shrink-0">

                <h2 class="font-semibold text-gray-800">
                    Edit Pengumuman
                </h2>

                <button onclick="closeEditModal()" class="text-gray-400 hover:text-red-500 transition">

                    <iconify-icon icon="solar:close-circle-bold" width="26">
                    </iconify-icon>

                </button>

            </div>

            {{-- FORM --}}
            <form id="editForm" method="POST" enctype="multipart/form-data" class="flex flex-col flex-1 overflow-hidden">

                @csrf
                @method('PUT')

                {{-- CONTENT --}}
                <div class="p-5 space-y-4 overflow-y-auto flex-1">

                    <img id="editPreview" class="w-full h-40 object-cover rounded-xl border">

                    <input type="file" name="foto" accept="image/*" onchange="previewEdit(event)"
                        class="w-full border rounded-xl p-3 text-sm">

                    <input type="text" id="editJudul" name="judul" required
                        class="w-full border rounded-xl px-4 py-3 text-sm">

                    <input type="date" id="editTanggal" name="tanggal" required
                        class="w-full border rounded-xl px-4 py-3 text-sm">

                    <textarea id="editDeskripsi" name="deskripsi" rows="5" required
                        class="w-full border rounded-xl px-4 py-3 text-sm resize-none"></textarea>

                </div>

                {{-- FOOTER --}}
                <div class="px-5 py-4 border-t flex justify-end gap-3 bg-gray-50 shrink-0">

                    <button type="button" onclick="closeEditModal()" class="px-4 py-2 rounded-xl border">

                        Batal

                    </button>

                    <button type="submit" class="bg-yellow-500 hover:bg-yellow-600 text-white px-5 py-2 rounded-xl">

                        Update

                    </button>

                </div>

            </form>

        </div>

    </div>

    <script>
        function openTambahModal() {
            document.getElementById('tambahModal').classList.remove('hidden');
            document.getElementById('tambahModal').classList.add('flex');
        }

        function closeTambahModal() {
            document.getElementById('tambahModal').classList.add('hidden');
        }

        function previewTambah(event) {
            let img = document.getElementById('previewTambah');

            img.src = URL.createObjectURL(event.target.files[0]);

            img.classList.remove('hidden');
        }

        function openDetailModal(judul, deskripsi, tanggal, foto) {
            document.getElementById('detailJudul').innerText = judul;
            document.getElementById('detailDeskripsi').innerText = deskripsi;
            document.getElementById('detailTanggal').innerText = tanggal;
            document.getElementById('detailFoto').src = foto;

            document.getElementById('detailModal').classList.remove('hidden');
            document.getElementById('detailModal').classList.add('flex');
        }

        function closeDetailModal() {
            document.getElementById('detailModal').classList.add('hidden');
        }

        function openEditModal(id, judul, deskripsi, tanggal, foto) {
            document.getElementById('editForm').action =
                `/admin/pengumuman/${id}`;

            document.getElementById('editJudul').value =
                judul;

            document.getElementById('editDeskripsi').value =
                deskripsi;

            document.getElementById('editTanggal').value =
                tanggal;

            document.getElementById('editPreview').src =
                foto;

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

       function confirmDelete(id) {

    Swal.fire({
        title: 'Hapus Pengumuman?',
        text: 'Data yang dihapus tidak dapat dikembalikan.',
        icon: 'warning',
        showCancelButton: true,
        confirmButtonColor: '#dc2626',
        cancelButtonColor: '#6b7280',
        confirmButtonText: 'Ya, Hapus',
        cancelButtonText: 'Batal'
    }).then((result) => {

        if (result.isConfirmed) {

            const form = document.getElementById(`deleteForm${id}`);

            if (form) {
                form.submit();
            }

        }

    });

}
    </script>

@endsection

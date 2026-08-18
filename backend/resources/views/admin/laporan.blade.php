@extends('admin.layouts.app')

@section('title', 'Laporan Kehadiran')
@section('page-title', 'Laporan Kehadiran')

@section('content')

<script src="https://code.iconify.design/iconify-icon/1.0.8/iconify-icon.min.js"></script>

<div class="space-y-6">

    {{-- HEADER --}}
    <div class="flex flex-col md:flex-row md:items-center md:justify-between gap-4">

        <div>
            <h1 class="text-2xl font-bold text-gray-800">Laporan Kehadiran</h1>
            <p class="text-sm text-gray-500">Rekap kehadiran siswa seluruh kelas SMA 15 Ambon</p>
        </div>

        @if($rekap)
            <a href="{{ route('admin.laporan.downloadSemua', ['bulan_awal' => $bulanAwal, 'bulan_akhir' => $bulanAkhir]) }}"
               class="bg-primary hover:bg-secondary text-white px-5 py-3 rounded-xl flex items-center gap-2 w-fit">
                <iconify-icon icon="solar:download-minimalistic-bold"></iconify-icon>
                <span>Unduh Semua Kelas</span>
            </a>
        @endif

    </div>

    {{-- FILTER PERIODE --}}
    <div class="bg-white rounded-2xl p-5 shadow-sm">
        <form method="GET" action="{{ route('admin.laporan.index') }}">
            <div class="grid grid-cols-1 md:grid-cols-3 gap-4">

                <div>
                    <label class="text-sm text-gray-600 mb-1 block">Dari Bulan</label>
                    <input type="month" name="bulan_awal" value="{{ $bulanAwal }}" required
                           class="w-full border rounded-xl px-4 py-3 focus:outline-none focus:ring-2 focus:ring-primary">
                </div>

                <div>
                    <label class="text-sm text-gray-600 mb-1 block">Sampai Bulan</label>
                    <input type="month" name="bulan_akhir" value="{{ $bulanAkhir }}" required
                           class="w-full border rounded-xl px-4 py-3 focus:outline-none focus:ring-2 focus:ring-primary">
                </div>

                <div class="flex items-end">
                    <button type="submit"
                            class="w-full bg-primary hover:bg-secondary text-white rounded-xl px-5 py-3 flex items-center justify-center gap-2">
                        <iconify-icon icon="solar:chart-2-bold"></iconify-icon>
                        <span>Tampilkan Laporan</span>
                    </button>
                </div>

            </div>
        </form>
    </div>

    {{-- TABLE REKAP PER KELAS --}}
    <div class="bg-white rounded-2xl shadow-sm overflow-hidden">
        <div class="overflow-x-auto">
            <table class="w-full">

                <thead class="bg-gray-50">
                    <tr class="text-left text-sm text-gray-600">
                        <th class="px-6 py-4">Kelas</th>
                        <th class="px-6 py-4 text-center">Total Siswa</th>
                        <th class="px-6 py-4 text-center">Hadir</th>
                        <th class="px-6 py-4 text-center">Terlambat</th>
                        <th class="px-6 py-4 text-center">Izin</th>
                        <th class="px-6 py-4 text-center">Sakit</th>
                        <th class="px-6 py-4 text-center">Alpha</th>
                        <th class="px-6 py-4 text-center">Aksi</th>
                    </tr>
                </thead>

                <tbody class="divide-y">

                    @if(!$rekap)
                        <tr>
                            <td colspan="8" class="text-center py-14">
                                <iconify-icon icon="solar:calendar-search-outline" width="70" class="text-gray-300"></iconify-icon>
                                <h3 class="mt-3 font-semibold text-gray-700">Pilih periode terlebih dahulu</h3>
                                <p class="text-sm text-gray-500">Gunakan filter di atas untuk menampilkan rekap kehadiran</p>
                            </td>
                        </tr>

                    @elseif($rekap->isEmpty())
                        <tr>
                            <td colspan="8" class="text-center py-14">
                                <iconify-icon icon="solar:folder-open-outline" width="70" class="text-gray-300"></iconify-icon>
                                <h3 class="mt-3 font-semibold text-gray-700">Belum ada data kelas</h3>
                            </td>
                        </tr>

                    @else
                        @foreach($rekap as $item)
                            <tr class="hover:bg-gray-50 transition">

                                <td class="px-6 py-4">
                                    <div class="font-semibold text-gray-800">
                                        Kelas {{ $item['nama_kelas'] }}
                                    </div>
                                </td>

                                <td class="px-6 py-4 text-center text-gray-600">
                                    {{ $item['total_siswa'] }}
                                </td>

                                <td class="px-6 py-4 text-center">
                                    <span class="px-2 py-1 rounded-lg bg-green-50 text-green-700 text-sm font-semibold">
                                        {{ $item['hadir'] }}
                                    </span>
                                </td>

                                <td class="px-6 py-4 text-center">
                                    <span class="px-2 py-1 rounded-lg bg-yellow-50 text-yellow-700 text-sm font-semibold">
                                        {{ $item['terlambat'] }}
                                    </span>
                                </td>

                                <td class="px-6 py-4 text-center">
                                    <span class="px-2 py-1 rounded-lg bg-blue-50 text-blue-700 text-sm font-semibold">
                                        {{ $item['izin'] }}
                                    </span>
                                </td>

                                <td class="px-6 py-4 text-center">
                                    <span class="px-2 py-1 rounded-lg bg-purple-50 text-purple-700 text-sm font-semibold">
                                        {{ $item['sakit'] }}
                                    </span>
                                </td>

                                <td class="px-6 py-4 text-center">
                                    <span class="px-2 py-1 rounded-lg bg-red-50 text-red-700 text-sm font-semibold">
                                        {{ $item['alpha'] }}
                                    </span>
                                </td>

                                <td class="px-6 py-4 text-center">
                                    <a href="{{ route('admin.laporan.downloadKelas', ['kelasId' => $item['id'], 'bulan_awal' => $bulanAwal, 'bulan_akhir' => $bulanAkhir]) }}"
                                       class="bg-primary hover:bg-secondary text-white px-3 py-2 rounded-lg text-sm inline-flex items-center gap-1">
                                        <iconify-icon icon="solar:download-minimalistic-linear"></iconify-icon>
                                        <span>Unduh</span>
                                    </a>
                                </td>

                            </tr>
                        @endforeach
                    @endif

                </tbody>

            </table>
        </div>
    </div>

</div>

@endsection

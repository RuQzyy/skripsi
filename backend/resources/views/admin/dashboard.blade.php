@extends('admin.layouts.app')

@section('title', 'Dashboard')

@section('page-title', 'Dashboard')

@section('content')

<script src="https://code.iconify.design/iconify-icon/1.0.8/iconify-icon.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>

<div class="space-y-6">

    {{-- HEADER --}}
    <div>
        <h1 class="text-2xl font-bold text-gray-800">
            Dashboard
        </h1>

        <p class="text-gray-500 mt-1">
            Selamat datang di Smart Attendance System MAN Ambon
        </p>
    </div>

    {{-- CARD STATISTIK --}}
    <div class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-6">

        {{-- SISWA --}}
        <div class="bg-white rounded-2xl shadow-sm p-6">

            <div class="flex justify-between items-center">

                <div>

                    <p class="text-gray-500 text-sm">
                        Total Siswa
                    </p>

                    <h2 class="text-3xl font-bold text-gray-800 mt-2">
                        {{ $totalSiswa }}
                    </h2>

                </div>

                <div class="bg-green-100 p-3 rounded-xl">

                    <iconify-icon
                        icon="mdi:account-school"
                        width="32"
                        class="text-green-600">
                    </iconify-icon>

                </div>

            </div>

        </div>

        {{-- GURU --}}
        <div class="bg-white rounded-2xl shadow-sm p-6">

            <div class="flex justify-between items-center">

                <div>

                    <p class="text-gray-500 text-sm">
                        Total Guru
                    </p>

                    <h2 class="text-3xl font-bold text-gray-800 mt-2">
                        {{ $totalGuru }}
                    </h2>

                </div>

                <div class="bg-blue-100 p-3 rounded-xl">

                    <iconify-icon
                        icon="mdi:account-tie"
                        width="32"
                        class="text-blue-600">
                    </iconify-icon>

                </div>

            </div>

        </div>

        {{-- KELAS --}}
        <div class="bg-white rounded-2xl shadow-sm p-6">

            <div class="flex justify-between items-center">

                <div>

                    <p class="text-gray-500 text-sm">
                        Total Kelas
                    </p>

                    <h2 class="text-3xl font-bold text-gray-800 mt-2">
                        {{ $totalKelas }}
                    </h2>

                </div>

                <div class="bg-orange-100 p-3 rounded-xl">

                    <iconify-icon
                        icon="mdi:google-classroom"
                        width="32"
                        class="text-orange-600">
                    </iconify-icon>

                </div>

            </div>

        </div>

        {{-- KEHADIRAN HARI INI --}}
        <div class="bg-white rounded-2xl shadow-sm p-6">

            <div class="flex justify-between items-center">

                <div>

                    <p class="text-gray-500 text-sm">
                        Kehadiran Hari Ini
                    </p>

                    <h2 class="text-3xl font-bold text-gray-800 mt-2">
                        {{ $persenKehadiranHariIni }}%
                    </h2>

                </div>

                <div class="bg-purple-100 p-3 rounded-xl">

                    <iconify-icon
                        icon="mdi:calendar-check"
                        width="32"
                        class="text-purple-600">
                    </iconify-icon>

                </div>

            </div>

        </div>

    </div>

    {{-- GRAFIK --}}
    <div class="grid grid-cols-1 xl:grid-cols-3 gap-6">

        {{-- GRAFIK BAR --}}
        <div class="xl:col-span-2 bg-white rounded-2xl shadow-sm p-6">

            <div class="flex justify-between items-center mb-6">

                <div>

                    <h2 class="font-semibold text-gray-800">
                        Statistik Kehadiran Bulanan
                    </h2>

                    <p class="text-sm text-gray-500">
                        Perbandingan hadir dan tidak hadir
                    </p>

                </div>

            </div>

            <canvas id="attendanceChart" height="120"></canvas>

        </div>

{{-- PENGUMUMAN TERBARU --}}
<div class="bg-white rounded-2xl shadow-sm p-6">

    <div class="flex items-center justify-between mb-5">

        <h2 class="font-semibold text-gray-800">
            Pengumuman Terbaru
        </h2>

        <a href="#"
            class="text-sm text-primary hover:underline">

            Lihat Semua

        </a>

    </div>

    <div class="space-y-4">

        @forelse($pengumumanTerbaru as $item)

            <div class="flex gap-3">

                {{-- FOTO --}}
                <img
                    src="{{ asset('storage/pengumuman/' . $item->foto) }}"
                    alt="{{ $item->judul }}"
                    class="w-20 h-20 rounded-xl object-cover flex-shrink-0">

                {{-- INFO --}}
                <div class="flex-1 min-w-0">

                    <h3 class="font-semibold text-gray-800 line-clamp-2">

                        {{ $item->judul }}

                    </h3>

                    <p class="text-xs text-gray-400 mt-1">

                        {{ \Carbon\Carbon::parse($item->tanggal)->translatedFormat('d F Y') }}

                    </p>

                    <p class="text-sm text-gray-500 mt-2 line-clamp-2">

                        {{ Str::limit($item->deskripsi, 80) }}

                    </p>

                </div>

            </div>

        @empty

            <div class="text-center py-10">

                <p class="text-gray-400">
                    Belum ada pengumuman.
                </p>

            </div>

        @endforelse

    </div>

</div>

    {{-- RINGKASAN --}}
    <div class="grid grid-cols-1 md:grid-cols-2 gap-6">

        <div class="bg-white rounded-2xl shadow-sm p-6">

            <h2 class="font-semibold text-gray-800 mb-4">
                Ringkasan Kehadiran
            </h2>

            <div class="space-y-4">

                <div>

                    <div class="flex justify-between text-sm mb-1">
                        <span>Hadir</span>
                        <span>{{ $ringkasan['hadir'] }}%</span>
                    </div>

                    <div class="w-full bg-gray-200 rounded-full h-3">
                        <div class="bg-green-500 h-3 rounded-full" style="width: {{ $ringkasan['hadir'] }}%"></div>
                    </div>

                </div>

                <div>

                    <div class="flex justify-between text-sm mb-1">
                        <span>Izin</span>
                        <span>{{ $ringkasan['izin'] }}%</span>
                    </div>

                    <div class="w-full bg-gray-200 rounded-full h-3">
                        <div class="bg-yellow-500 h-3 rounded-full" style="width: {{ $ringkasan['izin'] }}%"></div>
                    </div>

                </div>

                <div>

                    <div class="flex justify-between text-sm mb-1">
                        <span>Sakit</span>
                        <span>{{ $ringkasan['sakit'] }}%</span>
                    </div>

                    <div class="w-full bg-gray-200 rounded-full h-3">
                        <div class="bg-purple-500 h-3 rounded-full" style="width: {{ $ringkasan['sakit'] }}%"></div>
                    </div>

                </div>

                <div>

                    <div class="flex justify-between text-sm mb-1">
                        <span>Alpha</span>
                        <span>{{ $ringkasan['alpha'] }}%</span>
                    </div>

                    <div class="w-full bg-gray-200 rounded-full h-3">
                        <div class="bg-red-500 h-3 rounded-full" style="width: {{ $ringkasan['alpha'] }}%"></div>
                    </div>

                </div>

            </div>

        </div>

        <div class="bg-white rounded-2xl shadow-sm p-6">

            <h2 class="font-semibold text-gray-800 mb-4">
                Informasi Sistem
            </h2>

            <div class="space-y-3 text-sm text-gray-600">

                <p>
                    ✓ Face Recognition aktif
                </p>

                <p>
                    ✓ Kamera terhubung
                </p>

                <p>
                    ✓ Sinkronisasi data berjalan normal
                </p>

                <p>
                    ✓ Server dalam kondisi baik
                </p>

            </div>

        </div>

    </div>

</div>
<script>

const ctx = document.getElementById('attendanceChart');

new Chart(ctx, {

    type: 'bar',

    data: {

        labels: @json($bulanLabels),

        datasets: [

            {
                label: 'Hadir (%)',
                data: @json($dataHadir),
                backgroundColor: '#16a34a'
            },

            {
                label: 'Tidak Hadir (%)',
                data: @json($dataTidakHadir),
                backgroundColor: '#ef4444'
            }

        ]
    },

    options: {

        responsive: true,

        scales: {
            y: {
                beginAtZero: true,
                max: 100,
                ticks: {
                    callback: function(value) {
                        return value + '%';
                    }
                }
            }
        },

        plugins: {
            legend: {
                position: 'top'
            }
        }

    }

});

</script>

@endsection

<!DOCTYPE html>
<html lang="id">

<head>

    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">

    <title>@yield('title', 'Admin Panel')</title>

    @vite(['resources/css/app.css', 'resources/js/app.js'])

    <style>

        .tooltip {
            position: absolute;
            left: 70px;
            background: #0A1931;
            color: white;
            padding: 6px 10px;
            border-radius: 8px;
            font-size: 12px;
            opacity: 0;
            pointer-events: none;
            transition: .2s;
            white-space: nowrap;
            z-index: 50;
        }

        .group:hover .tooltip {
            opacity: 1;
        }

        .sidebar-scroll::-webkit-scrollbar {
            width: 4px;
        }

        .sidebar-scroll::-webkit-scrollbar-thumb {
            background: rgba(255,255,255,.2);
            border-radius: 10px;
        }

        .sidebar-scroll::-webkit-scrollbar-track {
            background: transparent;
        }

    </style>

</head>

<body class="bg-bg">

<div class="flex h-screen">

    {{-- SIDEBAR --}}
    {{--
        flex-shrink-0 WAJIB ada di sini.
        Tanpa ini, kalau konten di sisi kanan (mis. tabel lebar dengan
        overflow-x-auto) butuh ruang lebih dari lebar layar, flexbox
        akan ikut menyusutkan sidebar ini demi memuat konten kanan,
        sehingga sidebar terlihat "hilang"/menyempit meski width-nya
        di-set w-64. flex-shrink-0 mengunci lebar sidebar apa pun yang
        terjadi di konten sebelah kanan.
    --}}
    <aside id="sidebar"
        class="w-64 flex-shrink-0 bg-dark text-white flex flex-col transition-all duration-300 h-screen overflow-hidden">

        {{-- HEADER --}}
        <div class="p-4 border-b border-white/10">

            <div class="flex items-center gap-3">

                <img
                    src="{{ asset('images/logo.png') }}"
                    class="w-10 h-10 rounded-xl object-cover"
                    alt="Logo">

                <div class="sidebar-text">

                    <h1 class="font-bold text-sm leading-tight">
                        Smart Attendance
                    </h1>

                    <p class="text-xs text-light">
                        SMA 15 Ambon
                    </p>

                </div>

            </div>

            {{-- TOGGLE --}}
            <button
                onclick="toggleSidebar()"
                class="mt-5 bg-primary hover:bg-secondary p-2.5 rounded-xl w-full flex justify-center transition">

                <i data-feather="menu"></i>

            </button>

        </div>

        {{-- MENU --}}
        <div class="flex-1 overflow-y-auto overflow-x-hidden px-3 py-4 sidebar-scroll">

            <nav class="flex flex-col gap-1 text-sm">

                {{-- DASHBOARD --}}
                <a href="{{ route('admin.dashboard') }}"
                    class="group relative flex items-center gap-3 px-4 py-3 rounded-xl transition-all duration-200
                    {{ request()->routeIs('admin.dashboard') ? 'bg-primary shadow-lg' : 'hover:bg-white/10' }}">

                    <i data-feather="home"></i>

                    <span class="sidebar-text">
                        Dashboard
                    </span>

                    <span class="tooltip hidden">
                        Dashboard
                    </span>

                </a>

                {{-- DATA GURU --}}
                <a href="{{ route('admin.guru.index') }}"
                    class="group relative flex items-center gap-3 px-4 py-3 rounded-xl hover:bg-white/10">

                    <i data-feather="user-check"></i>

                    <span class="sidebar-text">
                        Data Guru
                    </span>

                    <span class="tooltip hidden">
                        Data Guru
                    </span>

                </a>

                {{-- DATA SISWA --}}
                <a href="{{ route('admin.siswa.index') }}"
                    class="group relative flex items-center gap-3 px-4 py-3 rounded-xl hover:bg-white/10">

                    <i data-feather="users"></i>

                    <span class="sidebar-text">
                        Data Siswa
                    </span>

                    <span class="tooltip hidden">
                        Data Siswa
                    </span>

                </a>

                {{-- DATA KELAS --}}
                <a href="{{ route('admin.kelas.index') }}"
                    class="group relative flex items-center gap-3 px-4 py-3 rounded-xl hover:bg-white/10">

                    <i data-feather="book-open"></i>

                    <span class="sidebar-text">
                        Data Kelas
                    </span>

                    <span class="tooltip hidden">
                        Data Kelas
                    </span>

                </a>

                {{-- ABSENSI --}}
                <a href="#"
                    class="group relative flex items-center gap-3 px-4 py-3 rounded-xl hover:bg-white/10">

                    <i data-feather="check-square"></i>

                    <span class="sidebar-text">
                        Absensi
                    </span>

                    <span class="tooltip hidden">
                        Absensi
                    </span>

                </a>

                {{-- PENGUMUMAN --}}
                <a href="{{ route('admin.pengumuman.index') }}"
                    class="group relative flex items-center gap-3 px-4 py-3 rounded-xl hover:bg-white/10">

                    <i data-feather="bell"></i>

                    <span class="sidebar-text">
                        Pengumuman
                    </span>

                    <span class="tooltip hidden">
                        Pengumuman
                    </span>

                </a>

                {{-- LAPORAN --}}
                <a href="{{ route('admin.laporan.index') }}"
                    class="group relative flex items-center gap-3 px-4 py-3 rounded-xl hover:bg-white/10">

                    <i data-feather="file-text"></i>

                    <span class="sidebar-text">
                        Laporan
                    </span>

                    <span class="tooltip hidden">
                        Laporan
                    </span>

                </a>

                {{-- PENGATURAN --}}
                <a href="{{ route('admin.absensi.setting') }}"
                    class="group relative flex items-center gap-3 px-4 py-3 rounded-xl hover:bg-white/10">

                    <i data-feather="settings"></i>

                    <span class="sidebar-text">
                        Pengaturan
                    </span>

                    <span class="tooltip hidden">
                        Pengaturan
                    </span>

                </a>

            </nav>

        </div>

        {{-- FOOTER --}}
        <div class="p-4 border-t border-white/10">

            <div class="bg-primary/20 rounded-2xl p-4 flex items-center gap-3">

                <div class="w-10 h-10 bg-primary text-white flex items-center justify-center rounded-full font-bold shrink-0">

                    {{ strtoupper(substr(auth()->user()->name,0,1)) }}

                </div>

                <div class="sidebar-text overflow-hidden">

                    <p class="text-xs text-light">
                        Login sebagai
                    </p>

                    <h3 class="font-semibold truncate">
                        Administrator
                    </h3>

                    <p class="text-xs text-soft truncate">
                        {{ auth()->user()->name }}
                    </p>

                </div>

            </div>

        </div>

    </aside>

    {{-- MAIN --}}
    {{--
        min-w-0 WAJIB ada di sini juga (pasangan dari flex-shrink-0 di
        atas). Tanpa min-w-0, flex item ini punya min-width default
        "auto" yang mengikuti lebar konten terlebarnya (mis. tabel
        dengan min-w-[1080px] di dalam @yield('content')). Itu memaksa
        SELURUH baris flex melebar dan mendorong/menyusutkan sidebar.
        Dengan min-w-0, elemen ini boleh menyusut sesuai layar, dan
        overflow horizontal tabel di dalamnya akan discroll sendiri
        oleh div overflow-x-auto miliknya (bukan mendorong sidebar).
    --}}
    <div class="flex-1 min-w-0 flex flex-col">

        {{-- NAVBAR --}}
        <header class="bg-white shadow px-6 py-4 flex justify-between items-center">

            <div>

                <h2 class="font-semibold text-dark">
                    @yield('page-title', 'Dashboard')
                </h2>

                <p class="text-xs text-gray-500">
                    Smart Attendance System SMA 15 Ambon
                </p>

            </div>

            <div class="flex items-center gap-4">

                <span class="text-sm text-gray-500">
                    {{ auth()->user()->name }}
                </span>

                <form method="POST" action="{{ route('logout') }}">
                    @csrf

                    <button
                        class="bg-primary text-white px-4 py-2 rounded-lg hover:bg-secondary transition">

                        Logout

                    </button>

                </form>

            </div>

        </header>

        {{--
            CONTENT
            PERBAIKAN: overflow-x-hidden DIHAPUS dari sini.
            Sebelumnya <main> punya overflow-y-auto + overflow-x-hidden,
            yang menjadikan <main> ikut menjadi "scrolling container".
            Ini berpotensi memotong/mengganggu elemen sticky (kolom
            Foto & Aksi) di dalam tabel Data Siswa. Sekarang overflow
            horizontal sepenuhnya diserahkan ke div pembungkus tabel
            (overflow-x-auto) di dalam @yield('content'), sementara
            main tetap min-w-0 supaya tidak mendorong sidebar melebar.
        --}}
        <main class="p-6 overflow-y-auto flex-1 min-w-0">

            @yield('content')

        </main>

    </div>

</div>

<script>

    function toggleSidebar() {

        const sidebar = document.getElementById('sidebar');
        const texts = document.querySelectorAll('.sidebar-text');
        const tooltips = document.querySelectorAll('.tooltip');

        if (sidebar.classList.contains('w-64')) {

            sidebar.classList.replace('w-64', 'w-20');

            texts.forEach(el => el.classList.add('hidden'));
            tooltips.forEach(el => el.classList.remove('hidden'));

        } else {

            sidebar.classList.replace('w-20', 'w-64');

            texts.forEach(el => el.classList.remove('hidden'));
            tooltips.forEach(el => el.classList.add('hidden'));

        }

    }

    feather.replace();

</script>

<script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>

</body>
</html>

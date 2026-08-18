@extends('admin.layouts.app')

@section('title', 'Pengaturan Absensi')
@section('page-title', 'Pengaturan Absensi')

@section('content')

<link rel="stylesheet"
    href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />

<script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>

<div class="max-w-5xl mx-auto">

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

    <div class="bg-white rounded-3xl shadow-sm p-6">

        <form
            action="{{ route('admin.absensi.setting.update') }}"
            method="POST">

            @csrf
            @method('PUT')

            {{-- ================= WAKTU ================= --}}
            <h2 class="font-bold text-lg mb-5">
                Pengaturan Waktu Absensi
            </h2>

            {{-- ===== Jam Absen Masuk ===== --}}
            <h3 class="font-semibold text-sm text-gray-600 mb-3">
                Absen Masuk
            </h3>

            <div class="grid md:grid-cols-3 gap-4">

                <div>
                    <label class="block mb-2 text-sm font-medium">
                        Jam Absen Masuk Mulai
                    </label>

                    <input
                        type="time"
                        name="jam_absen_mulai"
                        value="{{ $setting->jam_absen_mulai }}"
                        class="w-full border rounded-xl p-3">
                </div>

                <div>
                    <label class="block mb-2 text-sm font-medium">
                        Jam Terlambat
                    </label>

                    <input
                        type="time"
                        name="jam_terlambat"
                        value="{{ $setting->jam_terlambat }}"
                        class="w-full border rounded-xl p-3">
                </div>

                <div>
                    <label class="block mb-2 text-sm font-medium">
                        Jam Absen Masuk Selesai
                    </label>

                    <input
                        type="time"
                        name="jam_absen_selesai"
                        value="{{ $setting->jam_absen_selesai }}"
                        class="w-full border rounded-xl p-3">
                </div>

            </div>

            {{-- ===== Jam Absen Pulang ===== --}}
            <h3 class="font-semibold text-sm text-gray-600 mb-3 mt-6">
                Absen Pulang
            </h3>

            <div class="grid md:grid-cols-2 gap-4">

                <div>
                    <label class="block mb-2 text-sm font-medium">
                        Jam Absen Pulang Mulai
                    </label>

                    <input
                        type="time"
                        name="jam_pulang_mulai"
                        value="{{ $setting->jam_pulang_mulai }}"
                        class="w-full border rounded-xl p-3">
                </div>

                <div>
                    <label class="block mb-2 text-sm font-medium">
                        Jam Absen Pulang Selesai
                    </label>

                    <input
                        type="time"
                        name="jam_pulang_selesai"
                        value="{{ $setting->jam_pulang_selesai }}"
                        class="w-full border rounded-xl p-3">
                </div>

            </div>

            <hr class="my-8">

            {{-- ================= LOKASI ================= --}}
            <h2 class="font-bold text-lg mb-5">
                Pengaturan Lokasi Absensi
            </h2>

            <div class="space-y-4">

                <div>
                    <label class="block mb-2 text-sm font-medium">
                        Nama Lokasi
                    </label>

                    <input
                        type="text"
                        name="nama_lokasi"
                        value="{{ $setting->nama_lokasi }}"
                        placeholder="Nama Lokasi"
                        class="w-full border rounded-xl p-3">
                </div>

                <div class="grid md:grid-cols-2 gap-4">

                    <div>
                        <label class="block mb-2 text-sm font-medium">
                            Latitude
                        </label>

                        <input
                            type="text"
                            id="latitude"
                            name="latitude"
                            value="{{ $setting->latitude }}"
                            placeholder="Latitude"
                            class="w-full border rounded-xl p-3">
                    </div>

                    <div>
                        <label class="block mb-2 text-sm font-medium">
                            Longitude
                        </label>

                        <input
                            type="text"
                            id="longitude"
                            name="longitude"
                            value="{{ $setting->longitude }}"
                            placeholder="Longitude"
                            class="w-full border rounded-xl p-3">
                    </div>

                </div>

                <div>
                    <label class="block mb-2 text-sm font-medium">
                        BSSID WiFi Sekolah
                    </label>

                    <input
                        type="text"
                        name="wifi_bssid"
                        value="{{ $setting->wifi_bssid }}"
                        placeholder="Contoh: aa:bb:cc:dd:ee:ff"
                        class="w-full border rounded-xl p-3">

                    <p class="text-xs text-gray-500 mt-1">
                        Alamat unik router WiFi sekolah. Cara mendapatkannya: hubungkan HP ke WiFi sekolah,
                        lalu gunakan comand prompt netsh wlan show interfaces untuk mengecek BSSID dari router wifi.
                    </p>
                </div>

                <input type="hidden" name="wifi_required" value="0">
                <div class="flex items-center gap-3">
                    <input type="checkbox" id="wifi_required" name="wifi_required" value="1"
                        {{ $setting->wifi_required ? 'checked' : '' }} class="w-5 h-5">
                    <label for="wifi_required" class="text-sm font-medium">
                        Wajibkan siswa terhubung ke WiFi sekolah untuk bisa absen
                    </label>
                </div>

                <div>
                    <label class="block mb-2 text-sm font-medium">
                        Radius Absensi (Meter)
                    </label>

                    <input
                        type="number"
                        id="radius"
                        name="radius"
                        value="{{ $setting->radius }}"
                        placeholder="Radius"
                        class="w-full border rounded-xl p-3">
                </div>



                {{-- BUTTON GPS --}}
                <div>

                    <button
                        type="button"
                        onclick="getCurrentLocation()"
                        class="bg-blue-600 hover:bg-blue-700 text-white px-5 py-3 rounded-xl">

                        Gunakan Lokasi Saat Ini

                    </button>

                </div>

                {{-- MAP --}}
                <div>

                    <label class="block mb-2 text-sm font-medium">
                        Pilih Lokasi Pada Peta
                    </label>

                    <div
                        id="map"
                        class="w-full h-[450px] rounded-2xl border">
                    </div>

                </div>

            </div>

            <hr class="my-8">

            {{-- ================= STATUS ================= --}}
            <h2 class="font-bold text-lg mb-5">
                Status Absensi
            </h2>

            <select
                name="is_active"
                class="w-full border rounded-xl p-3">

                <option
                    value="1"
                    {{ $setting->is_active ? 'selected' : '' }}>
                    Aktif
                </option>

                <option
                    value="0"
                    {{ !$setting->is_active ? 'selected' : '' }}>
                    Nonaktif
                </option>

            </select>

            <button
                type="submit"
                class="mt-6 bg-primary hover:bg-secondary text-white px-6 py-3 rounded-xl">

                Simpan Pengaturan

            </button>

        </form>

    </div>

</div>

<script>

    let latitudeInput =
        document.getElementById('latitude');

    let longitudeInput =
        document.getElementById('longitude');

    let radiusInput =
        document.getElementById('radius');

    let defaultLat =
        parseFloat(latitudeInput.value) ||
        -3.6951234;

    let defaultLng =
        parseFloat(longitudeInput.value) ||
        128.1812345;

    let defaultRadius =
        parseInt(radiusInput.value) ||
        100;

    // ================= MAP =================

    let map = L.map('map')
        .setView(
            [defaultLat, defaultLng],
            17
        );

    L.tileLayer(
        'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
        {
            attribution:
                '&copy; OpenStreetMap'
        }
    ).addTo(map);

    // Marker

    let marker =
        L.marker(
            [defaultLat, defaultLng],
            {
                draggable: true
            }
        ).addTo(map);

    // Circle Radius

    let circle =
        L.circle(
            [defaultLat, defaultLng],
            {
                radius: defaultRadius
            }
        ).addTo(map);

    // ================= UPDATE POSITION =================

    function updatePosition(lat, lng)
    {
        latitudeInput.value =
            lat.toFixed(7);

        longitudeInput.value =
            lng.toFixed(7);

        marker.setLatLng([lat, lng]);

        circle.setLatLng([lat, lng]);
    }

    // ================= CLICK MAP =================

    map.on('click', function(e)
    {
        updatePosition(
            e.latlng.lat,
            e.latlng.lng
        );
    });

    // ================= DRAG MARKER =================

    marker.on('dragend', function()
    {
        let pos =
            marker.getLatLng();

        updatePosition(
            pos.lat,
            pos.lng
        );
    });

    // ================= UPDATE RADIUS =================

    radiusInput.addEventListener(
        'input',
        function()
        {
            circle.setRadius(
                parseInt(this.value) || 0
            );
        }
    );

    // ================= GPS =================

    function getCurrentLocation()
    {
        if (!navigator.geolocation)
        {
            alert(
                'Browser tidak mendukung GPS'
            );

            return;
        }

        navigator.geolocation.getCurrentPosition(

            function(position)
            {
                let lat =
                    position.coords.latitude;

                let lng =
                    position.coords.longitude;

                updatePosition(
                    lat,
                    lng
                );

                map.setView(
                    [lat, lng],
                    18
                );
            },

            function(error)
            {
                Swal.fire({
                    icon: 'error',
                    title: 'Gagal',
                    text: 'Tidak dapat mengambil lokasi'
                });
            }

        );
    }

</script>

@endsection

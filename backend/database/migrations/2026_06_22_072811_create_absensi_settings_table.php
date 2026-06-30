<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('absensi_settings', function (Blueprint $table) {
            $table->id();

            // Jam absensi
            $table->time('jam_absen_mulai');
            $table->time('jam_terlambat');
            $table->time('jam_absen_selesai');

            // Lokasi sekolah
            $table->string('nama_lokasi');

            $table->decimal('latitude', 10, 7);
            $table->decimal('longitude', 10, 7);

            // Radius dalam meter
            $table->integer('radius')->default(100);

            // Aktif / nonaktif absensi
            $table->boolean('is_active')->default(true);

            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('absensi_settings');
    }
};

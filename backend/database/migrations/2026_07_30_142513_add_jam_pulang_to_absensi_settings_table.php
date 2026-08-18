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
        Schema::table('absensi_settings', function (Blueprint $table) {
            $table->time('jam_pulang_mulai')
                ->nullable()
                ->after('jam_absen_selesai');

            $table->time('jam_pulang_selesai')
                ->nullable()
                ->after('jam_pulang_mulai');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('absensi_settings', function (Blueprint $table) {
            $table->dropColumn([
                'jam_pulang_mulai',
                'jam_pulang_selesai',
            ]);
        });
    }
};

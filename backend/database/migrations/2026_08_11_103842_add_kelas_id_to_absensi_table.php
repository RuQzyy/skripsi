<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Menambahkan kolom kelas_id pada tabel absensis.
     *
     * kelas_id digunakan sebagai SNAPSHOT kelas siswa pada saat
     * absensi dibuat.
     */
    public function up(): void
    {
        Schema::table('absensis', function (Blueprint $table) {
            $table->foreignId('kelas_id')
                ->nullable()
                ->after('user_id')
                ->constrained('kelas')
                ->nullOnDelete();
        });

        // ==========================================================
        // BACKFILL DATA ABSENSI LAMA
        // ==========================================================
        // Untuk data absensi yang sudah ada sebelum migration ini,
        // kelas_id akan diisi berdasarkan kelas_id user saat ini.
        //
        // Catatan:
        // Jika siswa sebelumnya pernah pindah kelas, data absensi
        // lama akan mengikuti kelas siswa yang sekarang.

        DB::table('absensis')
            ->whereNull('kelas_id')
            ->orderBy('id')
            ->chunkById(500, function ($rows) {
                foreach ($rows as $row) {

                    $kelasId = DB::table('users')
                        ->where('id', $row->user_id)
                        ->value('kelas_id');

                    if ($kelasId) {
                        DB::table('absensis')
                            ->where('id', $row->id)
                            ->update([
                                'kelas_id' => $kelasId
                            ]);
                    }
                }
            });
    }

    public function down(): void
    {
        Schema::table('absensis', function (Blueprint $table) {
            $table->dropForeign(['kelas_id']);
            $table->dropColumn('kelas_id');
        });
    }
};

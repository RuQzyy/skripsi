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
        Schema::table('absensis', function (Blueprint $table) {
            $table->time('jam_keluar')->nullable()->after('jam_masuk');

            $table->decimal('latitude_pulang', 10, 7)
                ->nullable()
                ->after('longitude');

            $table->decimal('longitude_pulang', 10, 7)
                ->nullable()
                ->after('latitude_pulang');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('absensis', function (Blueprint $table) {
            $table->dropColumn([
                'jam_keluar',
                'latitude_pulang',
                'longitude_pulang',
            ]);
        });
    }
};

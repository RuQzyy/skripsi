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

            // UUID unik dari aplikasi Flutter
            $table->uuid('client_uuid')
                ->nullable()
                ->unique()
                ->after('id');

            // Waktu absensi sebenarnya saat foto diambil
            $table->timestamp('client_captured_at')
                ->nullable()
                ->after('client_uuid');

            // Waktu server menerima sinkronisasi
            $table->timestamp('server_received_at')
                ->nullable()
                ->after('client_captured_at');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('absensis', function (Blueprint $table) {

            $table->dropUnique('absensis_client_uuid_unique');

            $table->dropColumn([
                'client_uuid',
                'client_captured_at',
                'server_received_at',
            ]);

        });
    }
};

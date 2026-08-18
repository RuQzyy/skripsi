<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('absensi_settings', function (Blueprint $table) {
            $table->string('wifi_bssid')->nullable()->after('radius');
            $table->boolean('wifi_required')->default(false)->after('wifi_bssid');
        });
    }

    public function down(): void
    {
        Schema::table('absensi_settings', function (Blueprint $table) {
            $table->dropColumn(['wifi_bssid', 'wifi_required']);
        });
    }
};

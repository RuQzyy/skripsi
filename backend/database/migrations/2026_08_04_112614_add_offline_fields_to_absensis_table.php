<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('absensis', function (Blueprint $table) {
            $table->double('accuracy')->nullable()->after('longitude_pulang');
            $table->string('wifi_bssid')->nullable()->after('accuracy');
            $table->boolean('is_mocked')->default(false)->after('wifi_bssid');
        });
    }

    public function down(): void
    {
        Schema::table('absensis', function (Blueprint $table) {
            $table->dropColumn([
                'accuracy',
                'wifi_bssid',
                'is_mocked',
            ]);
        });
    }
};

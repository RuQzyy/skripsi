<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Absensi extends Model
{
    protected $fillable = [
        'user_id',
        'kelas_id',
        'tanggal',

        'jam_masuk',
        'jam_keluar',

        'catatan',
        'status',

        'latitude',
        'longitude',

        'latitude_pulang',
        'longitude_pulang',

        // Validasi Absensi
        'accuracy',
        'wifi_bssid',
        'is_mocked',

        // Offline Sync
        'client_uuid',
        'client_captured_at',
        'server_received_at',
    ];

    protected $casts = [
        'tanggal' => 'date:Y-m-d',

        'accuracy' => 'double',
        'is_mocked' => 'boolean',

        // Offline Sync
        'client_captured_at' => 'datetime',
        'server_received_at' => 'datetime',
    ];

    protected static function boot()
    {
        parent::boot();

        static::saving(function ($absensi) {
            if ($absensi->status) {
                $absensi->status = ucfirst(strtolower($absensi->status));
            }
        });
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    /**
     * Kelas siswa PADA SAAT absensi ini dibuat (snapshot, bukan kelas
     * siswa yang sekarang). Karena kelas_id di tabel absensi diisi
     * sekali saat baris ini dibuat dan tidak pernah ikut berubah walau
     * siswa dipindah kelas setelahnya.
     */
    public function kelas()
    {
        return $this->belongsTo(Kelas::class);
    }

    /**
     * Mengecek apakah siswa sudah melakukan absen pulang.
     */
    public function sudahPulang(): bool
    {
        return !is_null($this->jam_keluar);
    }
}

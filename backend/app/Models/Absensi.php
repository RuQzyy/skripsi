<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Absensi extends Model
{
    protected $fillable = [
        'user_id',
        'tanggal',
        'jam_masuk',
        'status',
        'latitude',
        'longitude',
        'foto',
    ];

    protected $casts = [
        'tanggal' => 'date:Y-m-d',
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
}

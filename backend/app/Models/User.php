<?php

namespace App\Models;

use App\Models\Kelas;
use App\Models\Absensi;
use Laravel\Sanctum\HasApiTokens;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;

class User extends Authenticatable
{
    use HasApiTokens, Notifiable;

    protected $fillable = [
        'name',
        'email',
        'password',
        'nisn',
        'nip',
        'phone',
        'photo',
        'google_id',
        'face_id',
        'kelas_id',
        'role'
    ];

    protected $hidden = [
        'password',
        'remember_token',
    ];

    public function kelas()
    {
        return $this->belongsTo(
            Kelas::class,
            'kelas_id',
            'id'
        );
    }

    public function absensis()
    {
        return $this->hasMany(Absensi::class);
    }
}

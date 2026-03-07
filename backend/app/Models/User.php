<?php

namespace App\Models;

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
        'role'

    ];


    protected $hidden = [

        'password',
        'remember_token',

    ];

}

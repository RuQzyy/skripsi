<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Pengumuman;

class DashboardController extends Controller
{
    public function index()
    {
        $pengumumanTerbaru = Pengumuman::latest()
            ->take(3)
            ->get();

        return view('admin.dashboard', compact(
            'pengumumanTerbaru'
        ));
    }
}

<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Models\AbsensiSetting;
use App\Models\Absensi;
use App\Models\User;
use App\Services\WhatsappService;

class MarkAlphaAbsensi extends Command
{
    protected $signature = 'absensi:mark-alpha';
    protected $description = 'Tandai siswa yang belum absen sebagai Alpha setelah jam absen selesai';

    public function handle()
    {
        $setting = AbsensiSetting::first();

        if (!$setting || !$setting->is_active) {
            return;
        }

        $now = now()->format('H:i:s');

        if ($now < $setting->jam_absen_selesai) {
            return;
        }

        $today = now()->toDateString();

        $siswaList = User::where('role', 'siswa')->get(['id', 'name', 'phone']);
        $siswaIds = $siswaList->pluck('id');

        $sudahAbsenIds = Absensi::where('tanggal', $today)
            ->whereIn('user_id', $siswaIds)
            ->pluck('user_id');

        $belumAbsen = $siswaList->whereNotIn('id', $sudahAbsenIds);

        foreach ($belumAbsen as $siswa) {
            Absensi::create([
                'user_id'   => $siswa->id,
                'tanggal'   => $today,
                'jam_masuk' => null,
                'status'    => 'alpha',
            ]);

            if (!empty($siswa->phone)) {
                $tanggalIndo = now()->translatedFormat('d F Y');

                $pesan = "Yth. Orang Tua/Wali dari *{$siswa->name}*,\n\n"
                    . "Kami informasikan bahwa ananda *{$siswa->name}* tidak hadir (Alpha) di sekolah pada tanggal *{$tanggalIndo}* tanpa keterangan.\n\n"
                    . "Mohon konfirmasi ke pihak sekolah jika diperlukan.\n\n"
                    . "Pesan ini dikirim otomatis oleh Sistem Absensi Sekolah.";

                WhatsappService::send($siswa->phone, $pesan);

                // Jeda acak 4-8 detik sebelum lanjut ke siswa berikutnya
                sleep(rand(4, 8));
            }
        }

        if ($belumAbsen->count() > 0) {
            $this->info("{$belumAbsen->count()} siswa ditandai Alpha dan notifikasi WA diproses.");
        }
    }
}

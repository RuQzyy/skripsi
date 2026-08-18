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

    protected $description = 'Menandai Alpha dan Bolos secara otomatis';

    public function handle()
    {
        $setting = AbsensiSetting::first();

        if (!$setting || !$setting->is_active) {
            $this->warn('Pengaturan absensi belum aktif.');
            return Command::SUCCESS;
        }

        $today = now()->toDateString();
        $now   = now()->format('H:i:s');

        /*
        |--------------------------------------------------------------------------
        | 1. Tandai Alpha
        |--------------------------------------------------------------------------
        */

        if ($now >= $setting->jam_absen_selesai) {
            $this->markAlpha($today);
        }

        /*
        |--------------------------------------------------------------------------
        | 2. Tandai Bolos
        |--------------------------------------------------------------------------
        */

        if ($now >= $setting->jam_pulang_selesai) {
            $this->markBolos($today);
        }

        $this->info('Proses absensi selesai.');

        return Command::SUCCESS;
    }

    /**
     * ============================================================
     * ALPHA
     * ============================================================
     */
    private function markAlpha($today)
    {
        $siswaList = User::where('role', 'siswa')
            ->get(['id', 'name', 'phone']);

        $siswaIds = $siswaList->pluck('id');

        $sudahAbsenIds = Absensi::whereDate('tanggal', $today)
            ->whereIn('user_id', $siswaIds)
            ->pluck('user_id');

        $belumAbsen = $siswaList->whereNotIn('id', $sudahAbsenIds);

        foreach ($belumAbsen as $siswa) {

            Absensi::create([
                'user_id'    => $siswa->id,
                'tanggal'    => $today,
                'jam_masuk'  => null,
                'jam_keluar' => null,
                'status'     => 'Alpha',
            ]);

            if (!empty($siswa->phone)) {

                $tanggal = now()->translatedFormat('d F Y');

                $pesan =
                    "Yth. Orang Tua/Wali dari *{$siswa->name}*,\n\n"
                    ."Kami informasikan bahwa ananda *{$siswa->name}* "
                    ."tidak hadir (Alpha) di sekolah pada tanggal *{$tanggal}*.\n\n"
                    ."Mohon konfirmasi kepada pihak sekolah apabila terdapat kendala.\n\n"
                    ."Pesan ini dikirim otomatis oleh Sistem Absensi Sekolah.";

                WhatsappService::send($siswa->phone, $pesan);

                sleep(rand(4,8));
            }
        }

        $this->info($belumAbsen->count().' siswa ditandai Alpha.');
    }

    /**
     * ============================================================
     * BOLOS
     * ============================================================
     */
    private function markBolos($today)
    {
        $absensi = Absensi::with('user')
            ->whereDate('tanggal', $today)
            ->whereIn('status', [
                'Hadir',
                'Terlambat'
            ])
            ->whereNull('jam_keluar')
            ->get();

        foreach ($absensi as $item) {

            $item->update([
                'status' => 'Bolos'
            ]);

            $siswa = $item->user;

            if ($siswa && !empty($siswa->phone)) {

                $tanggal = now()->translatedFormat('d F Y');

                $pesan =
                    "Yth. Orang Tua/Wali dari *{$siswa->name}*,\n\n"
                    ."Kami informasikan bahwa ananda *{$siswa->name}* "
                    ."tercatat hadir di sekolah, namun belum melakukan *absen pulang* pada tanggal *{$tanggal}*.\n\n"
                    ."Status absensi hari ini tercatat sebagai *Bolos* karena tidak melakukan absen pulang sesuai ketentuan sekolah.\n\n"
                    ."Mohon memastikan ananda melakukan absen pulang atau menghubungi pihak sekolah apabila terdapat kendala.\n\n"
                    ."Pesan ini dikirim otomatis oleh Sistem Absensi Sekolah.";

                WhatsappService::send($siswa->phone, $pesan);

                sleep(rand(4,8));
            }
        }

        $this->info($absensi->count().' siswa ditandai Bolos.');
    }
}

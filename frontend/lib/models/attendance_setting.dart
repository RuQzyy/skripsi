class AttendanceSetting {
  final String namaLokasi;
  final String jamMulai;
  final String jamTerlambat;
  final String jamSelesai;
  final String jamPulangMulai;   // TAMBAHAN BARU
  final String jamPulangSelesai; // TAMBAHAN BARU
  final double latitude;
  final double longitude;
  final int radius;
  final bool isActive;
  final bool wifiRequired;

AttendanceSetting({
    required this.namaLokasi,
    required this.jamMulai,
    required this.jamTerlambat,
    required this.jamSelesai,
    required this.jamPulangMulai,   // TAMBAHAN BARU
    required this.jamPulangSelesai, // TAMBAHAN BARU
    required this.latitude,
    required this.longitude,
    required this.radius,
    required this.isActive,
    required this.wifiRequired,
  });

 factory AttendanceSetting.fromJson(Map<String, dynamic> json) {
    return AttendanceSetting(
      namaLokasi: json['nama_lokasi'],
      jamMulai: json['jam_absen_mulai'],
      jamTerlambat: json['jam_terlambat'],
      jamSelesai: json['jam_absen_selesai'],
      jamPulangMulai: json['jam_pulang_mulai'],     // TAMBAHAN BARU
      jamPulangSelesai: json['jam_pulang_selesai'], // TAMBAHAN BARU
      latitude: double.parse(json['latitude'].toString()),
      longitude: double.parse(json['longitude'].toString()),
      radius: json['radius'],
      isActive: json['is_active'] == 1,
      wifiRequired: json['wifi_required'] == true || json['wifi_required'] == 1,
    );
  }
}
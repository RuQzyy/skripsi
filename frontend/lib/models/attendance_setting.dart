class AttendanceSetting {
  final String namaLokasi;
  final String jamMulai;
  final String jamTerlambat;
  final String jamSelesai;
  final double latitude;
  final double longitude;
  final int radius;
  final bool isActive;

  AttendanceSetting({
    required this.namaLokasi,
    required this.jamMulai,
    required this.jamTerlambat,
    required this.jamSelesai,
    required this.latitude,
    required this.longitude,
    required this.radius,
    required this.isActive,
  });

  factory AttendanceSetting.fromJson(Map<String, dynamic> json) {
    return AttendanceSetting(
      namaLokasi: json['nama_lokasi'],
      jamMulai: json['jam_absen_mulai'],
      jamTerlambat: json['jam_terlambat'],
      jamSelesai: json['jam_absen_selesai'],
      latitude: double.parse(json['latitude'].toString()),
      longitude: double.parse(json['longitude'].toString()),
      radius: json['radius'],
      isActive: json['is_active'] == 1,
    );
  }
}
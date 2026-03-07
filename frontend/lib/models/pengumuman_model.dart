class Pengumuman {
  final int id;
  final String judul;
  final String deskripsi;
  final String foto;
  final String tanggal;

  Pengumuman({
    required this.id,
    required this.judul,
    required this.deskripsi,
    required this.foto,
    required this.tanggal,
  });

  factory Pengumuman.fromJson(Map<String, dynamic> json) {
    return Pengumuman(
      id: json['id'],
      judul: json['judul'],
      deskripsi: json['deskripsi'],
      foto: json['foto'],
      tanggal: json['tanggal'], 
    );
  }
}
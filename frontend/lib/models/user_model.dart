class UserModel {
  final int id;
  final String name;
  final String? nisn;
  final String? nip;
  final String? kelas;
  final String? email;
  final String? photo;
  final String? phone;
  final String role;

  UserModel({
    required this.id,
    required this.name,
    this.nisn,
    this.nip,
    this.kelas,
    this.email,
    this.photo,
    this.phone,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      nisn: json['nisn'],
      nip: json['nip'],
      kelas: json['kelas'],
      email: json['email'],
      photo: json['photo'],
      phone: json['phone'],
      role: json['role'],
    );
  }
}
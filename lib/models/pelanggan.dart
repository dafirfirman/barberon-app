class Pelanggan {
  final int id;
  final String email;
  final String password;
  final String createdAt;
  final String? profileImagePath;

  Pelanggan({
    required this.id,
    required this.email,
    required this.password,
    required this.createdAt,
    this.profileImagePath,
  });

  // Metode untuk mengubah map ke object Pelanggan
  factory Pelanggan.fromMap(Map<String, dynamic> map) {
    return Pelanggan(
      id: map['id'],
      email: map['email'],
      password: map['password'],
      createdAt: map['created_at'],
      profileImagePath: map['profile_image_path'],
    );
  }

  // Metode untuk mengubah object Pelanggan ke map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'password': password,
      'created_at': createdAt,
      'profile_image_path': profileImagePath,
    };
  }
}

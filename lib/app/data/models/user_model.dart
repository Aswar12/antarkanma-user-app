class UserModel {
  final int id;
  final String name;
  final String? email;
  final String? phoneNumber;
  final String role; // 'USER', 'MERCHANT', 'COURIER'
  final String? username;
  final String? profilePhotoUrl;
  final String? profilePhotoPath; // Tambahkan properti baru

  UserModel({
    required this.id,
    required this.name,
    this.email,
    this.phoneNumber,
    required this.role,
    this.username,
    this.profilePhotoUrl,
    this.profilePhotoPath, // Tambahkan parameter baru
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phoneNumber: json['phone_number'],
      role: (json['roles'] is List)
          ? json['roles'].first
          : json['roles'], // Mengambil role pertama jika merupakan array
      username: json['username'],
      profilePhotoUrl: json['profile_photo_url'],
      profilePhotoPath: json['profile_photo_path'], // Ambil dari JSON
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone_number': phoneNumber,
      'roles': role, // Pastikan ini sesuai dengan format yang diharapkan
      'username': username,
      'profile_photo_url': profilePhotoUrl,
      'profile_photo_path': profilePhotoPath, // Sertakan dalam JSON
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserModel &&
        other.id == id &&
        other.name == name &&
        other.email == email &&
        other.phoneNumber == phoneNumber &&
        other.role == role &&
        other.username == username &&
        other.profilePhotoUrl == profilePhotoUrl &&
        other.profilePhotoPath == profilePhotoPath; // Tambahkan perbandingan
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        email.hashCode ^
        phoneNumber.hashCode ^
        role.hashCode ^
        username.hashCode ^
        profilePhotoUrl.hashCode ^
        profilePhotoPath.hashCode; // Tambahkan hashCode
  }

  UserModel copyWith({
    int? id,
    String? name,
    String? email,
    String? phoneNumber,
    String? role,
    String? username,
    String? profilePhotoUrl,
    String? profilePhotoPath, // Tambahkan parameter baru
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      username: username ?? this.username,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      profilePhotoPath:
          profilePhotoPath ?? this.profilePhotoPath, // Tambahkan parameter baru
    );
  }
}

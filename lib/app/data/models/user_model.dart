class UserModel {
  final int id;
  final String name;
  final String? email;
  final String? phoneNumber;
  final String role;
  final String? username;
  final String? profilePhotoUrl;
  final String? profilePhotoPath;

  static const String ROLE_USER = 'USER';

  UserModel({
    required this.id,
    required this.name,
    this.email,
    this.phoneNumber,
    required this.role,
    this.username,
    this.profilePhotoUrl,
    this.profilePhotoPath,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Handle profile photo URL
    String? photoUrl = json['profile_photo_url'];
    if (photoUrl == null || photoUrl.isEmpty) {
      // If no photo URL, check if there's a path and construct the URL
      final photoPath = json['profile_photo_path'];
      if (photoPath != null && photoPath.isNotEmpty) {
        photoUrl = 'storage/$photoPath';
      }
    }

    // Handle role from different possible API response formats
    String role;
    if (json['role'] != null) {
      role = json['role'].toString().toUpperCase();
    } else if (json['roles'] != null) {
      if (json['roles'] is List) {
        role = (json['roles'] as List).first.toString().toUpperCase();
      } else {
        role = json['roles'].toString().toUpperCase();
      }
    } else {
      role = ROLE_USER;  // Default to USER role
    }

    return UserModel(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String?,
      phoneNumber: json['phone_number'] as String?,
      role: role,
      username: json['username'] as String?,
      profilePhotoUrl: photoUrl,
      profilePhotoPath: json['profile_photo_path'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone_number': phoneNumber,
      'roles': role,
      'username': username,
      'profile_photo_url': profilePhotoUrl,
      'profile_photo_path': profilePhotoPath,
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
        other.profilePhotoPath == profilePhotoPath;
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
        profilePhotoPath.hashCode;
  }

  UserModel copyWith({
    int? id,
    String? name,
    String? email,
    String? phoneNumber,
    String? role,
    String? username,
    String? profilePhotoUrl,
    String? profilePhotoPath,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      username: username ?? this.username,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      profilePhotoPath: profilePhotoPath ?? this.profilePhotoPath,
    );
  }

  // Helper methods
  bool get isUser => role == ROLE_USER;
  
  String get displayName => username ?? name;
  
  bool get hasProfilePhoto => 
      (profilePhotoUrl?.isNotEmpty ?? false) || 
      (profilePhotoPath?.isNotEmpty ?? false);
}

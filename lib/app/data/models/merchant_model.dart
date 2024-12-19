class MerchantModel {
  final int? id;
  final int ownerId;
  final String name;
  final String address;
  final String phoneNumber;
  final String? status; // Menambahkan status merchant
  final DateTime createdAt;
  final DateTime updatedAt;

  MerchantModel({
    this.id,
    required this.ownerId,
    required this.name,
    required this.address,
    required this.phoneNumber,
    this.status = 'ACTIVE', // Default status
    required this.createdAt,
    required this.updatedAt,
  });

  // Constructor untuk data dari API
  factory MerchantModel.fromJson(Map<String, dynamic> json) {
    try {
      // Helper function to safely parse integer
      int? parseInt(dynamic value) {
        if (value == null) return null;
        if (value is int) return value;
        if (value is String) {
          try {
            return int.parse(value);
          } catch (e) {
            print('Error parsing $value to int: $e');
            return null;
          }
        }
        return null;
      }

      return MerchantModel(
        id: parseInt(json['id']),
        ownerId: parseInt(json['owner_id']) ?? 0,
        name: json['name']?.toString() ?? '',
        address: json['address']?.toString() ?? '',
        phoneNumber: json['phone_number']?.toString() ?? '',
        status: json['status']?.toString() ?? 'ACTIVE',
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
            : DateTime.now(),
        updatedAt: json['updated_at'] != null
            ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
            : DateTime.now(),
      );
    } catch (e) {
      print('Error parsing merchant JSON: $e');
      print('Problematic JSON: $json');
      // Return a minimal valid merchant in case of error
      return MerchantModel(
        ownerId: 0,
        name: '',
        address: '',
        phoneNumber: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'name': name,
      'address': address,
      'phone_number': phoneNumber,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Copy with method
  MerchantModel copyWith({
    int? id,
    int? ownerId,
    String? name,
    String? address,
    String? phoneNumber,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MerchantModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      address: address ?? this.address,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Getter untuk mengecek apakah merchant aktif
  bool get isActive => status?.toUpperCase() == 'ACTIVE';

  // Method untuk memperbarui status
  MerchantModel updateStatus(String newStatus) {
    return copyWith(
      status: newStatus,
      updatedAt: DateTime.now(),
    );
  }

  // Method untuk memformat nomor telepon
  String get formattedPhoneNumber {
    // Implementasi formatting nomor telepon
    return phoneNumber;
  }

  // Method untuk mendapatkan ringkasan merchant
  String get summary => '$name - $address';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MerchantModel &&
        other.id == id &&
        other.ownerId == ownerId &&
        other.name == name &&
        other.address == address &&
        other.phoneNumber == phoneNumber &&
        other.status == status;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        ownerId.hashCode ^
        name.hashCode ^
        address.hashCode ^
        phoneNumber.hashCode ^
        status.hashCode;
  }

  @override
  String toString() {
    return 'MerchantModel(id: $id, name: $name, status: $status)';
  }
}

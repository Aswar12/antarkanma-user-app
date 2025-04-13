class CourierModel {
  final int? id;
  final int? userId;
  final String vehicleType;
  final String licensePlate;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final double walletBalance;
  final double feePerOrder;
  final bool isWalletActive;
  final double minimumBalance;
  final String name;
  final String fullDetails;

  CourierModel({
    this.id,
    this.userId,
    required this.vehicleType,
    required this.licensePlate,
    this.createdAt,
    this.updatedAt,
    required this.walletBalance,
    required this.feePerOrder,
    required this.isWalletActive,
    required this.minimumBalance,
    required this.name,
    required this.fullDetails,
  });

  factory CourierModel.fromJson(Map<String, dynamic> json) {
    return CourierModel(
      id: json['id'],
      userId: json['user_id'],
      vehicleType: json['vehicle_type'] ?? 'Unknown',
      licensePlate: json['license_plate'] ?? '-',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      walletBalance: json['wallet_balance'] != null 
          ? double.tryParse(json['wallet_balance'].toString()) ?? 0.0 
          : 0.0,
      feePerOrder: json['fee_per_order'] != null 
          ? double.tryParse(json['fee_per_order'].toString()) ?? 0.0 
          : 0.0,
      isWalletActive: json['is_wallet_active'] ?? false,
      minimumBalance: json['minimum_balance'] != null 
          ? double.tryParse(json['minimum_balance'].toString()) ?? 0.0 
          : 0.0,
      name: json['name'] ?? 'Unknown Courier',
      fullDetails: json['full_details'] ?? 'Unknown Courier ( - )',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'vehicle_type': vehicleType,
      'license_plate': licensePlate,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'wallet_balance': walletBalance,
      'fee_per_order': feePerOrder,
      'is_wallet_active': isWalletActive,
      'minimum_balance': minimumBalance,
      'name': name,
      'full_details': fullDetails,
    };
  }
}

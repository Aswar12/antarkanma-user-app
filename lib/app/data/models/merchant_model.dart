class MerchantModel {
  final int? id;
  final int ownerId;
  final String name;
  final String address;
  final String phoneNumber;
  final String? status; // Menambahkan status merchant
  final String? description; // New field for merchant description
  final String? logo; // New field for merchant logo
  final String? openingTime; // New field for opening time
  final String? closingTime; // New field for closing time
  final List<String>? operatingDays; // New field for operating days
  final DateTime createdAt; 
  final int? orderCount; // New field for order count
  final int? productsSold; // New field for products sold
  final int? totalSales; // New field for total sales
  final int? monthlyRevenue; // New field for monthly revenue
  final int? productCount; // New field for product count
  final DateTime updatedAt;

  MerchantModel({
    this.id,
    required this.ownerId,
    required this.name,
    required this.address,
    required this.phoneNumber,
    this.status = 'ACTIVE', // Default status
    this.description, // Accept description
    this.logo, // Accept logo
    required this.createdAt,
    this.productCount, // Accept product count
    required this.updatedAt,
    this.openingTime, // Accept opening time
    this.closingTime, // Accept closing time
    this.operatingDays, // Accept operating days
    this.orderCount, // Accept order count
    this.productsSold, // Accept products sold
    this.totalSales, // Accept total sales
    this.monthlyRevenue, // Accept monthly revenue
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

      // Parse operating days from JSON
      List<String>? parseOperatingDays(dynamic value) {
        if (value == null) return null;
        if (value is List) {
          return value.map((e) => e.toString()).toList();
        }
        if (value is String && value.isNotEmpty) {
          return value.split(',').map((e) => e.trim()).toList();
        }
        return [];
      }

      return MerchantModel(
        id: parseInt(json['id']),
        ownerId: parseInt(json['owner_id'].toString()) ?? 0,
        name: json['name']?.toString() ?? '',
        address: json['address']?.toString() ?? '',
        phoneNumber: json['phone_number']?.toString() ?? '',
        status: json['status']?.toString() ?? 'ACTIVE',
        description: json['description']?.toString(),
        logo: json['logo']?.toString(),
        openingTime: json['opening_time']?.toString(),
        closingTime: json['closing_time']?.toString(),
        operatingDays: parseOperatingDays(json['operating_days']),
        productCount: parseInt(json['product_count']),
        orderCount: parseInt(json['order_count']),
        productsSold: parseInt(json['products_sold']),
        totalSales: parseInt(json['total_sales']),
        monthlyRevenue: parseInt(json['monthly_revenue']),
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
            : DateTime.now(),
        updatedAt: json['updated_at'] != null
            ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
            : DateTime.now(),
      );
    } catch (e) {
      // Return a minimal valid merchant in case of error
      return MerchantModel(
        ownerId: 0,
        name: '',
        address: '',
        phoneNumber: '',
        description: null,
        logo: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        productCount: 0,
        orderCount: 0,
        productsSold: 0,
        totalSales: 0,
        monthlyRevenue: 0,
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'owner_id': ownerId,
      'name': name,
      'address': address,
      'phone_number': phoneNumber,
      'status': status,
      'description': description,
      'logo': logo,
      'product_count': productCount,
      'opening_time': openingTime,
      'closing_time': closingTime,
      'operating_days': operatingDays,
      'order_count': orderCount,
      'products_sold': productsSold,
      'total_sales': totalSales,
      'monthly_revenue': monthlyRevenue,
    };
  }

  MerchantModel copyWith({
    int? id,
    int? ownerId,
    String? name,
    String? address,
    String? phoneNumber,
    String? status,
    String? description,
    String? logo,
    int? productCount,
    String? openingTime,
    String? closingTime,
    List<String>? operatingDays,
    int? orderCount,
    int? productsSold,
    int? totalSales,
    int? monthlyRevenue,
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
      description: description ?? this.description,
      logo: logo ?? this.logo,
      productCount: productCount ?? this.productCount,
      openingTime: openingTime ?? this.openingTime,
      closingTime: closingTime ?? this.closingTime,
      operatingDays: operatingDays ?? this.operatingDays,
      orderCount: orderCount ?? this.orderCount,
      productsSold: productsSold ?? this.productsSold,
      totalSales: totalSales ?? this.totalSales,
      monthlyRevenue: monthlyRevenue ?? this.monthlyRevenue,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isActive => status?.toUpperCase() == 'ACTIVE';

  MerchantModel updateStatus(String newStatus) {
    return copyWith(
      status: newStatus,
      updatedAt: DateTime.now(),
    );
  }

  String get formattedPhoneNumber => phoneNumber;

  String get summary => '$name - $address';

  String? get merchantLogoUrl => logo;
  String get merchantName => name;
  String get merchantContact => phoneNumber;
  String? get merchantOpeningHours => openingTime;
  List<String>? get merchantOperatingDays => operatingDays;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MerchantModel &&
        other.id == id &&
        other.ownerId == ownerId &&
        other.name == name &&
        other.address == address &&
        other.phoneNumber == phoneNumber &&
        other.status == status &&
        other.description == description &&
        other.logo == logo;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        ownerId.hashCode ^
        name.hashCode ^
        address.hashCode ^
        phoneNumber.hashCode ^
        status.hashCode ^
        description.hashCode ^
        logo.hashCode;
  }

  @override
  String toString() {
    return 'MerchantModel(id: $id, name: $name, status: $status, description: $description, logo: $logo)';
  }
}

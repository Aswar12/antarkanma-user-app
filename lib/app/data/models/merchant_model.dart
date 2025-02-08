class MerchantModel {
  final int? id;
  final String name;
  final String address;
  final String phoneNumber;
  final String status;
  final String? description;
  final String? logo;
  final String? logoUrl;
  final String? openingTime;
  final String? closingTime;
  final List<String>? operatingDays;
  final double? latitude;
  final double? longitude;
  final double? distance;
  final int? duration;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? stats;
  final int? totalProducts;

  MerchantModel({
    this.id,
    required this.name,
    required this.address,
    required this.phoneNumber,
    this.status = 'active',
    this.description,
    this.logo,
    this.logoUrl,
    this.openingTime,
    this.closingTime,
    this.operatingDays,
    this.latitude,
    this.longitude,
    this.distance,
    this.duration,
    this.createdAt,
    this.updatedAt,
    this.stats,
    this.totalProducts,
  });

  String? get effectiveLogoUrl {
    if (logoUrl != null && logoUrl!.isNotEmpty) {
      if (logoUrl!.startsWith('http://') || logoUrl!.startsWith('https://')) {
        return logoUrl;
      }
    }
    return null;
  }

  int get productCount {
    if (totalProducts != null) return totalProducts!;
    
    if (stats != null) {
      var count = stats!['product_count'];
      if (count == null) return 0;
      if (count is int) return count;
      if (count is String) {
        return int.tryParse(count) ?? 0;
      }
    }
    return 0;
  }
  
  int get totalOrders => stats?['total_orders'] ?? 0;
  double get totalSales => (stats?['total_sales'] ?? 0.0).toDouble();

  factory MerchantModel.fromJson(Map<String, dynamic> json) {
    try {
      List<String>? parseOperatingDays(dynamic value) {
        if (value == null) return null;
        if (value is List) {
          return value.map((e) => e.toString()).toList();
        }
        if (value is String && value.isNotEmpty) {
          return value.split(',').map((e) => e.trim()).toList();
        }
        return null;
      }

      double? parseDouble(dynamic value) {
        if (value == null) return null;
        if (value is double) return value;
        if (value is int) return value.toDouble();
        if (value is String) {
          try {
            return double.parse(value);
          } catch (e) {
            print('Error parsing $value to double: $e');
            return null;
          }
        }
        return null;
      }

      int? parseInt(dynamic value) {
        if (value == null) return null;
        if (value is int) return value;
        if (value is double) return value.toInt();
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
        name: json['name']?.toString() ?? '',
        address: json['address']?.toString() ?? '',
        phoneNumber: json['phone_number']?.toString() ?? '',
        status: json['status']?.toString().toLowerCase() ?? 'active',
        description: json['description']?.toString(),
        logo: json['logo']?.toString(),
        logoUrl: json['logo_url']?.toString(),
        openingTime: json['opening_time']?.toString(),
        closingTime: json['closing_time']?.toString(),
        operatingDays: parseOperatingDays(json['operating_days']),
        latitude: parseDouble(json['latitude']),
        longitude: parseDouble(json['longitude']),
        distance: parseDouble(json['distance']),
        duration: parseInt(json['duration']),
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'].toString())
            : null,
        updatedAt: json['updated_at'] != null
            ? DateTime.tryParse(json['updated_at'].toString())
            : null,
        stats: json['stats'] as Map<String, dynamic>?,
        totalProducts: parseInt(json['total_products']),
      );
    } catch (e) {
      print('Error parsing merchant data: $e');
      print('JSON data: $json');
      return MerchantModel(
        name: 'Error Loading Merchant',
        address: 'Address Unavailable',
        phoneNumber: 'Phone Unavailable',
        status: 'inactive',
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'phone_number': phoneNumber,
      'status': status,
      'description': description,
      'logo': logo,
      'logo_url': logoUrl,
      'opening_time': openingTime,
      'closing_time': closingTime,
      'operating_days': operatingDays,
      'latitude': latitude,
      'longitude': longitude,
      'distance': distance,
      'duration': duration,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'stats': stats,
      'total_products': totalProducts,
    };
  }

  bool get isActive => status.toLowerCase() == 'active';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MerchantModel &&
        other.id == id &&
        other.name == name &&
        other.address == address &&
        other.phoneNumber == phoneNumber &&
        other.status == status &&
        other.description == description &&
        other.logo == logo &&
        other.logoUrl == logoUrl &&
        other.openingTime == openingTime &&
        other.closingTime == closingTime &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.distance == distance &&
        other.duration == duration &&
        other.totalProducts == totalProducts &&
        other.stats.toString() == stats.toString();
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        address.hashCode ^
        phoneNumber.hashCode ^
        status.hashCode ^
        description.hashCode ^
        logo.hashCode ^
        logoUrl.hashCode ^
        openingTime.hashCode ^
        closingTime.hashCode ^
        latitude.hashCode ^
        longitude.hashCode ^
        distance.hashCode ^
        duration.hashCode ^
        totalProducts.hashCode ^
        stats.hashCode;
  }

  @override
  String toString() {
    return 'MerchantModel(id: $id, name: $name, address: $address, status: $status, distance: $distance km, duration: $duration min, productCount: $productCount)';
  }
}

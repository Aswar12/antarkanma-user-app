import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:antarkanma/app/data/models/order_model.dart';
import 'package:antarkanma/app/data/models/user_location_model.dart';

class TransactionModel {
  final String? id;
  final String orderId;
  final String userId;
  final String userLocationId;
  final double totalPrice;
  final double shippingPrice;
  final DateTime? paymentDate;
  final String status; // PENDING, COMPLETED, CANCELED
  final String paymentMethod; // MANUAL, ONLINE
  final String paymentStatus; // PENDING, COMPLETED, FAILED
  final int? rating;
  final String? note;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Relasi
  OrderModel? order;
  UserLocationModel? userLocation;

  TransactionModel({
    this.id,
    required this.orderId,
    required this.userId,
    required this.userLocationId,
    required this.totalPrice,
    required this.shippingPrice,
    this.paymentDate,
    this.status = 'PENDING',
    required this.paymentMethod,
    this.paymentStatus = 'PENDING',
    this.rating,
    this.note,
    this.createdAt,
    this.updatedAt,
    this.order,
    this.userLocation,
  });

  // Getter untuk total harga (termasuk ongkir)
  double get grandTotal => totalPrice + shippingPrice;

  // Formatter untuk harga dalam Rupiah
  String get formattedTotalPrice {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(totalPrice);
  }

  String get formattedShippingPrice {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(shippingPrice);
  }

  String get formattedGrandTotal {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(grandTotal);
  }

  // Konversi ke JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'user_id': userId,
      'user_location_id': userLocationId,
      'total_price': totalPrice,
      'shipping_price': shippingPrice,
      'payment_date': paymentDate?.toIso8601String(),
      'status': status,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      'rating': rating,
      'note': note,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Membuat instance dari JSON
  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'],
      orderId: json['order_id'],
      userId: json['user_id'],
      userLocationId: json['user_location_id'],
      totalPrice: json['total_price'].toDouble(),
      shippingPrice: json['shipping_price'].toDouble(),
      paymentDate: json['payment_date'] != null
          ? DateTime.parse(json['payment_date'])
          : null,
      status: json['status'] ?? 'PENDING',
      paymentMethod: json['payment_method'],
      paymentStatus: json['payment_status'] ?? 'PENDING',
      rating: json['rating'],
      note: json['note'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  // Copy with method
  TransactionModel copyWith({
    String? id,
    String? orderId,
    String? userId,
    String? userLocationId,
    double? totalPrice,
    double? shippingPrice,
    DateTime? paymentDate,
    String? status,
    String? paymentMethod,
    String? paymentStatus,
    int? rating,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
    OrderModel? order,
    UserLocationModel? userLocation,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      userId: userId ?? this.userId,
      userLocationId: userLocationId ?? this.userLocationId,
      totalPrice: totalPrice ?? this.totalPrice,
      shippingPrice: shippingPrice ?? this.shippingPrice,
      paymentDate: paymentDate ?? this.paymentDate,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      rating: rating ?? this.rating,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      order: order ?? this.order,
      userLocation: userLocation ?? this.userLocation,
    );
  }

  // Method untuk mengupdate status transaksi
  TransactionModel updateStatus(String newStatus) {
    return copyWith(
      status: newStatus,
      updatedAt: DateTime.now(),
    );
  }

  // Method untuk mengupdate status pembayaran
  TransactionModel updatePaymentStatus(String newPaymentStatus) {
    return copyWith(
      paymentStatus: newPaymentStatus,
      updatedAt: DateTime.now(),
      paymentDate: newPaymentStatus == 'COMPLETED' ? DateTime.now() : null,
    );
  }

  // Validasi transaksi
  bool validate() {
    return totalPrice > 0 && shippingPrice >= 0;
  }

  // Status-related methods
  String get statusDisplay {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'Menunggu Pembayaran';
      case 'COMPLETED':
        return 'Selesai';
      case 'CANCELED':
        return 'Dibatalkan';
      default:
        return 'Status Tidak Dikenal';
    }
  }

  Color getStatusColor() {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Colors.orange;
      case 'COMPLETED':
        return Colors.green;
      case 'CANCELED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Payment status display
  String get paymentStatusDisplay {
    switch (paymentStatus.toUpperCase()) {
      case 'PENDING':
        return 'Menunggu Pembayaran';
      case 'COMPLETED':
        return 'Pembayaran Selesai';
      case 'FAILED':
        return 'Pembayaran Gagal';
      default:
        return 'Status Pembayaran Tidak Dikenal';
    }
  }

  // Method untuk mengecek apakah transaksi masih bisa dibatalkan
  bool get canBeCanceled {
    return status == 'PENDING' && paymentStatus != 'COMPLETED';
  }

  // Method untuk mendapatkan ringkasan transaksi
  Map<String, dynamic> getSummary() {
    return {
      'transaction_id': id,
      'order_id': orderId,
      'total_price': formattedTotalPrice,
      'shipping_price': formattedShippingPrice,
      'grand_total': formattedGrandTotal,
      'status': statusDisplay,
      'payment_method': paymentMethod,
      'payment_status': paymentStatusDisplay,
      'payment_date': paymentDate,
      'created_at': createdAt,
    };
  }

  // Method untuk mengecek apakah transaksi sudah dibayar
  bool get isPaid => paymentStatus == 'COMPLETED';

  // Method untuk mengecek apakah transaksi sudah selesai
  bool get isCompleted => status == 'COMPLETED';

  // Method untuk mengecek apakah transaksi dibatalkan
  bool get isCanceled => status == 'CANCELED';

  // Method untuk menambahkan rating
  TransactionModel addRating(int newRating) {
    if (newRating < 1 || newRating > 5) {
      throw ArgumentError('Rating harus antara 1 dan 5');
    }
    return copyWith(
      rating: newRating,
      updatedAt: DateTime.now(),
    );
  }

  // Method untuk menambahkan catatan
  TransactionModel addNote(String newNote) {
    return copyWith(
      note: newNote,
      updatedAt: DateTime.now(),
    );
  }

  // Method untuk mendapatkan durasi sejak transaksi dibuat
  String get durationSinceCreated {
    if (createdAt == null) return 'Waktu tidak tersedia';
    final duration = DateTime.now().difference(createdAt!);
    if (duration.inDays > 0) {
      return '${duration.inDays} hari yang lalu';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} jam yang lalu';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes} menit yang lalu';
    } else {
      return 'Baru saja';
    }
  }

  // Method untuk mendapatkan informasi pengiriman
  Map<String, dynamic> getShippingInfo() {
    return {
      'address': userLocation?.address ?? 'Alamat tidak tersedia',
      'city': userLocation?.city ?? 'Kota tidak tersedia',
      'postal_code': userLocation?.postalCode ?? 'Kode pos tidak tersedia',
      'phone_number':
          userLocation?.phoneNumber ?? 'Nomor telepon tidak tersedia',
    };
  }

  // Method untuk mengecek apakah transaksi memerlukan tindakan dari pengguna
  bool get requiresUserAction {
    return status == 'PENDING' && paymentStatus == 'PENDING';
  }

  // Method untuk mendapatkan instruksi pembayaran
  String getPaymentInstructions() {
    switch (paymentMethod.toUpperCase()) {
      case 'MANUAL':
        return 'Silakan transfer ke rekening berikut: [Nomor Rekening]';
      case 'ONLINE':
        return 'Anda akan diarahkan ke halaman pembayaran online';
      default:
        return 'Metode pembayaran tidak dikenal';
    }
  }

  // Method untuk membandingkan dengan transaksi lain
  bool isEqual(TransactionModel other) {
    return id == other.id &&
        orderId == other.orderId &&
        userId == other.userId &&
        userLocationId == other.userLocationId &&
        totalPrice == other.totalPrice &&
        shippingPrice == other.shippingPrice &&
        status == other.status &&
        paymentMethod == other.paymentMethod &&
        paymentStatus == other.paymentStatus;
  }

  // Method untuk mengecek apakah transaksi masih aktif
  bool get isActive {
    return status != 'CANCELED' && status != 'COMPLETED';
  }

  // Method untuk mendapatkan estimasi waktu pengiriman (contoh sederhana)
  String get estimatedDeliveryTime {
    if (status == 'COMPLETED') return 'Pesanan telah diterima';
    if (status == 'CANCELED') return 'Pesanan dibatalkan';
    if (paymentStatus != 'COMPLETED') return 'Menunggu pembayaran';

    // Asumsi pengiriman membutuhkan 2 hari kerja setelah pembayaran
    if (paymentDate != null) {
      final estimatedDate = paymentDate!.add(const Duration(days: 2));
      return DateFormat('dd MMMM yyyy').format(estimatedDate);
    }

    return 'Estimasi belum tersedia';
  }
}

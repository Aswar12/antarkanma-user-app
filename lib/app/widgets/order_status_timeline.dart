import 'package:flutter/material.dart';
import 'package:antarkanma/theme.dart';
import 'package:antarkanma/app/data/models/transaction_model.dart';
import 'package:intl/intl.dart';

class OrderStatusTimeline extends StatelessWidget {
  final TransactionModel transaction;
  final bool isHorizontal;

  const OrderStatusTimeline({
    super.key,
    required this.transaction,
    this.isHorizontal = false,
  });

  // Flow State configuration
  List<Map<String, dynamic>> _getTimelineSteps() {
    // Determine current index based on status
    int currentIndex = _getCurrentStepIndex();

    // Status timestamps - mapping from transaction history if available
    // Currently using the transaction creation time as fallback for pending
    String timeStr = transaction.createdAt != null
        ? DateFormat('HH:mm').format(transaction.createdAt!)
        : '--:--';

    return [
      {
        'title': 'Pesanan Dibuat',
        'subtitle': transaction.status == 'PENDING'
            ? 'Menunggu Konfirmasi'
            : 'Pesanan telah diterima merchant',
        'icon': Icons.receipt_long,
        'time': timeStr,
        'isCompleted': currentIndex >= 0,
        'isActive': currentIndex == 0,
        'isError': transaction.status == 'CANCELED',
      },
      {
        'title': 'Disiapkan',
        'subtitle': 'Merchant sedang menyiapkan makanan',
        'icon': Icons.soup_kitchen,
        'time': currentIndex >= 1 ? 'Diproses' : '',
        'isCompleted': currentIndex >= 1,
        'isActive': currentIndex == 1,
        'isError': false,
      },
      {
        'title': 'Kurir Menuju Merchant',
        'subtitle': 'Kurir sedang dalam perjalanan mengambil pesanan',
        'icon': Icons.sports_motorsports,
        'time': currentIndex >= 2 ? 'Menuju Toko' : '',
        'isCompleted': currentIndex >= 2,
        'isActive': currentIndex == 2,
        'isError': false,
      },
      {
        'title': 'Pesanan Diambil',
        'subtitle': 'Kurir telah mengambil pesanan di merchant',
        'icon': Icons.inventory,
        'time': currentIndex >= 3 ? 'Diambil' : '',
        'isCompleted': currentIndex >= 3,
        'isActive': currentIndex == 3,
        'isError': false,
      },
      {
        'title': 'Kurir Menuju Lokasi',
        'subtitle': 'Kurir sedang mengantarkan pesanan ke lokasimu',
        'icon': Icons.delivery_dining,
        'time': currentIndex >= 4 ? 'Di Jalan' : '',
        'isCompleted': currentIndex >= 4,
        'isActive': currentIndex == 4,
        'isError': false,
      },
      {
        'title': 'Pesanan Selesai',
        'subtitle': 'Pesanan telah sampai tujuan 🎉',
        'icon': Icons.check_circle_outline,
        'time': currentIndex >= 5 ? 'Selesai' : '',
        'isCompleted': currentIndex >= 5,
        'isActive': currentIndex == 5,
        'isError': false,
      },
    ];
  }

  int _getCurrentStepIndex() {
    // 1. Transaction level status completely overrides everything
    if (transaction.status == 'CANCELED') return 0; // Show error on first step
    if (transaction.status == 'COMPLETED') return 5; // All done

    // 2. Courier Status logic
    final cs = transaction.courierStatus.toUpperCase();

    switch (cs) {
      case 'IDLE':
        // Check order status if still pending vs processing
        // Support both underscore and non-underscore formats
        bool isAnyProcessing = transaction.orders.any((o) {
          final status = o.orderStatus.toUpperCase();
          return status == 'PROCESSING' || 
                 status == 'READY_FOR_PICKUP' || 
                 status == 'READYTOPICKUP'; // Legacy support
        });
        return isAnyProcessing ? 1 : 0;
      case 'HEADING_TO_MERCHANT':
        return 2;
      case 'AT_MERCHANT':
        return 3;
      case 'HEADING_TO_CUSTOMER':
        return 4;
      case 'AT_CUSTOMER':
        return 4; // Or 5 if you prefer "arrived" to be its own step
      case 'DELIVERED':
        return 5;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (transaction.status == 'CANCELED') {
      return _buildCanceledState();
    }

    final steps = _getTimelineSteps();

    return Container(
      padding: EdgeInsets.all(Dimenssions.height15),
      decoration: BoxDecoration(
        color: backgroundColor2,
        borderRadius: BorderRadius.circular(Dimenssions.radius15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 10,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Status Pengiriman',
            style: primaryTextStyle.copyWith(
              fontSize: Dimenssions.font16,
              fontWeight: semiBold,
            ),
          ),
          SizedBox(height: Dimenssions.height15),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: steps.length,
            itemBuilder: (context, index) {
              return _buildTimelineStep(steps[index],
                  isLast: index == steps.length - 1);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineStep(Map<String, dynamic> step, {required bool isLast}) {
    bool isCompleted = step['isCompleted'] ?? false;
    bool isActive = step['isActive'] ?? false;
    bool isError = step['isError'] ?? false;

    Color iconColor = Colors.white;
    Color circleColor = secondaryTextColor.withOpacity(0.2);
    Color borderColor = Colors.transparent;

    if (isError) {
      circleColor = alertColor;
    } else if (isActive) {
      circleColor = primaryOrange;
      borderColor = primaryOrange.withOpacity(0.3);
    } else if (isCompleted) {
      circleColor = logoColorSecondary;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline graphics column
          SizedBox(
            width: Dimenssions.width30,
            child: Column(
              children: [
                Container(
                  width: Dimenssions.font24,
                  height: Dimenssions.font24,
                  decoration: BoxDecoration(
                    color: circleColor,
                    shape: BoxShape.circle,
                    border: isActive
                        ? Border.all(color: borderColor, width: 4)
                        : null,
                  ),
                  child: Center(
                    child: Icon(
                      step['icon'],
                      size: Dimenssions.font14,
                      color: isCompleted || isActive
                          ? Colors.white
                          : secondaryTextColor,
                    ),
                  ),
                ),
                if (!isLast) ...[
                  Expanded(
                    child: Container(
                      width: 2,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? logoColorSecondary
                            : secondaryTextColor.withOpacity(0.2),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          SizedBox(width: Dimenssions.width10),

          // Content column
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: isLast ? 0 : Dimenssions.height20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        step['title'],
                        style: primaryTextStyle.copyWith(
                          fontSize: Dimenssions.font14,
                          fontWeight:
                              isActive || isCompleted ? semiBold : medium,
                          color: isError
                              ? alertColor
                              : (isCompleted || isActive
                                  ? primaryTextColor
                                  : secondaryTextColor),
                        ),
                      ),
                      if (step['time'].toString().isNotEmpty &&
                          (isActive || isCompleted))
                        Text(
                          step['time'],
                          style: secondaryTextStyle.copyWith(
                            fontSize: Dimenssions.font12,
                            fontWeight: isActive ? semiBold : regular,
                            color:
                                isActive ? primaryOrange : secondaryTextColor,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: Dimenssions.height4),
                  Text(
                    step['subtitle'],
                    style: secondaryTextStyle.copyWith(
                      fontSize: Dimenssions.font12,
                      color: isActive ? primaryTextColor : secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCanceledState() {
    return Container(
      padding: EdgeInsets.all(Dimenssions.height15),
      decoration: BoxDecoration(
        color: alertColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(Dimenssions.radius15),
        border: Border.all(color: alertColor.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(Dimenssions.height10),
            decoration: BoxDecoration(
              color: alertColor,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.cancel,
                color: Colors.white, size: Dimenssions.font20),
          ),
          SizedBox(width: Dimenssions.width15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pesanan Dibatalkan',
                  style: primaryTextStyle.copyWith(
                    fontWeight: semiBold,
                    color: alertColor,
                    fontSize: Dimenssions.font14,
                  ),
                ),
                SizedBox(height: Dimenssions.height4),
                Text(
                  'Transaksi ini telah dibatalkan secara otomatis atau oleh sistem pengguna.',
                  style:
                      secondaryTextStyle.copyWith(fontSize: Dimenssions.font12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

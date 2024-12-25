import 'package:antarkanma/theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OrderManagementPage extends StatefulWidget {
  const OrderManagementPage({super.key});

  @override
  State<OrderManagementPage> createState() => OrderManagementPageState();
}

class OrderManagementPageState extends State<OrderManagementPage> {
  // Sample order data
  final List<Map<String, dynamic>> orders = [
    {
      'orderId': 'ORD001',
      'customerName': 'John Doe',
      'totalPrice': 250000,
      'orderDate': DateTime.now(),
      'status': 'Pending',
      'customerInfo': {
        'phone': '081234567890',
        'email': 'john@example.com',
      },
      'products': [
        {
          'name': 'Product A',
          'quantity': 2,
          'price': 100000,
          'image': 'assets/image_shoes.png',
        },
        {
          'name': 'Product B',
          'quantity': 1,
          'price': 50000,
          'image': 'assets/image_shoes2.png',
        },
      ],
      'paymentMethod': 'Transfer Bank',
      'shippingAddress': 'Jl. Example No. 123, Kota Example, 12345',
    },
    // Add more sample orders here
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Manajemen Pesanan',
          style: primaryTextStyle.copyWith(color: logoColor),
        ),
        backgroundColor: transparentColor,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(Dimenssions.width16),
        itemCount: orders.length,
        itemBuilder: (context, index) => _buildOrderCard(orders[index]),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    return Card(
      margin: EdgeInsets.only(bottom: Dimenssions.height16),
      child: InkWell(
        onTap: () => _showOrderDetails(order),
        child: Padding(
          padding: EdgeInsets.all(Dimenssions.width16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order #${order['orderId']}',
                    style: primaryTextStyle.copyWith(
                      fontSize: Dimenssions.font16,
                      fontWeight: bold,
                    ),
                  ),
                  _buildStatusChip(order['status']),
                ],
              ),
              SizedBox(height: Dimenssions.height12),
              Row(
                children: [
                  Icon(Icons.person_outline, size: 20, color: subtitleColor),
                  SizedBox(width: Dimenssions.width8),
                  Text(
                    order['customerName'],
                    style: secondaryTextStyle,
                  ),
                ],
              ),
              SizedBox(height: Dimenssions.height8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 20, color: subtitleColor),
                  SizedBox(width: Dimenssions.width8),
                  Text(
                    DateFormat('dd MMM yyyy, HH:mm').format(order['orderDate']),
                    style: secondaryTextStyle,
                  ),
                ],
              ),
              SizedBox(height: Dimenssions.height8),
              Row(
                children: [
                  Icon(Icons.monetization_on_outlined,
                      size: 20, color: subtitleColor),
                  SizedBox(width: Dimenssions.width8),
                  Text(
                    'Rp ${NumberFormat('#,###').format(order['totalPrice'])}',
                    style: priceTextStyle,
                  ),
                ],
              ),
              SizedBox(height: Dimenssions.height12),
              _buildActionButtons(order),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color chipColor;
    switch (status.toLowerCase()) {
      case 'pending':
        chipColor = Colors.orange;
        break;
      case 'processed':
        chipColor = Colors.blue;
        break;
      case 'completed':
        chipColor = Colors.green;
        break;
      case 'cancelled':
        chipColor = Colors.red;
        break;
      default:
        chipColor = Colors.grey;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: chipColor,
          fontSize: Dimenssions.font12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> order) {
    if (order['status'].toLowerCase() == 'pending') {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: () => _showRejectDialog(order),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: BorderSide(color: Colors.red),
            ),
            child: Text('Tolak'),
          ),
          SizedBox(width: Dimenssions.width12),
          ElevatedButton(
            onPressed: () => _showProcessDialog(order),
            style: ElevatedButton.styleFrom(
              backgroundColor: logoColor,
            ),
            child: Text('Proses'),
          ),
        ],
      );
    }
    return SizedBox.shrink();
  }

  void _showOrderDetails(Map<String, dynamic> order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: EdgeInsets.all(Dimenssions.width16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: EdgeInsets.only(bottom: Dimenssions.height20),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  'Detail Pesanan #${order['orderId']}',
                  style: primaryTextStyle.copyWith(
                    fontSize: Dimenssions.font20,
                    fontWeight: bold,
                  ),
                ),
                SizedBox(height: Dimenssions.height20),
                _buildDetailSection(
                  'Informasi Pelanggan',
                  [
                    'Nama: ${order['customerName']}',
                    'Telepon: ${order['customerInfo']['phone']}',
                    'Email: ${order['customerInfo']['email']}',
                  ],
                ),
                _buildDetailSection(
                  'Daftar Produk',
                  order['products'].map<String>((product) {
                    return '${product['name']} (${product['quantity']}x) - Rp ${NumberFormat('#,###').format(product['price'])}';
                  }).toList(),
                ),
                _buildDetailSection(
                  'Informasi Pembayaran',
                  [
                    'Metode: ${order['paymentMethod']}',
                    'Total: Rp ${NumberFormat('#,###').format(order['totalPrice'])}',
                  ],
                ),
                _buildDetailSection(
                  'Alamat Pengiriman',
                  [order['shippingAddress']],
                ),
                SizedBox(height: Dimenssions.height20),
                if (order['status'].toLowerCase() == 'pending')
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _showRejectDialog(order);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: BorderSide(color: Colors.red),
                            padding: EdgeInsets.symmetric(
                                vertical: Dimenssions.height12),
                          ),
                          child: Text('Tolak Pesanan'),
                        ),
                      ),
                      SizedBox(width: Dimenssions.width12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _showProcessDialog(order);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: logoColor,
                            padding: EdgeInsets.symmetric(
                                vertical: Dimenssions.height12),
                          ),
                          child: Text('Proses Pesanan'),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<String> details) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: primaryTextStyle.copyWith(
            fontSize: Dimenssions.font16,
            fontWeight: bold,
          ),
        ),
        SizedBox(height: Dimenssions.height8),
        Container(
          padding: EdgeInsets.all(Dimenssions.width12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: details
                .map(
                  (detail) => Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Text(detail, style: secondaryTextStyle),
                  ),
                )
                .toList(),
          ),
        ),
        SizedBox(height: Dimenssions.height16),
      ],
    );
  }

  void _showProcessDialog(Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Proses Pesanan'),
        content: Text('Apakah Anda yakin ingin memproses pesanan ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              // Handle process order
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: logoColor),
            child: Text('Proses'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Tolak Pesanan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Apakah Anda yakin ingin menolak pesanan ini?'),
            SizedBox(height: Dimenssions.height16),
            TextField(
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Alasan penolakan (opsional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              // Handle reject order
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Tolak'),
          ),
        ],
      ),
    );
  }
}

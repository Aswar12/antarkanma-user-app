import 'package:antarkanma/theme.dart';
import 'package:flutter/material.dart';

class MerchantOrderPage extends StatefulWidget {
  const MerchantOrderPage({super.key});

  @override
  State<MerchantOrderPage> createState() => MerchantOrderPageState();
}

class MerchantOrderPageState extends State<MerchantOrderPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Sample data for orders
  final List<Map<String, dynamic>> orders = [
    {
      'id': 1,
      'items': [
        {'name': 'Product 1', 'quantity': 2, 'price': 10000},
        {'name': 'Product 2', 'quantity': 1, 'price': 20000},
      ],
      'totalPrice': 40000,
      'status': 'Pending',
      'customer': {
        'name': 'John Doe',
        'phone': '1234567890',
        'email': 'john@example.com'
      },
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Daftar Pesanan',
            style: primaryTextStyle.copyWith(color: logoColor)),
        backgroundColor: transparentColor,
        elevation: 0,
        leading: IconButton(
          icon:
              Icon(Icons.menu, color: logoColor, size: Dimenssions.iconSize24),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_outlined,
                color: logoColor, size: Dimenssions.iconSize20),
            onPressed: () {
              // Navigate to notification page
            },
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: Dimenssions.width10),
            child: CircleAvatar(
              radius: Dimenssions.width20,
              backgroundImage: const AssetImage('assets/image_profile.png'),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(Dimenssions.width16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  return _buildOrderCard(orders[index]);
                },
              ),
            ),
            SizedBox(height: Dimenssions.height20),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: Dimenssions.height8),
      child: ListTile(
        title: Text('Order #${order['id']}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...order['items'].map<Widget>((item) {
              return Text(
                  '${item['name']} (x${item['quantity']}) - Rp ${item['price']}');
            }).toList(),
            Text('Total: Rp ${order['totalPrice']}'),
            Text('Status: ${order['status']}'),
            Text('Customer: ${order['customer']['name']}'),
            Text('Phone: ${order['customer']['phone']}'),
            Text('Email: ${order['customer']['email']}'),
          ],
        ),
        onTap: () {
          // Navigate to order details page
        },
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: Dimenssions.width8),
            child: ElevatedButton(
              onPressed: () {
                // Add action for filtering orders
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: logoColor,
                padding: EdgeInsets.symmetric(
                  vertical: Dimenssions.height12,
                  horizontal: Dimenssions.width16,
                ),
              ),
              child: Text(
                'Filter Pesanan',
                style: primaryTextStyle.copyWith(
                  color: Colors.white,
                  fontSize: Dimenssions.font14,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: Dimenssions.width8),
            child: ElevatedButton(
              onPressed: () {
                // Add action for adding new order
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: logoColor,
                padding: EdgeInsets.symmetric(
                  vertical: Dimenssions.height12,
                  horizontal: Dimenssions.width16,
                ),
              ),
              child: Text(
                'Tambah Pesanan',
                style: primaryTextStyle.copyWith(
                  color: Colors.white,
                  fontSize: Dimenssions.font14,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

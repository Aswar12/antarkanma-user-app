import 'package:antarkanma/theme.dart';
import 'package:flutter/material.dart';

class MerchantOrderPage extends StatefulWidget {
  const MerchantOrderPage({super.key});

  @override
  State<MerchantOrderPage> createState() => MerchantOrderPageState();
}

class MerchantOrderPageState extends State<MerchantOrderPage>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  TabController? _tabController;

  // Sample data for orders
  final List<Map<String, dynamic>> orders = [
    {
      'id': 'ORD001',
      'items': [
        {
          'name': 'Product 1',
          'quantity': 2,
          'price': 10000,
          'image': 'assets/image_shoes.png'
        },
        {
          'name': 'Product 2',
          'quantity': 1,
          'price': 20000,
          'image': 'assets/image_shoes2.png'
        },
      ],
      'totalPrice': 40000,
      'status': 'Pending',
      'orderDate': '2024-01-20 14:30',
      'customer': {
        'name': 'John Doe',
        'phone': '1234567890',
        'email': 'john@example.com',
        'address': 'Jl. Example No. 123'
      },
    },
    {
      'id': 'ORD002',
      'items': [
        {
          'name': 'Product 3',
          'quantity': 1,
          'price': 15000,
          'image': 'assets/image_shoes3.png'
        },
      ],
      'totalPrice': 15000,
      'status': 'Processing',
      'orderDate': '2024-01-20 13:15',
      'customer': {
        'name': 'Jane Smith',
        'phone': '0987654321',
        'email': 'jane@example.com',
        'address': 'Jl. Sample No. 456'
      },
    },
  ];

  String? _getOrderCustomerName(Map<String, dynamic> order) {
    try {
      return order['customer']?['name'] as String?;
    } catch (e) {
      return null;
    }
  }

  String? _getOrderCustomerPhone(Map<String, dynamic> order) {
    try {
      return order['customer']?['phone'] as String?;
    } catch (e) {
      return null;
    }
  }

  String? _getOrderCustomerAddress(Map<String, dynamic> order) {
    try {
      return order['customer']?['address'] as String?;
    } catch (e) {
      return null;
    }
  }

  List<Map<String, dynamic>> _getOrderItems(Map<String, dynamic> order) {
    try {
      return List<Map<String, dynamic>>.from(order['items'] ?? []);
    } catch (e) {
      return [];
    }
  }

  String? _getItemName(Map<String, dynamic> item) {
    try {
      return item['name'] as String?;
    } catch (e) {
      return null;
    }
  }

  int? _getItemQuantity(Map<String, dynamic> item) {
    try {
      return item['quantity'] as int?;
    } catch (e) {
      return null;
    }
  }

  int? _getItemPrice(Map<String, dynamic> item) {
    try {
      return item['price'] as int?;
    } catch (e) {
      return null;
    }
  }

  String? _getItemImage(Map<String, dynamic> item) {
    try {
      return item['image'] as String?;
    } catch (e) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Widget _buildProductImage(Map<String, dynamic> item) {
    final imagePath = _getItemImage(item);
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Dimenssions.radius8),
        color: logoColor.withOpacity(0.1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Dimenssions.radius8),
        child: imagePath != null
            ? Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.image_not_supported, color: logoColor);
                },
              )
            : Icon(Icons.shopping_bag, color: logoColor),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_tabController == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: backgroundColor1,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildOrderStatistics(),
          _buildStatusTabs(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOrderList('All'),
                _buildOrderList('Pending'),
                _buildOrderList('Processing'),
                _buildOrderList('Completed'),
                _buildOrderList('Cancelled'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      title: Text(
        'Daftar Pesanan',
        style: primaryTextStyle.copyWith(
          color: logoColor,
          fontSize: Dimenssions.font18,
          fontWeight: semiBold,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.search, color: logoColor),
          onPressed: () {},
        ),
        IconButton(
          icon: Icon(Icons.filter_list, color: logoColor),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildOrderStatistics() {
    return Container(
      padding: EdgeInsets.all(Dimenssions.width16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Hari Ini', '5', Colors.blue),
          _buildStatItem('Pending', '2', Colors.orange),
          _buildStatItem('Proses', '1', Colors.green),
          _buildStatItem('Selesai', '2', Colors.purple),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: primaryTextStyle.copyWith(
            fontSize: Dimenssions.font20,
            fontWeight: bold,
            color: color,
          ),
        ),
        SizedBox(height: Dimenssions.height4),
        Text(
          label,
          style: secondaryTextStyle.copyWith(
            fontSize: Dimenssions.font12,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusTabs() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: logoColor,
        unselectedLabelColor: subtitleColor,
        indicatorColor: logoColor,
        tabs: const [
          Tab(text: 'Semua'),
          Tab(text: 'Pending'),
          Tab(text: 'Proses'),
          Tab(text: 'Selesai'),
          Tab(text: 'Batal'),
        ],
      ),
    );
  }

  Widget _buildOrderList(String status) {
    var filteredOrders = status == 'All'
        ? orders
        : orders.where((order) => order['status'] == status).toList();

    return ListView.builder(
      padding: EdgeInsets.all(Dimenssions.width16),
      itemCount: filteredOrders.length,
      itemBuilder: (context, index) {
        return _buildOrderCard(filteredOrders[index]);
      },
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    return Card(
      margin: EdgeInsets.only(bottom: Dimenssions.height16),
      color: backgroundColor1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimenssions.radius12),
      ),
      child: Column(
        children: [
          _buildOrderHeader(order),
          _buildOrderContent(order),
          _buildOrderFooter(order),
        ],
      ),
    );
  }

  Widget _buildOrderHeader(Map<String, dynamic> order) {
    return Container(
      padding: EdgeInsets.all(Dimenssions.width16),
      decoration: BoxDecoration(
        color: backgroundColor1,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(Dimenssions.radius12),
          topRight: Radius.circular(Dimenssions.radius12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Order #${order['id']}',
                style: primaryTextStyle.copyWith(
                  fontWeight: semiBold,
                ),
              ),
              SizedBox(height: Dimenssions.height4),
              Text(
                order['orderDate'],
                style: secondaryTextStyle.copyWith(
                  fontSize: Dimenssions.font12,
                ),
              ),
            ],
          ),
          _buildStatusBadge(order['status']),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color badgeColor;
    switch (status.toLowerCase()) {
      case 'pending':
        badgeColor = Colors.orange;
        break;
      case 'processing':
        badgeColor = Colors.blue;
        break;
      case 'completed':
        badgeColor = Colors.green;
        break;
      case 'cancelled':
        badgeColor = Colors.red;
        break;
      default:
        badgeColor = Colors.grey;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Dimenssions.width12,
        vertical: Dimenssions.height4,
      ),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(Dimenssions.radius12),
        border: Border.all(color: badgeColor.withOpacity(0.5)),
      ),
      child: Text(
        status,
        style: primaryTextStyle.copyWith(
          color: badgeColor,
          fontSize: Dimenssions.font12,
          fontWeight: medium,
        ),
      ),
    );
  }

  Widget _buildOrderContent(Map<String, dynamic> order) {
    return Container(
      padding: EdgeInsets.all(Dimenssions.width16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: logoColor.withOpacity(0.1),
                child: Icon(Icons.person_outline, color: logoColor),
              ),
              SizedBox(width: Dimenssions.width12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getOrderCustomerName(order) ?? 'Unknown Customer',
                      style: primaryTextStyle.copyWith(fontWeight: medium),
                    ),
                    SizedBox(height: Dimenssions.height4),
                    Text(
                      _getOrderCustomerPhone(order) ?? 'No Phone',
                      style: secondaryTextStyle,
                    ),
                    Text(
                      _getOrderCustomerAddress(order) ?? 'No Address',
                      style: secondaryTextStyle,
                    ),
                  ],
                ),
              ),
            ],
          ),
          Divider(height: Dimenssions.height24),
          Text(
            'Daftar Pesanan:',
            style: primaryTextStyle.copyWith(fontWeight: medium),
          ),
          SizedBox(height: Dimenssions.height8),
          ..._getOrderItems(order).map<Widget>((item) {
            final name = _getItemName(item) ?? 'Unnamed Product';
            final quantity = _getItemQuantity(item)?.toString() ?? '0';
            final price = _getItemPrice(item)?.toString() ?? '0';

            return Padding(
              padding: EdgeInsets.only(bottom: Dimenssions.height12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        _buildProductImage(item),
                        SizedBox(width: Dimenssions.width12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: primaryTextStyle.copyWith(
                                  fontWeight: medium,
                                ),
                              ),
                              SizedBox(height: Dimenssions.height4),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: Dimenssions.width8,
                                  vertical: Dimenssions.height4,
                                ),
                                decoration: BoxDecoration(
                                  color: logoColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(
                                      Dimenssions.radius8),
                                ),
                                child: Text(
                                  'x$quantity',
                                  style: primaryTextStyle.copyWith(
                                    color: logoColor,
                                    fontWeight: medium,
                                    fontSize: Dimenssions.font12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'Rp $price',
                    style: primaryTextStyle.copyWith(
                      fontWeight: medium,
                      color: logoColor,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          Divider(height: Dimenssions.height24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Pembayaran',
                style: primaryTextStyle.copyWith(fontWeight: semiBold),
              ),
              Text(
                'Rp ${order['totalPrice']}',
                style: primaryTextStyle.copyWith(
                  fontWeight: bold,
                  color: logoColor,
                  fontSize: Dimenssions.font16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderFooter(Map<String, dynamic> order) {
    return Container(
      padding: EdgeInsets.all(Dimenssions.width16),
      decoration: BoxDecoration(
        color: backgroundColor1,
        border: Border(
          top: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {},
              icon:
                  Icon(Icons.visibility_outlined, size: Dimenssions.iconSize20),
              label: Text('Detail'),
              style: OutlinedButton.styleFrom(
                backgroundColor: backgroundColor1,
                foregroundColor: logoColor,
                side: BorderSide(color: logoColor),
                padding: EdgeInsets.symmetric(vertical: Dimenssions.height12),
              ),
            ),
          ),
          SizedBox(width: Dimenssions.width12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: Icon(Icons.check_circle_outline,
                  size: Dimenssions.iconSize20),
              label: Text('Proses'),
              style: ElevatedButton.styleFrom(
                backgroundColor: backgroundColor1,
                foregroundColor: logoColor,
                padding: EdgeInsets.symmetric(vertical: Dimenssions.height12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

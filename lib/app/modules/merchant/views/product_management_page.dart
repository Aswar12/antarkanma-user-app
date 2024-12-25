import 'package:antarkanma/theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'product_form_page.dart';

class ProductManagementPage extends StatefulWidget {
  const ProductManagementPage({super.key});

  @override
  State<ProductManagementPage> createState() => ProductManagementPageState();
}

class ProductManagementPageState extends State<ProductManagementPage> {
  final List<Map<String, dynamic>> products = [
    {
      'id': 1,
      'name': 'Produk A',
      'price': 150000,
      'status': true,
      'image': 'assets/image_shoes.png',
      'description': 'Deskripsi produk A',
      'category': 'Kategori 1',
      'variants': [
        {
          'id': 1,
          'name': 'Ukuran',
          'value': 'XL',
          'price_adjustment': 10000,
          'status': 'ACTIVE'
        },
        {
          'id': 2,
          'name': 'Ukuran',
          'value': 'L',
          'price_adjustment': 5000,
          'status': 'ACTIVE'
        }
      ],
    },
  ];

  String searchQuery = '';
  String selectedCategory = 'Semua';
  String selectedSort = 'Baru';
  bool showActiveOnly = false;

  List<Map<String, dynamic>> get filteredProducts {
    return products.where((product) {
      if (searchQuery.isNotEmpty &&
          !product['name'].toLowerCase().contains(searchQuery.toLowerCase())) {
        return false;
      }
      if (selectedCategory != 'Semua' &&
          product['category'] != selectedCategory) {
        return false;
      }
      if (showActiveOnly && !product['status']) {
        return false;
      }
      return true;
    }).toList()
      ..sort((a, b) {
        switch (selectedSort) {
          case 'A-Z':
            return a['name'].compareTo(b['name']);
          case 'Z-A':
            return b['name'].compareTo(a['name']);
          case '↑':
            return b['price'].compareTo(a['price']);
          case '↓':
            return a['price'].compareTo(b['price']);
          default:
            return 0;
        }
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Manajemen Produk',
          style: primaryTextStyle.copyWith(color: logoColor),
        ),
        backgroundColor: transparentColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: Dimenssions.width12,
              vertical: Dimenssions.height8,
            ),
            child: Column(
              children: [
                SizedBox(
                  height: 36,
                  child: TextField(
                    onChanged: (value) => setState(() => searchQuery = value),
                    style: TextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'Cari produk...',
                      hintStyle: TextStyle(fontSize: 12),
                      prefixIcon:
                          Icon(Icons.search, color: logoColor, size: 18),
                      contentPadding: EdgeInsets.zero,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide(color: logoColor),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 32,
                        child: DropdownButtonFormField<String>(
                          value: selectedCategory,
                          isDense: true,
                          isExpanded: true,
                          itemHeight: null,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black,
                          ),
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.symmetric(horizontal: 6),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300),
                            ),
                            constraints: BoxConstraints(maxHeight: 32),
                          ),
                          items: ['Semua', 'Kategori 1', 'Kategori 2']
                              .map((cat) => DropdownMenuItem(
                                    value: cat,
                                    child: Text(cat,
                                        style: TextStyle(fontSize: 12)),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null)
                              setState(() => selectedCategory = value);
                          },
                        ),
                      ),
                    ),
                    SizedBox(width: 6),
                    Expanded(
                      child: SizedBox(
                        height: 32,
                        child: DropdownButtonFormField<String>(
                          value: selectedSort,
                          isDense: true,
                          isExpanded: true,
                          itemHeight: null,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black,
                          ),
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.symmetric(horizontal: 6),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade300),
                            ),
                            constraints: BoxConstraints(maxHeight: 32),
                          ),
                          items: ['Baru', 'A-Z', 'Z-A', '↑', '↓']
                              .map((sort) => DropdownMenuItem(
                                    value: sort,
                                    child: Text(sort,
                                        style: TextStyle(fontSize: 12)),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null)
                              setState(() => selectedSort = value);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                Transform.scale(
                  scale: 0.8,
                  child: ListTile(
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Produk Aktif',
                      style: TextStyle(fontSize: 12),
                    ),
                    trailing: Switch(
                      value: showActiveOnly,
                      onChanged: (value) =>
                          setState(() => showActiveOnly = value),
                      activeColor: logoColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                // Implement refresh logic
              },
              child: filteredProducts.isEmpty
                  ? _buildEmptyState()
                  : GridView.builder(
                      padding: EdgeInsets.all(Dimenssions.width12),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.7,
                        crossAxisSpacing: Dimenssions.width8,
                        mainAxisSpacing: Dimenssions.height8,
                      ),
                      itemCount: filteredProducts.length,
                      itemBuilder: (context, index) {
                        final product = filteredProducts[index];
                        return _buildProductCard(product);
                      },
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToProductForm(),
        backgroundColor: logoColor,
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Belum ada produk',
            style: primaryTextStyle.copyWith(
              fontSize: 16,
              fontWeight: semiBold,
            ),
          ),
          SizedBox(height: 8),
          Text('Tambahkan produk pertama Anda', style: secondaryTextStyle),
        ],
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _navigateToProductForm(product: product),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Image.asset(
                      product['image'],
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                if (product['variants']?.isNotEmpty ?? false)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: logoColor.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${product['variants'].length} Varian',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product['name'],
                          style: primaryTextStyle.copyWith(
                            fontSize: 12,
                            fontWeight: semiBold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Rp ${product['price']}',
                          style: priceTextStyle.copyWith(fontSize: 12),
                        ),
                      ],
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: product['status']
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          product['status'] ? 'Aktif' : 'Nonaktif',
                          style: TextStyle(
                            color:
                                product['status'] ? Colors.green : Colors.red,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToProductForm({Map<String, dynamic>? product}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductFormPage(product: product),
      ),
    );

    if (result != null) {
      setState(() {
        if (product != null) {
          final index = products.indexWhere((p) => p['id'] == product['id']);
          if (index != -1) {
            products[index] = {...product, ...result};
          }
        } else {
          products.add({
            'id': products.length + 1,
            ...result,
          });
        }
      });
    }
  }
}

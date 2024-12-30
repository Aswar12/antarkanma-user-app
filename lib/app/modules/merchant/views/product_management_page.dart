import 'package:antarkanma/theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:antarkanma/app/modules/merchant/controllers/merchant_product_controller.dart';
import 'package:antarkanma/app/data/models/product_model.dart';
import 'package:antarkanma/app/modules/merchant/views/merchant_product_detail_page.dart';
import 'product_form_page.dart';

class ProductManagementPage extends GetView<MerchantProductController> {
  const ProductManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor1,
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
              horizontal: Dimenssions.width16,
              vertical: Dimenssions.height12,
            ),
            color: backgroundColor1,
            child: Column(
              children: [
                SizedBox(
                  height: 40,
                  child: TextField(
                    onChanged: (value) => controller.searchProducts(value),
                    style: TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Cari produk...',
                      hintStyle: TextStyle(fontSize: 14),
                      prefixIcon: Icon(Icons.search, color: logoColor, size: 20),
                      contentPadding: EdgeInsets.zero,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: logoColor),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: DropdownButtonFormField<String>(
                          value: 'Semua',
                          isDense: true,
                          isExpanded: true,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black,
                          ),
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.symmetric(horizontal: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          items: ['Semua', 'Kategori 1', 'Kategori 2']
                              .map((cat) => DropdownMenuItem(
                                    value: cat,
                                    child: Text(cat, style: TextStyle(fontSize: 14)),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              controller.filterByCategory(value);
                            }
                          },
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: DropdownButtonFormField<String>(
                          value: 'Baru',
                          isDense: true,
                          isExpanded: true,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black,
                          ),
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.symmetric(horizontal: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          items: ['Baru', 'A-Z', 'Z-A', '↑', '↓']
                              .map((sort) => DropdownMenuItem(
                                    value: sort,
                                    child: Text(sort, style: TextStyle(fontSize: 14)),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              controller.sortProducts(value);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                Transform.scale(
                  scale: 0.9,
                  child: ListTile(
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Produk Aktif',
                      style: TextStyle(fontSize: 14),
                    ),
                    trailing: Obx(() => Switch(
                          value: controller.showActiveOnly.value,
                          onChanged: controller.toggleActiveOnly,
                          activeColor: logoColor,
                        )),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return Center(child: CircularProgressIndicator());
              }

              if (controller.errorMessage.value.isNotEmpty) {
                return Center(
                  child: Text(
                    controller.errorMessage.value,
                    style: TextStyle(color: Colors.red),
                  ),
                );
              }

              if (controller.filteredProducts.isEmpty) {
                return _buildEmptyState();
              }

              return RefreshIndicator(
                onRefresh: () async => controller.fetchProducts(),
                child: GridView.builder(
                  padding: EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.68,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: controller.filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = controller.filteredProducts[index];
                    return _buildProductCard(product);
                  },
                ),
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToProductForm(),
        backgroundColor: logoColor,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey.shade300),
          SizedBox(height: 16),
          Text(
            'Belum ada produk',
            style: primaryTextStyle.copyWith(
              fontSize: 18,
              fontWeight: semiBold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Tambahkan produk pertama Anda',
            style: secondaryTextStyle.copyWith(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(ProductModel product) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _navigateToProductForm(product: product),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              child: AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      product.firstImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset(
                          'assets/image_shoes.png',
                          fit: BoxFit.cover,
                        );
                      },
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      left: 8,
                      right: 8,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: primaryTextStyle.copyWith(
                              fontSize: 14,
                              fontWeight: semiBold,
                              color: Colors.white,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4),
                          Text(
                            product.formattedPrice,
                            style: priceTextStyle.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: product.isActive
                              ? Colors.green.withOpacity(0.9)
                              : Colors.red.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          product.isActive ? 'Aktif' : 'Nonaktif',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (product.category != null)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: logoColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        product.category!.name,
                        style: TextStyle(
                          color: logoColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.star, size: 14, color: Colors.amber),
                      SizedBox(width: 4),
                      Text(
                        '${product.averageRating.toStringAsFixed(1)}',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        ' (${product.totalReviews})',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      Spacer(),
                      if (product.variants.isNotEmpty)
                        Row(
                          children: [
                            Icon(Icons.style, size: 14, color: Colors.grey),
                            SizedBox(width: 4),
                            Text(
                              '${product.variants.length}',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToProductForm({ProductModel? product}) async {
    if (product != null) {
      final result = await Get.to(() => MerchantProductDetailPage(product: product));
      if (result != null) {
        controller.fetchProducts();
      }
    } else {
      final result = await Get.to(() => ProductFormPage(product: null));
      if (result != null) {
        controller.fetchProducts();
      }
    }
  }
}

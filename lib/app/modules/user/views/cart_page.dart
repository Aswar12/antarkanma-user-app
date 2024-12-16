// ignore_for_file: deprecated_member_use

import 'package:antarkanma/app/controllers/cart_controller.dart';
import 'package:antarkanma/app/controllers/user_main_controller.dart';
import 'package:antarkanma/app/data/models/cart_item_model.dart';
import 'package:antarkanma/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class CartPage extends GetView<CartController> {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor3,
      appBar: AppBar(
        toolbarHeight: Dimenssions.height45,
        title: Text(
          'Keranjang',
          style: primaryTextStyle.copyWith(
            // Menggunakan style dari theme
            fontSize: Dimenssions.font20,
            fontWeight: regular,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white, // Mengubah warna background
        foregroundColor: primaryTextColor,
        iconTheme: IconThemeData(
          color: logoColorSecondary, // Mengubah warna icon
        ), // Mengubah warna teks dan icon
        actions: [
          IconButton(
            icon: Icon(
              Icons.delete_outline,
              size: Dimenssions.iconSize24,
            ),
            onPressed: () => _showClearCartDialog(),
          ),
        ],
        elevation: 0.5,
        shape: Border(
          // Optional: menambahkan border bottom
          bottom: BorderSide(
            color: Colors.grey.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      body: GetBuilder<CartController>(
        builder: (controller) {
          if (controller.merchantItems.isEmpty) {
            return _buildEmptyCart();
          }
          return _buildCartList();
        },
      ),
      bottomNavigationBar: _buildCheckoutBar(),
    );
  }

  void _showClearCartDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Hapus Semua?'),
        content: const Text('Yakin ingin mengosongkan keranjang?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              controller.clearCart();
              Get.back();
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 100,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 20),
          Text(
            'Keranjang Belanja Kosong',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // Jika berada dalam UserMainPage
              Get.find<UserMainController>().currentIndex.value = 0;

              // Jika berada di CartPage standalone
              Get.offAllNamed('/main');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: logoColorSecondary,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Mulai Belanja',
                style: primaryTextStyle.copyWith(color: backgroundColor1)),
          ),
        ],
      ),
    );
  }

  Widget _buildCartList() {
    return ListView.builder(
      padding: EdgeInsets.all(Dimenssions.height15),
      itemCount: controller.merchantItems.length,
      itemBuilder: (context, index) {
        final merchantId = controller.merchantItems.keys.elementAt(index);
        final merchantItems = controller.merchantItems[merchantId];
        if (merchantItems != null) {
          return _buildMerchantSection(merchantId, merchantItems);
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildMerchantSection(int merchantId, List<CartItemModel> items) {
    return Card(
      color: backgroundColor2,
      margin: EdgeInsets.only(bottom: Dimenssions.height15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
                horizontal: Dimenssions.width20,
                vertical: Dimenssions.height10),
            child: Text(
              items.first.merchant.name,
              style: primaryTextStyle.copyWith(
                  fontSize: Dimenssions.font18, fontWeight: semiBold),
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) =>
                _buildCartItem(merchantId, items[index], index),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(int merchantId, CartItemModel item, int index) {
    return Dismissible(
      key: Key('$merchantId-${item.product.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        HapticFeedback.mediumImpact();
        return await Get.dialog<bool>(
          AlertDialog(
            title: const Text('Hapus Item?'),
            content:
                const Text('Yakin ingin menghapus item ini dari keranjang?'),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () {
                  controller.removeFromCart(merchantId, index);
                  Get.back(result: true);
                },
                child: const Text('Hapus'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        ScaffoldMessenger.of(Get.context!).showSnackBar(
          SnackBar(
            content: Text('${item.product.name} dihapus dari keranjang'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                controller.undoRemove(merchantId, index, item);
              },
            ),
          ),
        );
      },
      child: Semantics(
        label: 'Geser ke kiri untuk menghapus ${item.product.name}',
        child: Stack(
          children: [
            Tooltip(
              message: 'Geser ke kiri untuk menghapus ${item.product.name}',
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: Dimenssions.height20,
                  vertical: Dimenssions.height10,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Gambar produk
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: item.product.imageUrls.isNotEmpty
                          ? Image.network(
                              item.product.imageUrls.first,
                              width: Dimenssions.height90,
                              height: Dimenssions.height90,
                              fit: BoxFit.cover,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return const Center(
                                    child: CircularProgressIndicator());
                              },
                              errorBuilder: (context, error, stackTrace) =>
                                  Image.asset(
                                'assets/image_shoes.png',
                                width: Dimenssions.height90,
                                height: Dimenssions.height90,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Image.asset(
                              'assets/image_shoes.png',
                              width: Dimenssions.height90,
                              height: Dimenssions.height90,
                              fit: BoxFit.cover,
                            ),
                    ),
                    SizedBox(width: Dimenssions.width15),
                    // Informasi produk
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.product.name,
                            style: primaryTextStyle.copyWith(
                              fontWeight: semiBold,
                              fontSize: Dimenssions.font18,
                            ),
                          ),
                          SizedBox(height: Dimenssions.height5),

                          // Menampilkan variant jika ada
                          if (item.selectedVariant != null) ...[
                            Row(
                              children: [
                                Text(
                                  '${item.selectedVariant!.name}: ',
                                  style: primaryTextStyle.copyWith(
                                    fontSize: Dimenssions.font14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  item.selectedVariant!.value,
                                  style: primaryTextStyle.copyWith(
                                    fontSize: Dimenssions.font14,
                                    color: Colors.grey[600],
                                    fontWeight: medium,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: Dimenssions.height5),
                          ],

                          Text(
                            NumberFormat.currency(
                              locale: 'id',
                              symbol: 'Rp ',
                              decimalDigits: 0,
                            ).format(item.totalPrice),
                            style: TextStyle(
                              color: logoColorSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Kontrol kuantitas
            Positioned(
              bottom: Dimenssions.height15,
              left: Dimenssions.height100 + Dimenssions.width80,
              child: Container(
                height: Dimenssions.height35,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(
                      8), // Mengubah radius menjadi lebih kecil
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          bottomLeft: Radius.circular(8),
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            bottomLeft: Radius.circular(8),
                          ),
                          onTap: () =>
                              controller.decrementQuantity(merchantId, index),
                          child: Container(
                            width: Dimenssions.height35,
                            height: Dimenssions.height35,
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.remove,
                              size: 18,
                              color: logoColorSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: Dimenssions.height35,
                      alignment: Alignment.center,
                      child: Text(
                        '${item.quantity}',
                        style: primaryTextStyle.copyWith(
                          fontSize: Dimenssions.font16,
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(8),
                            bottomRight: Radius.circular(8),
                          ),
                          onTap: () =>
                              controller.incrementQuantity(merchantId, index),
                          child: Container(
                            width: Dimenssions.height35,
                            height: Dimenssions.height35,
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.add,
                              size: 18,
                              color: logoColorSecondary,
                            ),
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

  Widget _buildCheckoutBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(Dimenssions.radius15),
            topRight: Radius.circular(Dimenssions.radius15),
          ),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Belanjaanta',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  GetBuilder<CartController>(
                    builder: (controller) => Text(
                      NumberFormat.currency(
                        locale: 'id',
                        symbol: 'Rp ',
                        decimalDigits: 0,
                      ).format(controller.totalPrice),
                      style: TextStyle(
                        fontSize: 18,
                        color: logoColorSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            GetBuilder<CartController>(
              builder: (controller) => ElevatedButton(
                onPressed: controller.itemCount > 0
                    ? () {
                        Get.toNamed('/main/checkout', arguments: {
                          'merchantItems': controller.merchantItems,
                          'type': 'cart',
                        });
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: controller.itemCount > 0
                      ? logoColorSecondary
                      : Colors.grey,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Checkout',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ignore_for_file: deprecated_member_use

import 'package:antarkanma/app/controllers/cart_controller.dart';
import 'package:antarkanma/app/controllers/user_main_controller.dart';
import 'package:antarkanma/app/data/models/cart_item_model.dart';
import 'package:antarkanma/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final CartController cartController = Get.find<CartController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor3,
      appBar: AppBar(
        title: Text(
          'Keranjang',
          style: primaryTextStyle.copyWith(
            fontSize: Dimenssions.font20,
            fontWeight: regular,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: primaryTextColor,
        iconTheme: IconThemeData(
          color: logoColorSecondary,
        ),
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
          return _buildCartList(controller);
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
              cartController.clearCart();
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
              Get.find<UserMainController>().currentIndex.value = 0;
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

  Widget _buildCartList(CartController controller) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: EdgeInsets.all(Dimenssions.height15),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  alignment: Alignment.center,
                  child: Text(
                    'Geser item ke kiri untuk menghapus',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                ...controller.merchantItems.entries.map((entry) {
                  final merchantId = entry.key;
                  final merchantItems = entry.value;
                  return _buildMerchantSection(merchantId, merchantItems);
                }).toList(),
              ],
            ),
          ),
        );
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
          Column(
            children: List.generate(items.length, (index) {
              return _buildCartItem(merchantId, items[index], index);
            }),
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
        color: Colors.red.shade400,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.delete_outline,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  'Geser untuk Hapus',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 20),
          ],
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red.shade400,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.delete_outline,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  'Geser untuk Hapus',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 20),
          ],
        ),
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
                  cartController.removeFromCart(merchantId, index);
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
                cartController.undoRemove(merchantId, index, item);
              },
            ),
          ),
        );
      },
      child: Container(
        color: Colors.white,
        child: Stack(
          children: [
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 20,
                color: Colors.red.withOpacity(0.07),
                child: Center(
                  child: Icon(
                    Icons.chevron_left,
                    color: logoColorSecondary,
                    size: 20,
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: Dimenssions.height20,
                vertical: Dimenssions.height10,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: item.product.imageUrls.isNotEmpty
                        ? Image.network(
                            item.product.imageUrls.first,
                            width: Dimenssions.height90,
                            height: Dimenssions.height90,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
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
          ],
        ),
      ),
    );
  }

  Widget _buildCheckoutBar() {
    return SafeArea(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: Dimenssions.width15,
          vertical: Dimenssions.height10,
        ),
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

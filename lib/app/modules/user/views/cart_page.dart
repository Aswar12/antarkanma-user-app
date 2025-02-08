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
          return SafeArea(
            child: Container(
              color: backgroundColor3,
              child: _buildCartList(controller),
            ),
          );
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
          Container(
            constraints: BoxConstraints(maxWidth: 200),
            child: ElevatedButton(
              onPressed: () {
                final userMainController = Get.find<UserMainController>();
                userMainController.changePage(0);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: logoColorSecondary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('Mulai Belanja',
                  style: primaryTextStyle.copyWith(color: backgroundColor1)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartList(CartController controller) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(Dimenssions.height10),
      child: Column(
        children: controller.merchantItems.entries.map((entry) {
          final merchantId = entry.key;
          final merchantItems = entry.value;
          return _buildMerchantSection(merchantId, merchantItems);
        }).toList(),
      ),
    );
  }

  Widget _buildMerchantSection(int merchantId, List<CartItemModel> items) {
    return Card(
      color: backgroundColor2,
      margin: EdgeInsets.only(bottom: Dimenssions.height10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
                horizontal: Dimenssions.width15, vertical: Dimenssions.height8),
            child: Text(
              items.first.merchant.name,
              style: primaryTextStyle.copyWith(
                  fontSize: Dimenssions.font16, fontWeight: semiBold),
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
      key: UniqueKey(),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red.shade400,
        child: const Icon(
          Icons.delete_outline,
          color: Colors.white,
          size: 24,
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
      child: Container(
        color: Colors.white,
        child: Stack(
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: Dimenssions.height15,
                vertical: Dimenssions.height8,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Transform.scale(
                    scale: 1.1,
                    child: Checkbox(
                      value: item.isSelected,
                      onChanged: (bool? value) {
                        controller.toggleItemSelection(merchantId, index);
                      },
                      activeColor: logoColorSecondary,
                      side: BorderSide(
                        color: logoColorSecondary,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  SizedBox(width: Dimenssions.width10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: item.product.imageUrls.isNotEmpty
                        ? Image.network(
                            item.product.imageUrls.first,
                            width: Dimenssions.height70,
                            height: Dimenssions.height70,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                  child: CircularProgressIndicator());
                            },
                            errorBuilder: (context, error, stackTrace) =>
                                Image.asset(
                              'assets/image_shoes.png',
                              width: Dimenssions.height70,
                              height: Dimenssions.height70,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Image.asset(
                            'assets/image_shoes.png',
                            width: Dimenssions.height70,
                            height: Dimenssions.height70,
                            fit: BoxFit.cover,
                          ),
                  ),
                  SizedBox(width: Dimenssions.width12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item.product.name,
                          style: primaryTextStyle.copyWith(
                            fontWeight: semiBold,
                            fontSize: Dimenssions.font14,
                          ),
                        ),
                        if (item.selectedVariant != null) ...[
                          SizedBox(height: Dimenssions.height4),
                          Row(
                            children: [
                              Text(
                                '${item.selectedVariant!.name}: ',
                                style: primaryTextStyle.copyWith(
                                  fontSize: Dimenssions.font12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                item.selectedVariant!.value,
                                style: primaryTextStyle.copyWith(
                                  fontSize: Dimenssions.font12,
                                  color: Colors.grey[600],
                                  fontWeight: medium,
                                ),
                              ),
                            ],
                          ),
                        ],
                        SizedBox(height: Dimenssions.height4),
                        Text(
                          NumberFormat.currency(
                            locale: 'id',
                            symbol: 'Rp ',
                            decimalDigits: 0,
                          ).format(item.totalPrice),
                          style: TextStyle(
                            color: logoColorSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: Dimenssions.font14,
                          ),
                        ),
                        SizedBox(height: Dimenssions.height6),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.grey[300]!,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              InkWell(
                                onTap: () => controller.decrementQuantity(
                                    merchantId, index),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  child: Icon(
                                    Icons.remove,
                                    size: 16,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  border: Border.symmetric(
                                    vertical: BorderSide(
                                      color: Colors.grey[300]!,
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  '${item.quantity}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap: () => controller.incrementQuantity(
                                    merchantId, index),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  child: Icon(
                                    Icons.add,
                                    size: 16,
                                    color: Colors.black,
                                  ),
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
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 15,
                decoration: BoxDecoration(
                  color: logoColorSecondary.withOpacity(0.1),
                  border: Border(
                    left: BorderSide(
                      color: logoColorSecondary.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.chevron_left,
                    color: logoColorSecondary,
                    size: 16,
                  ),
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
                    'Total Belanja',
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
                      ).format(controller.selectedItemsTotal),
                      style: TextStyle(
                        fontSize: 18,
                        color: logoColorSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            GetBuilder<CartController>(
              builder: (controller) => SizedBox(
                width: 180, // Fixed width for the button
                child: ElevatedButton(
                  onPressed: controller.selectedItemCount > 0
                      ? () {
                          Map<int, List<CartItemModel>> groupedItems = {};

                          // Group selected items by merchant ID
                          for (var item in controller.selectedItems) {
                            final merchantId = item.merchant.id ?? 0;
                            if (!groupedItems.containsKey(merchantId)) {
                              groupedItems[merchantId] = [];
                            }
                            groupedItems[merchantId]!.add(item);
                          }

                          Get.toNamed('/usermain/checkout', arguments: {
                            'merchantItems': groupedItems,
                            'type': 'cart',
                          });
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: controller.selectedItemCount > 0
                        ? logoColorSecondary
                        : Colors.grey,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Checkout (${controller.selectedItemCount})',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
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

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../controllers/manual_order_controller.dart';
import 'manual_order_item_widget.dart';

// Reuse colors
const Color kJastipNavy = Color(0xFF1E3A8A);
const Color kJastipOrange = Color(0xFFF97316);
const Color kBgLight = Color(0xFFF1F5F9);
const Color kSlate400 = Color(0xFF94A3B8);

class ManualOrderPage extends GetView<ManualOrderController> {
  const ManualOrderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgLight,
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.9),
        elevation: 0,
        centerTitle: true,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: Color(0xFF475569), size: 20),
            onPressed: () => Get.back(),
          ),
        ),
        title: const Text(
          'Jastip / Belanja',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: kJastipNavy,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey[200], height: 1),
        ),
      ),
      body: Stack(
        children: [
          // Main Scrollable Content
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
                16, 16, 16, 120), // Bottom padding for fixed footer
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                const SizedBox(height: 16),

                // Dynamic List of Stores
                Obx(() => ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: controller.stores.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 24),
                      itemBuilder: (context, index) {
                        return _buildStoreCard(
                            context, index, controller.stores[index]);
                      },
                    )),

                const SizedBox(height: 24),
                _buildAddStoreButton(),

                const SizedBox(height: 32),
                _buildDeliverySection(),
              ],
            ),
          ),

          // Fixed Bottom Footer
          Align(
            alignment: Alignment.bottomCenter,
            child: _buildBottomBar(context),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.shopping_bag_outlined,
              color: kJastipOrange, size: 20),
        ),
        const SizedBox(width: 12),
        const Text(
          'Mau Titip Apa Hari Ini?',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _buildStoreCard(
      BuildContext context, int storeIndex, JastipStore store) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Store Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'TOKO #${storeIndex + 1}',
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: kSlate400,
              ),
            ),
            if (controller.stores.length > 1)
              InkWell(
                onTap: () => controller.removeStore(storeIndex),
                child: const Padding(
                  padding: EdgeInsets.all(4.0),
                  child: Text('Hapus Toko',
                      style: TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ),
              )
          ],
        ),
        const SizedBox(height: 8),

        // Store Info Input Section
        Container(
          padding: const EdgeInsets.all(
              14), // Reduced from 20 to 14 (~30% less internal space, making it look smaller/compact)
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20), // Slightly smaller radius
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildFormInput(
                label: 'Nama Toko / Tempat',
                icon: Icons.store_rounded,
                hint: 'Contoh: Sate Padang Simpang 5',
                controller: store.storeNameController,
                fontSize: 12, // Smaller font
              ),
              const SizedBox(height: 12),
              _buildFormInput(
                label: 'Alamat / Lokasi Toko (Opsional)', // Added Optional
                icon: Icons.location_on_rounded,
                hint: 'Boleh dikosongkan',
                controller: store.storeAddressController,
                fontSize: 12, // Smaller font
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Items for this Store
        Obx(() => ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: store.items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, itemIndex) {
                return ManualOrderItemWidget(
                  item: store.items[itemIndex],
                  index: itemIndex,
                  onRemove: () => store.removeItem(itemIndex),
                  onPickImage: () =>
                      controller.pickImage(storeIndex, itemIndex),
                );
              },
            )),

        const SizedBox(height: 16),
        _buildAddItemButton(store),
      ],
    );
  }

  Widget _buildDeliverySection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lokasi Pengantaran (Tujuan Akhir)',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.blueGrey[400],
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: controller.selectLocation,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on_rounded, color: kJastipOrange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Obx(() => Text(
                          controller.deliveryAddress.value,
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontWeight: FontWeight.w600,
                            color: kJastipNavy,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )),
                  ),
                  const Text(
                    'Ubah',
                    style: TextStyle(
                      color: kJastipOrange,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
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

  Widget _buildFormInput({
    required String label,
    required IconData icon,
    required String hint,
    required TextEditingController controller,
    double fontSize = 14, // Default 14
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: Colors.blueGrey[400],
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC), // slate-50
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 2), // Slightly more compact vertical
          child: Row(
            children: [
              Icon(icon, color: kSlate400, size: fontSize + 8),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: controller,
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: fontSize,
                    color: const Color(0xFF0F172A),
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: hint,
                    hintStyle: const TextStyle(color: kSlate400),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddItemButton(JastipStore store) {
    return InkWell(
      onTap: store.addItem,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey[300]!,
            width: 1,
          ),
          color: Colors.white,
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, color: Colors.blueGrey[400], size: 18),
              const SizedBox(width: 8),
              Text(
                'Tambah Barang',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.blueGrey[400],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddStoreButton() {
    return InkWell(
      onTap: controller.addStore,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: kJastipNavy.withOpacity(0.2),
            width: 2,
            style: BorderStyle.none, // dashed workaround not easy, using solid
          ),
          color: kJastipNavy.withOpacity(0.05),
        ),
        // Dashed border effect
        child: CustomPaint(
          painter: _DashedRectPainter(
              color: kJastipNavy.withOpacity(0.3), strokeWidth: 2, gap: 5),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.store_rounded, color: kJastipNavy),
                  const SizedBox(width: 8),
                  const Text(
                    'Tambah Toko / Tempat Lain',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: kJastipNavy,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          border: Border(top: BorderSide(color: Colors.grey[200]!)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ]),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: kJastipNavy,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'TOTAL ESTIMASI',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Obx(() => Text(
                          NumberFormat.currency(
                                  locale: 'id', symbol: 'Rp ', decimalDigits: 0)
                              .format(controller.totalEstimatedPrice.value),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Plus Jakarta Sans',
                          ),
                        )),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            InkWell(
              onTap: controller.submitOrder,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                decoration: BoxDecoration(
                  color: kJastipOrange,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: kJastipOrange.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: const [
                    Text(
                      'Pesan',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded,
                        color: Colors.white, size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  final double strokeWidth;
  final Color color;
  final double gap;

  _DashedRectPainter(
      {this.strokeWidth = 2.0, this.color = Colors.red, this.gap = 5.0});

  @override
  void paint(Canvas canvas, Size size) {
    Paint dashedPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    double x = size.width;
    double y = size.height;

    Path _topPath = getDashedPath(
      a: const Point(0, 0),
      b: Point(x, 0),
      gap: gap,
    );

    Path _rightPath = getDashedPath(
      a: Point(x, 0),
      b: Point(x, y),
      gap: gap,
    );

    Path _bottomPath = getDashedPath(
      a: Point(0, y),
      b: Point(x, y),
      gap: gap,
    );

    Path _leftPath = getDashedPath(
      a: const Point(0, 0),
      b: Point(0, y),
      gap: gap,
    );

    canvas.drawPath(_topPath, dashedPaint);
    canvas.drawPath(_rightPath, dashedPaint);
    canvas.drawPath(_bottomPath, dashedPaint);
    canvas.drawPath(_leftPath, dashedPaint);
  }

  Path getDashedPath({
    required Point<double> a,
    required Point<double> b,
    required double gap,
  }) {
    Size size = Size(b.x - a.x, b.y - a.y);
    Path path = Path();
    path.moveTo(a.x, a.y);
    bool shouldDraw = true;
    Point<double> currentPoint = Point(a.x, a.y);

    num radians = atan(size.height / size.width);

    num dx =
        cos(radians) * gap < 0 ? cos(radians) * gap * -1 : cos(radians) * gap;

    num dy =
        sin(radians) * gap < 0 ? sin(radians) * gap * -1 : sin(radians) * gap;

    while (currentPoint.x <= b.x && currentPoint.y <= b.y) {
      shouldDraw
          ? path.lineTo(currentPoint.x, currentPoint.y)
          : path.moveTo(currentPoint.x, currentPoint.y);
      shouldDraw = !shouldDraw;
      currentPoint = Point(
        currentPoint.x + dx,
        currentPoint.y + dy,
      );
    }
    return path;
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

// Re-added Point class because it's used by _DashedRectPainter 
// AND I removed "import 'dart:math'" previously but now I need it? 
// Wait, I see "import 'dart:math'" at the top. 
// If 'dart:math' has Point, then I don't need this custom class.
// But dart:math Point is usually Point<T>.
// If I use dart:math, I should remove this class to avoid conflict.
// In the previous step I removed the custom class AND the import.
// This file HAS 'import dart:math'.
// So I should NOT include the class definition at the bottom if dart:math is imported.
// I will check if dart:math covers Point<double>. Yes it does.
// So I will REMOVE the custom class from this file content before writing.

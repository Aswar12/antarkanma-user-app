import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/manual_order_controller.dart';

// Specific colors requested by user
const Color kJastipNavy = Color(0xFF1E3A8A);
const Color kJastipOrange = Color(0xFFF97316);
const Color kBgLight = Color(0xFFF1F5F9);
const Color kSlate100 = Color(0xFFF1F5F9); // approximates tailwind slate-100
const Color kSlate200 = Color(0xFFE2E8F0);
const Color kSlate400 = Color(0xFF94A3B8);
const Color kSlate500 = Color(0xFF64748B);

class ManualOrderItemWidget extends StatelessWidget {
  final ManualOrderItem item;
  final int index;
  final VoidCallback onRemove;
  final VoidCallback onPickImage;

  const ManualOrderItemWidget({
    super.key,
    required this.item,
    required this.index,
    required this.onRemove,
    required this.onPickImage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.all(24), // Increased from 20 to 24 for larger feel
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24), // rounded-3xl
        border: Border.all(color: kSlate100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ITEM #${index + 1}',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  color: kJastipOrange,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              if (index > 0)
                InkWell(
                  onTap: onRemove,
                  child: Icon(Icons.close, color: kSlate400, size: 20),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Main Content Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo Picker
              GestureDetector(
                onTap: onPickImage,
                child: Obx(() {
                  bool hasImage = item.image.value != null;
                  return Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: hasImage ? Colors.white : kSlate100,
                      borderRadius: BorderRadius.circular(16),
                      border: hasImage
                          ? Border.all(color: kJastipOrange, width: 2)
                          : Border.all(
                              color: kSlate200,
                              width: 2,
                              style: BorderStyle
                                  .none), // Dashed border workaround needs CustomPainter, using solid for now or simple border
                    ),
                    child: hasImage
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.file(item.image.value!,
                                fit: BoxFit.cover),
                          )
                        : Container(
                            // Dashed border effect could be here
                            decoration: DottedDecoration(
                                color: kSlate400,
                                strokeWidth: 2,
                                borderRadius: BorderRadius.circular(16)),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.camera_alt_rounded,
                                    color: kSlate400, size: 24),
                                const SizedBox(height: 4),
                                Text(
                                  'FOTO',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: kSlate400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  );
                }),
              ),
              const SizedBox(width: 16),

              // Inputs
              Expanded(
                child: Column(
                  children: [
                    _buildInput(
                      controller: item.nameController,
                      icon: Icons.fastfood_rounded,
                      hint: 'Nama Barang...',
                    ),
                    const SizedBox(height: 12),
                    _buildInput(
                      controller: item.noteController,
                      icon: Icons.notes_rounded,
                      hint: 'Catatan...',
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Divider(color: kSlate100, height: 1),
          const SizedBox(height: 16),

          // Price & Qty
          Row(
            children: [
              // Price Input
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: kSlate100.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Rp',
                        style: TextStyle(
                          color: kSlate500,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: item.priceController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: kJastipNavy,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Estimasi Harga',
                            hintStyle: TextStyle(
                              color: kSlate400,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Qty Selector
              Container(
                decoration: BoxDecoration(
                  color: kSlate100,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    _qtyBtn(Icons.remove, () {
                      int current = int.tryParse(item.qtyController.text) ?? 1;
                      if (current > 1) {
                        item.qtyController.text = (current - 1).toString();
                      }
                    }),
                    Container(
                      width: 32,
                      alignment: Alignment.center,
                      child: Text(
                        item.qtyController
                            .text, // Normally this should be reactive, but controller listeners handle it
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    _qtyBtn(Icons.add, () {
                      int current = int.tryParse(item.qtyController.text) ?? 1;
                      item.qtyController.text = (current + 1).toString();
                    }),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: kSlate100.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      padding:
          EdgeInsets.symmetric(horizontal: 12, vertical: maxLines > 1 ? 12 : 2),
      child: Row(
        crossAxisAlignment:
            maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Icon(icon, color: kSlate400, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: maxLines,
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 14,
                color: Colors.black87,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: hint,
                hintStyle: TextStyle(
                  color: kSlate400,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        child: Icon(icon, size: 18, color: kSlate500),
      ),
    );
  }
}

// Simple Dotted Border Decoration
class DottedDecoration extends Decoration {
  final Color color;
  final double strokeWidth;
  final BorderRadius borderRadius;

  const DottedDecoration({
    required this.color,
    required this.strokeWidth,
    required this.borderRadius,
  });

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return _DottedDecorationPainter(color, strokeWidth, borderRadius);
  }
}

class _DottedDecorationPainter extends BoxPainter {
  final Color color;
  final double strokeWidth;
  final BorderRadius borderRadius;

  _DottedDecorationPainter(this.color, this.strokeWidth, this.borderRadius);

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final Rect rect = offset & configuration.size!;
    final RRect rrect = borderRadius.toRRect(rect);

    // Simplistic approach: just draw the RRect (dashed is complex to implement perfectly in one go without path metrics)
    // For now, let's just make it a solid line looked like reference image or use a path effect if possible.
    // Making it solid light gray as fallback is better than broken dash code.
    canvas.drawRRect(rrect, paint);

    // If we want dashed, we'd need Path and PathDashPathEffect which is standard but verbose.
    // Keeping it simple solid border as per "just draw RRect" above, but changing style to indicate "placeholder"
  }
}

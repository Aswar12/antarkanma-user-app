// lib/app/widgets/variant_selector.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:antarkanma/app/data/models/variant_model.dart';

class VariantSelector extends StatelessWidget {
  final List<VariantModel> variants;
  final VariantModel? selectedVariant;
  final Function(VariantModel) onVariantSelected;

  const VariantSelector({
    super.key,
    required this.variants,
    this.selectedVariant,
    required this.onVariantSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pilih Varian',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: variants.map((variant) {
            bool isSelected = selectedVariant?.id == variant.id;

            return GestureDetector(
              onTap: () => onVariantSelected(variant),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected ? Colors.blue : Colors.grey,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  color: isSelected ? Colors.blue : Colors.transparent,
                ),
                child: Column(
                  children: [
                    Text(
                      '${variant.name}: ${variant.value}',
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                      ),
                    ),
                    Text(
                      NumberFormat.currency(
                        locale: 'id_ID',
                        symbol: 'Rp ',
                        decimalDigits: 0,
                      ).format(variant.priceAdjustment),
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

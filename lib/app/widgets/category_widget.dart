import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:antarkanma/app/controllers/homepage_controller.dart';
import 'package:antarkanma/app/services/category_service.dart';
import 'package:antarkanma/theme.dart';

class CategoryWidget extends StatelessWidget {
  const CategoryWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final HomePageController homeController = Get.find<HomePageController>();
    final CategoryService categoryService = Get.find<CategoryService>();

    // Force load categories if empty
    if (categoryService.categories.isEmpty) {
      categoryService.loadCategories();
    }

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor1,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Obx(() {
        if (categoryService.isLoading.value) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(
            horizontal: Dimenssions.width15,
            vertical: Dimenssions.height5,
          ),
          child: Row(
            children: [
              _buildCategoryItem("Semua", homeController),
              ...categoryService.categories
                  .map((category) =>
                      _buildCategoryItem(category.name, homeController))
                  .toList(),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildCategoryItem(String category, HomePageController controller) {
    return Container(
      margin: EdgeInsets.only(right: Dimenssions.width10),
      child: Obx(() {
        bool isSelected = controller.selectedCategory.value == category;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => controller.selectedCategory.value = category,
            borderRadius: BorderRadius.circular(Dimenssions.radius15),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: Dimenssions.width15,
                vertical: Dimenssions.height5,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? logoColorSecondary.withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(Dimenssions.radius15),
                border: Border.all(
                  color: isSelected
                      ? logoColorSecondary
                      : secondaryTextColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                category,
                style: primaryTextStyle.copyWith(
                  color: isSelected ? logoColorSecondary : secondaryTextColor,
                  fontSize: Dimenssions.font14,
                  fontWeight: isSelected ? semiBold : regular,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

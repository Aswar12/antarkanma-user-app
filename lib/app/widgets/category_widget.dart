import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:antarkanma/app/controllers/homepage_controller.dart';
import 'package:antarkanma/app/services/category_service.dart';
import 'package:antarkanma/theme.dart';

class CategoryWidget extends StatefulWidget {
  const CategoryWidget({Key? key}) : super(key: key);

  @override
  State<CategoryWidget> createState() => _CategoryWidgetState();
}

class _CategoryWidgetState extends State<CategoryWidget> {
  final HomePageController homeController = Get.find<HomePageController>();
  final CategoryService categoryService = Get.find<CategoryService>();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (categoryService.categories.isEmpty) {
        categoryService.getCategories(); // Updated method name
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildCategoryItem(String category) {
    return Container(
      margin: EdgeInsets.only(right: Dimenssions.width10),
      child: Obx(() {
        bool isSelected = homeController.selectedCategory.value == category;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              homeController.updateSelectedCategory(category);
              _scrollController.animateTo(
                0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            },
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

  @override
  Widget build(BuildContext context) {
    return Obx(() {
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
        child: categoryService.isLoading.value
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                ),
              )
            : SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(
                  horizontal: Dimenssions.width15,
                ),
                child: Row(
                  children: [
                    if (homeController.selectedCategory.value != "Semua")
                      _buildCategoryItem(homeController.selectedCategory.value),
                    _buildCategoryItem("Semua"),
                    ...categoryService.categories
                        .where((category) =>
                            category.name !=
                            homeController.selectedCategory.value)
                        .map((category) => _buildCategoryItem(category.name))
                        .toList(),
                  ],
                ),
              ),
      );
    });
  }
}

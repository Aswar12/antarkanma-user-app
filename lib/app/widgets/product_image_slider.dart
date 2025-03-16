import 'package:antarkanma/app/utils/image_viewer_page.dart';
import 'package:antarkanma/app/widgets/cached_image_view.dart';
import 'package:antarkanma/theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class ProductImageSlider extends StatelessWidget {
  final List<String> imageUrls;
  final int currentIndex;
  final Function(int) onPageChanged;
  final String productId;

  static const List<String> PLACEHOLDER_IMAGES = [
    'assets/image_shoes.png',
    'assets/image_shoes2.png',
    'assets/image_shoes3.png',
  ];

  final bool enableInfiniteScroll;
  final bool enableAutoPlay;
  final Duration autoPlayInterval;
  final double indicatorBottomPosition;

  const ProductImageSlider({
    super.key,
    required this.imageUrls,
    required this.currentIndex,
    required this.onPageChanged,
    required this.productId,
    this.enableInfiniteScroll = false,
    this.enableAutoPlay = true,
    this.autoPlayInterval = const Duration(seconds: 3),
    this.indicatorBottomPosition = 40,
  });

  @override
  Widget build(BuildContext context) {
    final List<String> displayImages =
        imageUrls.isEmpty ? PLACEHOLDER_IMAGES : imageUrls;

    return Stack(
      children: [
        // Main Image Carousel
        CarouselSlider.builder(
          itemCount: displayImages.length,
          options: CarouselOptions(
            height: double.infinity,
            viewportFraction: 1.0,
            enlargeCenterPage: false,
            enableInfiniteScroll: enableInfiniteScroll,
            autoPlayInterval: autoPlayInterval,
            scrollPhysics: const BouncingScrollPhysics(),
            onPageChanged: (index, _) => onPageChanged(index),
          ),
          itemBuilder: (context, index, realIndex) {
            return _buildImageSliderItem(
              imageUrl: displayImages[index],
              index: index,
              displayImages: displayImages,
            );
          },
        ),
        // Image Indicator
        _buildImageIndicator(displayImages.length),
      ],
    );
  }

  Widget _buildImageSliderItem({
    required String imageUrl,
    required int index,
    required List<String> displayImages,
  }) {
    return GestureDetector(
      onTap: () {
        Get.to(
          ImageViewerPage(
            imageUrls: displayImages,
            initialIndex: index,
            heroTagPrefix: '${productId}_$index',
          ),
          transition: Transition.zoom,
        );
      },
      child: Hero(
        tag: 'product_image_${productId}_$index',
        child: Container(
          color: backgroundColor3,
          child: CachedImageView(
            imageUrl: imageUrl,
            placeholder: PLACEHOLDER_IMAGES[0],
          ),
        ),
      ),
    );
  }

  Widget _buildImageIndicator(int imageCount) {
    return Positioned(
      bottom: indicatorBottomPosition,
      left: 0,
      right: 0,
      child: Center(
        child: AnimatedSmoothIndicator(
          activeIndex: currentIndex,
          count: imageCount,
          effect: ExpandingDotsEffect(
            dotWidth: Dimenssions.width8,
            dotHeight: Dimenssions.height8,
            spacing: Dimenssions.width6,
            activeDotColor: logoColorSecondary,
            dotColor: backgroundColor1.withOpacity(0.5),
          ),
        ),
      ),
    );
  }
}

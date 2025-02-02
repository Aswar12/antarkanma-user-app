import 'package:antarkanma/app/utils/image_viewer_page.dart';
import 'package:antarkanma/app/widgets/cached_image_view.dart';
import 'package:antarkanma/theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

/// A widget that displays a carousel of product images with lazy loading,
/// image caching, and interactive features like zooming and indicators.
class ProductImageSlider extends StatelessWidget {
  /// List of image URLs to display in the carousel
  final List<String> imageUrls;

  /// Current active index in the carousel
  final int currentIndex;

  /// Callback function when page changes
  final Function(int) onPageChanged;

  /// Unique identifier for the product
  final String productId;

  /// Default placeholder images when no images are provided
  static const List<String> PLACEHOLDER_IMAGES = [
    'assets/image_shoes.png',
    'assets/image_shoes2.png',
    'assets/image_shoes3.png',
  ];

  /// Whether to enable infinite scrolling
  final bool enableInfiniteScroll;

  /// Whether to enable auto play
  final bool enableAutoPlay;

  /// Duration between auto play transitions
  final Duration autoPlayInterval;

  /// Position of the indicator from bottom
  final double indicatorBottomPosition;

  ProductImageSlider({
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
        CarouselSlider(
          options: CarouselOptions(
            height: double.infinity,
            viewportFraction: 1.0,
            enlargeCenterPage: false,
            enableInfiniteScroll: enableInfiniteScroll,
            autoPlayInterval: autoPlayInterval,
            scrollPhysics: const BouncingScrollPhysics(),
            onPageChanged: (index, _) => onPageChanged(index),
          ),
          items: [
            for (var i = 0; i < displayImages.length; i++)
              _buildImageSliderItem(
                imageUrl: displayImages[i],
                index: i,
                displayImages: displayImages,
              ),
          ],
        ),
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
          decoration: BoxDecoration(
            color: backgroundColor3,
          ),
          child: CachedImageView(
            imageUrl: imageUrl,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
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

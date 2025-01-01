import 'package:antarkanma/app/utils/image_viewer_page.dart';
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

  const ProductImageSlider({
    Key? key,
    required this.imageUrls,
    required this.currentIndex,
    required this.onPageChanged,
    required this.productId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<String> displayImages =
        imageUrls.isEmpty ? PLACEHOLDER_IMAGES : imageUrls;

    return Stack(
      children: [
        CarouselSlider.builder(
          itemCount: displayImages.length,
          options: CarouselOptions(
            height: double.infinity,
            viewportFraction: 1.0,
            enlargeCenterPage: false,
            autoPlay: displayImages.length > 1,
            autoPlayInterval: const Duration(seconds: 3),
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
        _buildImageIndicator(displayImages.length),
      ],
    );
  }

  Widget _buildImageSliderItem({
    required String imageUrl,
    required int index,
    required List<String> displayImages,
  }) {
    final String uniqueId = '${productId}_${DateTime.now().millisecondsSinceEpoch}';

    return GestureDetector(
      onTap: () {
        Get.to(
          () => ImageViewerPage(
            imageUrls: displayImages,
            initialIndex: index,
            heroTagPrefix: uniqueId,
          ),
          transition: Transition.zoom,
        );
      },
      child: Hero(
        tag: 'product_image_${uniqueId}_$index',
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor3,
          ),
          child: _buildImage(imageUrl),
        ),
      ),
    );
  }

  Widget _buildImage(String imageUrl) {
    return imageUrl.startsWith('assets/')
        ? _buildAssetImage(imageUrl)
        : _buildNetworkImage(imageUrl);
  }

  Widget _buildAssetImage(String imageUrl) {
    return Image.asset(
      imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, stackTrace) {
        return _buildErrorPlaceholder();
      },
    );
  }

  Widget _buildNetworkImage(String imageUrl) {
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                : null,
            color: logoColorSecondary,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return _buildErrorPlaceholder();
      },
    );
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      color: backgroundColor3,
      child: Center(
        child: Icon(
          Icons.error_outline,
          color: alertColor,
          size: 40,
        ),
      ),
    );
  }

  Widget _buildImageIndicator(int imageCount) {
    return Positioned(
      bottom: Dimenssions.height40,
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

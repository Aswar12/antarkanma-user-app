import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:antarkanma/theme.dart';

class CachedImageView extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final String? placeholder;
  final BorderRadius? borderRadius;

  const CachedImageView({
    Key? key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder = 'assets/image_shoes.png',
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return _buildPlaceholder();
    }

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => _buildLoadingState(),
        errorWidget: (context, url, error) => _buildPlaceholder(),
        fadeInDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      width: width,
      height: height,
      color: backgroundColor3.withOpacity(0.1),
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(logoColorSecondary),
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor3.withOpacity(0.1),
        borderRadius: borderRadius,
        image: placeholder != null
            ? DecorationImage(
                image: AssetImage(placeholder!),
                fit: fit,
              )
            : null,
      ),
      child: placeholder == null
          ? Icon(
              Icons.image_not_supported,
              color: secondaryTextColor,
              size: 24,
            )
          : null,
    );
  }
}

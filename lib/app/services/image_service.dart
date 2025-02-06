import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:antarkanma/theme.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class ImageService extends GetxService {
  static ImageService get to => Get.find<ImageService>();
  
  // Custom cache manager
  late final DefaultCacheManager _cacheManager;

  // Initialize the service
  @override
  void onInit() {
    super.onInit();
    _cacheManager = DefaultCacheManager();
    _clearOldCache();
  }

  Future<void> _clearOldCache() async {
    try {
      await _cacheManager.emptyCache();
    } catch (e) {
      debugPrint('Error clearing image cache: $e');
    }
  }

  // Get optimized image URL based on size
  String getOptimizedUrl(String originalUrl, {double? width, double? height}) {
    // Add size parameters to URL if supported by your backend
    if (width != null || height != null) {
      final Uri uri = Uri.parse(originalUrl);
      final Map<String, String> queryParams = Map.from(uri.queryParameters);
      
      if (width != null) queryParams['w'] = width.round().toString();
      if (height != null) queryParams['h'] = height.round().toString();
      
      return uri.replace(queryParameters: queryParams).toString();
    }
    return originalUrl;
  }

  // Widget for displaying product thumbnails
  Widget buildProductThumbnail(
    String imageUrl, {
    double size = 100,
    BoxFit fit = BoxFit.cover,
    String? heroTag,
  }) {
    final optimizedUrl = getOptimizedUrl(imageUrl, width: size, height: size);
    
    return CachedNetworkImage(
      imageUrl: optimizedUrl,
      fit: fit,
      memCacheWidth: size.round(),
      memCacheHeight: size.round(),
      cacheManager: _cacheManager,
      placeholder: (context, url) => Container(
        color: backgroundColor3.withOpacity(0.1),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(logoColorSecondary),
            ),
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: backgroundColor3.withOpacity(0.1),
        child: Icon(
          Icons.image_not_supported_outlined,
          color: secondaryTextColor,
          size: size * 0.5,
        ),
      ),
    );
  }

  // Clear image cache
  Future<void> clearCache() async {
    try {
      await _cacheManager.emptyCache();
    } catch (e) {
      debugPrint('Error clearing image cache: $e');
    }
  }

  @override
  void onClose() {
    _cacheManager.dispose();
    super.onClose();
  }
}

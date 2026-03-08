import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:antarkanma/theme.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'dart:io';

class ImageService extends GetxService {
  static ImageService get to => Get.find<ImageService>();

  // Custom cache manager
  DefaultCacheManager? _cacheManager;
  final RxBool _isInitialized = false.obs;

  Future<void> _initializeService() async {
    if (_isInitialized.value) return;

    try {
      debugPrint('ImageService: Starting initialization');
      _cacheManager = DefaultCacheManager();

      // Clear old cache if cache manager is ready
      if (_cacheManager != null) {
        try {
          await _cacheManager!.emptyCache();
          debugPrint('ImageService: Cache cleared successfully');
        } catch (e) {
          debugPrint('ImageService: Error clearing cache (non-fatal): $e');
          // Continue initialization even if cache clear fails
        }
      }

      _isInitialized.value = true;
      debugPrint('ImageService: Initialized successfully');
    } catch (e) {
      debugPrint('ImageService: Error during initialization: $e');
      // Set to initialized to allow app to continue with default fallbacks
      _isInitialized.value = true;
    }
  }

  Future<void> ensureInitialized() async {
    if (!_isInitialized.value) {
      await _initializeService();
    }
  }

  Future<String> getOptimizedUrl(String originalUrl,
      {double? width, double? height}) async {
    if (!_isInitialized.value) {
      await ensureInitialized();
    }

    try {
      // Only do manual DNS lookup for local development domains (.test, .local)
      // to avoid triggering raw SocketExceptions on IDE debuggers for dead public S3 domains.
      final uri = Uri.parse(originalUrl);
      if (uri.hasAuthority &&
          uri.host.isNotEmpty &&
          (uri.host.endsWith('.test') || uri.host.endsWith('.local'))) {
        try {
          await InternetAddress.lookup(uri.host)
              .timeout(const Duration(seconds: 3));
        } catch (e) {
          debugPrint('ImageService: DNS lookup failed for ${uri.host}: $e');
          // For local development domains that fail, apply local proxy rewrite.
          return originalUrl.replaceAll(
              uri.host, uri.host.replaceAll('.', '-'));
        }
      }
      if (width != null || height != null) {
        final Map<String, String> queryParams =
            Map<String, String>.from(uri.queryParameters);

        if (width != null) queryParams['w'] = width.round().toString();
        if (height != null) queryParams['h'] = height.round().toString();

        return uri.replace(queryParameters: queryParams).toString();
      }

      return originalUrl;
    } catch (e) {
      debugPrint('ImageService: Error optimizing URL: $e');
      return originalUrl;
    }
  }

  Widget buildProductThumbnail(
    String imageUrl, {
    double size = 100,
    BoxFit fit = BoxFit.cover,
    String? heroTag,
  }) {
    // Basic validation to prevent flutter_cache_manager crash on invalid URLs
    if (imageUrl.isEmpty ||
        (!imageUrl.startsWith('http://') && !imageUrl.startsWith('https://'))) {
      debugPrint('ImageService: Invalid URL format: $imageUrl');
      return _buildPlaceholder(size);
    }

    // Explicitly block known dead or problematic URLs
    final blockedDomains = [
      'dev.antarkanmaa.my.id',
      'is3.cloudhost.id',
      'antarkanma.my.id',
    ];
    
    if (blockedDomains.any((domain) => imageUrl.contains(domain))) {
      debugPrint('ImageService: BLOCKED problematic URL: $imageUrl');
      return _buildPlaceholder(size);
    }

    // Ensure service is initialized before building widget
    if (!_isInitialized.value) {
      ensureInitialized();
    }

    // Show placeholder if service isn't ready
    if (_cacheManager == null) {
      debugPrint('ImageService: Cache manager not ready');
      return _buildPlaceholder(size);
    }

    return FutureBuilder<String>(
        future: getOptimizedUrl(imageUrl, width: size, height: size),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            debugPrint(
                'ImageService: URL optimization error: ${snapshot.error}');
            return _buildPlaceholder(size);
          }

          final optimizedUrl = snapshot.data ?? imageUrl;

          // Double-check: block problematic URLs even after optimization
          if (optimizedUrl.isEmpty || 
              blockedDomains.any((domain) => optimizedUrl.contains(domain))) {
            debugPrint('ImageService: BLOCKED after optimization: $optimizedUrl');
            return _buildPlaceholder(size);
          }

          return CachedNetworkImage(
            imageUrl: optimizedUrl,
            fit: fit,
            memCacheWidth: size.round(),
            memCacheHeight: size.round(),
            cacheManager: _cacheManager,
            maxWidthDiskCache: 1000,
            maxHeightDiskCache: 1000,
            placeholder: (context, url) => _buildLoadingPlaceholder(size),
            errorWidget: (context, url, error) {
              // Silent fail for blocked domains (already expected)
              if (!blockedDomains.any((domain) => url.contains(domain))) {
                debugPrint('ImageService: Image load error: $error for URL: $url');
              }
              return _buildPlaceholder(size);
            },
          );
        });
  }

  Widget _buildPlaceholder(double size) {
    return Container(
      color: backgroundColor3.withOpacity(0.1),
      child: Icon(
        Icons.image_not_supported_outlined,
        color: secondaryTextColor,
        size: size * 0.5,
      ),
    );
  }

  Widget _buildLoadingPlaceholder(double size) {
    return Container(
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
    );
  }

  Future<void> clearCache() async {
    try {
      if (_cacheManager != null) {
        await _cacheManager!.emptyCache();
        debugPrint('ImageService: Cache cleared successfully');
      }
    } catch (e) {
      debugPrint('ImageService: Error clearing cache: $e');
    }
  }

  @override
  void onClose() {
    try {
      if (_cacheManager != null) {
        _cacheManager!.dispose();
        debugPrint('ImageService: Cache manager disposed');
      }
    } catch (e) {
      debugPrint('ImageService: Error disposing cache manager: $e');
    }
    super.onClose();
  }
}

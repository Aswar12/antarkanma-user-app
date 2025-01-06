import 'package:flutter/foundation.dart';

class PaginatedResponse<T> {
  final List<T> data;
  final String? nextCursor;
  final bool hasMore;
  final Map<String, dynamic>? meta;

  PaginatedResponse({
    required this.data,
    this.nextCursor,
    this.hasMore = true,
    this.meta,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    try {
      debugPrint('PaginatedResponse: Parsing JSON response');
      debugPrint('Raw JSON structure: ${json.keys.join(', ')}');

      // Handle API response structure
      Map<String, dynamic>? metaData = json['meta'] as Map<String, dynamic>?;
      List<dynamic> dataList = [];

      if (json.containsKey('data')) {
        var rawData = json['data'];
        if (rawData is Map<String, dynamic> && rawData.containsKey('data')) {
          // Handle nested data structure
          debugPrint('Found nested data structure');
          dataList = rawData['data'] as List;
        } else if (rawData is List) {
          // Handle flat data structure
          debugPrint('Found flat data structure');
          dataList = rawData;
        }
      }

      debugPrint('Found ${dataList.length} items in data list');

      // Parse items with error handling
      final parsedData = dataList.map((item) {
        try {
          if (item is! Map<String, dynamic>) {
            debugPrint('Converting item to Map<String, dynamic>');
            item = Map<String, dynamic>.from(item as Map);
          }
          return fromJson(item);
        } catch (e) {
          debugPrint('Error parsing item: $e');
          debugPrint('Problematic item: $item');
          return null;
        }
      }).where((item) => item != null).cast<T>().toList();

      debugPrint('Successfully parsed ${parsedData.length} items');

      // Get pagination info from the nested data structure
      final paginationData = json['data'] is Map ? json['data'] as Map<String, dynamic> : null;
      String? nextCursor;
      bool hasMore = false;

      if (paginationData != null) {
        nextCursor = paginationData['next_page_url']?.toString();
        hasMore = nextCursor != null;
      }

      return PaginatedResponse(
        data: parsedData,
        nextCursor: nextCursor,
        hasMore: hasMore,
        meta: metaData,
      );
    } catch (e, stackTrace) {
      debugPrint('Error parsing paginated response: $e');
      debugPrint('Stack trace: $stackTrace');
      debugPrint('Raw JSON: $json');
      return PaginatedResponse(
        data: [],
        hasMore: false,
      );
    }
  }

  Map<String, dynamic> toJson(Map<String, dynamic> Function(T) toJson) {
    return {
      'data': data.map((item) => toJson(item)).toList(),
      'next_cursor': nextCursor,
      'has_more': hasMore,
      'meta': meta,
    };
  }

  @override
  String toString() {
    return 'PaginatedResponse(items: ${data.length}, nextCursor: $nextCursor, hasMore: $hasMore)';
  }
}

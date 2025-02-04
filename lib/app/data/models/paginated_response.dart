class PaginatedResponse<T> {
  final List<T> data;
  final int currentPage;
  final int lastPage;
  final int total;

  PaginatedResponse({
    required this.data,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    try {
      // Handle case where data is directly a list
      if (json['data'] is List) {
        return PaginatedResponse<T>(
          data: (json['data'] as List)
              .map((item) => fromJson(item as Map<String, dynamic>))
              .toList(),
          currentPage: json['current_page'] as int? ?? 1,
          lastPage: json['last_page'] as int? ?? 1,
          total: json['total'] as int? ?? json['data'].length,
        );
      }

      // Handle case where data is nested in a map
      if (json['data'] is Map) {
        final dataMap = json['data'] as Map<String, dynamic>;
        if (dataMap['data'] is List) {
          return PaginatedResponse<T>(
            data: (dataMap['data'] as List)
                .map((item) => fromJson(item as Map<String, dynamic>))
                .toList(),
            currentPage: dataMap['current_page'] as int? ?? 1,
            lastPage: dataMap['last_page'] as int? ?? 1,
            total: dataMap['total'] as int? ?? dataMap['data'].length,
          );
        }
      }

      // Default case - treat the entire json as a single item
      return PaginatedResponse<T>(
        data: [fromJson(json)],
        currentPage: 1,
        lastPage: 1,
        total: 1,
      );
    } catch (e) {
      print('Error parsing paginated response: $e');
      print('JSON data: $json');
      // Return empty response on error
      return PaginatedResponse<T>(
        data: [],
        currentPage: 1,
        lastPage: 1,
        total: 0,
      );
    }
  }

  Map<String, dynamic> toJson(Map<String, dynamic> Function(T) toJson) {
    return {
      'data': data.map((item) => toJson(item)).toList(),
      'current_page': currentPage,
      'last_page': lastPage,
      'total': total,
    };
  }

  @override
  String toString() {
    return 'PaginatedResponse(data: ${data.length} items, currentPage: $currentPage, lastPage: $lastPage, total: $total)';
  }
}

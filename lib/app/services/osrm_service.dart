import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class OSRMService {
  final Dio _dio = Dio();
  final String _baseUrl = 'https://router.project-osrm.org/route/v1/driving/';

  Future<Map<String, dynamic>?> calculateRoute(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) async {
    try {
      final response = await _dio.get(
        '$_baseUrl$startLng,$startLat;$endLng,$endLat',
        queryParameters: {
          'overview': 'false',
          'alternatives': 'false',
          'steps': 'false',
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final routes = response.data['routes'] as List;
        if (routes.isNotEmpty) {
          final route = routes[0];
          return {
            'distance': route['distance'] / 1000, // Convert to kilometers
            'duration': route['duration'] / 60, // Convert to minutes
          };
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error calculating route: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> calculateBatchDistances(
    double userLat,
    double userLng,
    List<Map<String, dynamic>> destinations,
  ) async {
    final results = <Map<String, dynamic>>[];
    
    // Process in batches of 10 to avoid overwhelming the OSRM server
    for (var i = 0; i < destinations.length; i += 10) {
      final batch = destinations.skip(i).take(10);
      final futures = batch.map((dest) async {
        final route = await calculateRoute(
          userLat,
          userLng,
          dest['latitude'],
          dest['longitude'],
        );
        
        if (route != null) {
          return {
            'merchant_id': dest['id'],
            'distance': route['distance'],
            'duration': route['duration'],
          };
        }
        return null;
      });

      final batchResults = await Future.wait(futures);
      results.addAll(batchResults.whereType<Map<String, dynamic>>());

      // Add a small delay between batches
      if (i + 10 < destinations.length) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }

    return results;
  }
}

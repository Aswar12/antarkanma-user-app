import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart' as dio;
import 'package:dio/io.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:antarkanma/config.dart';
import 'package:antarkanma/app/services/storage_service.dart';

class ShippingProvider extends GetxService {
  late final dio.Dio _dio;
  final _storage = StorageService.instance;
  bool _isInitialized = false;

  // Increased timeout durations
  // Increased timeouts for debug mode
  static final Duration defaultConnectTimeout = kDebugMode 
      ? const Duration(seconds: 90)
      : const Duration(seconds: 45);
  static final Duration defaultSendTimeout = kDebugMode
      ? const Duration(seconds: 90)
      : const Duration(seconds: 45);
  static final Duration defaultReceiveTimeout = kDebugMode
      ? const Duration(seconds: 90)
      : const Duration(seconds: 45);
  static final Duration defaultIdleTimeout = kDebugMode
      ? const Duration(seconds: 90)
      : const Duration(seconds: 45);
  // Adjust retry attempts and delay based on debug mode
  static final int maxRetryAttempts = kDebugMode ? 5 : 3;
  static final Duration initialRetryDelay = kDebugMode 
      ? const Duration(seconds: 2)
      : const Duration(seconds: 1);

  void _initializeDio() {
    if (_isInitialized) return;
    
    _dio = dio.Dio();
    _setupBaseOptions();
    _setupInterceptors();
    _isInitialized = true;
  }

  Future<void> ensureInitialized() async {
    _initializeDio();
  }

  void _setupBaseOptions() {
    _dio.options = dio.BaseOptions(
      baseUrl: Config.baseUrl,
      connectTimeout: defaultConnectTimeout,
      receiveTimeout: defaultReceiveTimeout,
      sendTimeout: defaultSendTimeout,
      validateStatus: (status) => status! < 500,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Connection': 'keep-alive',
      },
      extra: {
        'retryAttempts': maxRetryAttempts,
        'retryDelay': initialRetryDelay,
        'silent': false,
        'retryCount': 0,
      },
      receiveDataWhenStatusError: true,
      followRedirects: true,
      persistentConnection: true,
    );
    
    if (_dio.httpClientAdapter is IOHttpClientAdapter) {
      final adapter = _dio.httpClientAdapter as IOHttpClientAdapter;
      adapter.onHttpClientCreate = (client) {
        client.idleTimeout = defaultIdleTimeout;
        client.connectionTimeout = defaultConnectTimeout;
        if (kDebugMode) {
          client.badCertificateCallback = (cert, host, port) => true;
        }
        return client;
      };
    }
  }

  void _setupInterceptors() {
    _dio.interceptors.addAll([
      dio.InterceptorsWrapper(
        onRequest: (options, handler) async {
          try {
            final token = _storage.getToken();
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }

            // Log request details in debug mode
            if (kDebugMode) {
              debugPrint('🌐 REQUEST[${options.method}] => PATH: ${options.path}');
              debugPrint('🌐 Request URL: ${options.uri}');
              debugPrint('*** Request ***');
              debugPrint('uri: ${options.uri}');
              debugPrint('method: ${options.method}');
              debugPrint('responseType: ${options.responseType}');
              debugPrint('followRedirects: ${options.followRedirects}');
              debugPrint('persistentConnection: ${options.persistentConnection}');
              debugPrint('connectTimeout: ${options.connectTimeout}');
              debugPrint('sendTimeout: ${options.sendTimeout}');
              debugPrint('receiveTimeout: ${options.receiveTimeout}');
              debugPrint('receiveDataWhenStatusError: ${options.receiveDataWhenStatusError}');
              debugPrint('extra: ${options.extra}');
              debugPrint('headers:');
              options.headers.forEach((key, value) {
                debugPrint(' $key: $value');
              });
              debugPrint('data:');
              debugPrint('${options.data}');
              debugPrint('');
            }

            return handler.next(options);
          } catch (e) {
            debugPrint('Error in request interceptor: $e');
            return handler.reject(
              dio.DioException(
                requestOptions: options,
                error: e,
                type: dio.DioExceptionType.unknown,
              ),
            );
          }
        },
        onResponse: (response, handler) {
          try {
            // Log response in debug mode
            if (kDebugMode) {
              debugPrint('✅ RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}');
              debugPrint('*** Response ***');
              debugPrint('uri: ${response.requestOptions.uri}');
              debugPrint('statusCode: ${response.statusCode}');
              debugPrint('headers:');
              response.headers.forEach((name, values) {
                debugPrint(' $name: ${values.join(', ')}');
              });
            }
            return handler.next(response);
          } catch (e) {
            debugPrint('Error in response interceptor: $e');
            return handler.reject(
              dio.DioException(
                requestOptions: response.requestOptions,
                error: e,
                type: dio.DioExceptionType.unknown,
              ),
            );
          }
        },
        onError: (error, handler) async {
          if (error.requestOptions.extra['retryCount'] == null) {
            error.requestOptions.extra['retryCount'] = 0;
          }

          final int currentRetry = error.requestOptions.extra['retryCount'] as int;
          final int maxRetries = error.requestOptions.extra['retryAttempts'] as int;
          
          if (currentRetry < maxRetries) {
            error.requestOptions.extra['retryCount'] = currentRetry + 1;
            
            debugPrint('🔴 Error Type: ${error.type}');
            debugPrint('🔴 Error Message: ${error.message}');
            debugPrint('🔄 Connection error occurred. Attempting retry...');
            
            final delay = initialRetryDelay * (currentRetry + 1);
            debugPrint('🔄 Waiting ${delay.inSeconds}s before retry ${currentRetry + 1}/$maxRetries');
            await Future.delayed(delay);

            // Increase timeouts for retry
            // Exponential backoff for timeouts in debug mode
            final multiplier = kDebugMode ? (currentRetry + 1) * 2 : (currentRetry + 1);
            error.requestOptions.connectTimeout = defaultConnectTimeout * multiplier;
            error.requestOptions.sendTimeout = defaultSendTimeout * multiplier;
            error.requestOptions.receiveTimeout = defaultReceiveTimeout * multiplier;

            try {
              final response = await _dio.fetch(error.requestOptions);
              return handler.resolve(response);
            } catch (e) {
              debugPrint('❌ Retry failed: $e');
              return handler.reject(error);
            }
          }
          
          _handleError(error);
          return handler.next(error);
        },
      ),
    ]);
  }

  void _handleError(dio.DioException error) {
    String message;
    debugPrint('🔴 DioException type: ${error.type}');
    debugPrint('🔴 DioException message: ${error.message}');
    
    if (error.type == dio.DioExceptionType.connectionTimeout ||
        error.type == dio.DioExceptionType.sendTimeout ||
        error.type == dio.DioExceptionType.receiveTimeout) {
      throw TimeoutException('Koneksi timeout. Silakan coba lagi.');
    }

    if (error.type == dio.DioExceptionType.cancel) {
      throw TimeoutException('Request dibatalkan karena timeout.');
    }
    
    switch (error.response?.statusCode) {
      case 401:
        message = 'Sesi telah berakhir. Silakan login kembali.';
        break;
      case 403:
        message = 'Anda tidak memiliki akses ke fitur ini.';
        break;
      case 422:
        final errors = error.response?.data['errors'];
        if (errors != null) {
          message = errors.toString();
        } else {
          message = error.response?.data['message'] ?? 'Terjadi kesalahan validasi';
        }
        break;
      default:
        message = error.response?.data?['message'] ?? 'Terjadi kesalahan pada server';
    }
    throw Exception(message);
  }

  Future<dio.Response> calculateShipping({
    required int userLocationId,
    required int merchantId,
  }) async {
    final completer = Completer<dio.Response>();
    Timer? timeoutTimer;
    int retryCount = 0;

    try {
      _initializeDio();
      debugPrint('📤 Calculating shipping cost for location $userLocationId and merchant $merchantId');

      while (retryCount < maxRetryAttempts) {
        timeoutTimer?.cancel();
        // Use exponential backoff for timeout timer in debug mode
        final timeoutMultiplier = kDebugMode ? (retryCount + 1) * 2 : (retryCount + 1);
        timeoutTimer = Timer(defaultReceiveTimeout * timeoutMultiplier, () {
          if (!completer.isCompleted) {
            debugPrint('🔴 Request timed out (attempt ${retryCount + 1}/$maxRetryAttempts)');
            if (retryCount + 1 < maxRetryAttempts) {
              retryCount++;
              final delay = initialRetryDelay * (retryCount + 1);
              debugPrint('🔄 Waiting ${delay.inSeconds}s before retry $retryCount/$maxRetryAttempts');
              Future.delayed(delay, () {
                _retryCalculateShipping(userLocationId, merchantId, completer, retryCount);
              });
            } else {
              completer.completeError(
                TimeoutException('Kalkulasi biaya pengiriman timeout setelah $maxRetryAttempts percobaan'),
              );
            }
          }
        });

        try {
          final response = await _dio.post(
            '/shipping/calculate',
            data: {
              'user_location_id': userLocationId,
              'merchant_id': merchantId,
            },
            options: dio.Options(
              // Use exponential backoff for timeouts in debug mode
              sendTimeout: defaultSendTimeout * (kDebugMode ? (retryCount + 1) * 2 : (retryCount + 1)),
              receiveTimeout: defaultReceiveTimeout * (kDebugMode ? (retryCount + 1) * 2 : (retryCount + 1)),
              headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
              },
            ),
          );

          if (!completer.isCompleted) {
            if (response.data == null) {
              completer.completeError(Exception('Server returned empty response'));
            } else {
              debugPrint('📥 Shipping calculation response: ${response.data}');
              completer.complete(response);
            }
          }
          break;
        } catch (e) {
          if (e is dio.DioException && 
              (e.type == dio.DioExceptionType.connectionTimeout ||
               e.type == dio.DioExceptionType.sendTimeout ||
               e.type == dio.DioExceptionType.receiveTimeout)) {
            retryCount++;
            if (retryCount >= maxRetryAttempts) {
              if (!completer.isCompleted) {
                completer.completeError(e);
              }
              break;
            }
            final delay = initialRetryDelay * retryCount;
            debugPrint('🔄 Connection timeout. Waiting ${delay.inSeconds}s before retry $retryCount/$maxRetryAttempts');
            await Future.delayed(delay);
            continue;
          }
          if (!completer.isCompleted) {
            completer.completeError(e);
          }
          break;
        }
      }

      return await completer.future;
    } catch (e) {
      debugPrint('Error in shipping calculation: $e');
      rethrow;
    } finally {
      timeoutTimer?.cancel();
    }
  }

  Future<void> _retryCalculateShipping(
    int userLocationId,
    int merchantId,
    Completer<dio.Response> completer,
    int retryCount,
  ) async {
    try {
      // Use exponential backoff for timeouts in debug mode
      final multiplier = kDebugMode ? (retryCount + 1) * 2 : (retryCount + 1);
      final response = await _dio.post(
        '/shipping/calculate',
        data: {
          'user_location_id': userLocationId,
          'merchant_id': merchantId,
        },
        options: dio.Options(
          sendTimeout: defaultSendTimeout * multiplier,
          receiveTimeout: defaultReceiveTimeout * multiplier,
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (!completer.isCompleted) {
        if (response.data == null) {
          completer.completeError(Exception('Server returned empty response'));
        } else {
          debugPrint('📥 Shipping calculation response (retry $retryCount): ${response.data}');
          completer.complete(response);
        }
      }
    } catch (e) {
      if (!completer.isCompleted) {
        completer.completeError(e);
      }
    }
  }

  Future<dio.Response> getShippingPreview({
    required int userLocationId,
    required List<Map<String, dynamic>> items,
    dio.CancelToken? cancelToken,
  }) async {
    final completer = Completer<dio.Response>();
    Timer? timeoutTimer;
    int retryCount = 0;

    try {
      _initializeDio();
      debugPrint('📤 Getting shipping preview for location $userLocationId');
      debugPrint('Items: $items');

      while (retryCount < maxRetryAttempts && (cancelToken?.isCancelled != true)) {
        timeoutTimer?.cancel();
        timeoutTimer = Timer(defaultReceiveTimeout * (retryCount + 1), () {
          if (!completer.isCompleted) {
            debugPrint('🔴 Request timed out (attempt ${retryCount + 1}/$maxRetryAttempts)');
            if (retryCount + 1 < maxRetryAttempts) {
              retryCount++;
              final delay = initialRetryDelay * (retryCount + 1);
              debugPrint('🔄 Waiting ${delay.inSeconds}s before retry $retryCount/$maxRetryAttempts');
              Future.delayed(delay, () {
                _retryShippingPreview(userLocationId, items, cancelToken, completer, retryCount);
              });
            } else {
              cancelToken?.cancel('Request timed out after $maxRetryAttempts attempts');
              completer.completeError(
                TimeoutException('Preview pengiriman timeout setelah $maxRetryAttempts percobaan'),
              );
            }
          }
        });

        try {
          final response = await _dio.post(
            '/shipping/preview',
            data: {
              'user_location_id': userLocationId,
              'items': items,
            },
            options: dio.Options(
              // Use exponential backoff for timeouts in debug mode
              sendTimeout: defaultSendTimeout * (kDebugMode ? (retryCount + 1) * 2 : (retryCount + 1)),
              receiveTimeout: defaultReceiveTimeout * (kDebugMode ? (retryCount + 1) * 2 : (retryCount + 1)),
              headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
              },
            ),
            cancelToken: cancelToken,
          );

          if (!completer.isCompleted) {
            if (response.data == null) {
              completer.completeError(Exception('Server returned empty response'));
            } else {
              debugPrint('📥 Shipping preview response: ${response.data}');
              completer.complete(response);
            }
          }
          break;
        } catch (e) {
          if (cancelToken?.isCancelled == true) {
            if (!completer.isCompleted) {
              completer.completeError(e);
            }
            break;
          }

          if (e is dio.DioException && 
              (e.type == dio.DioExceptionType.connectionTimeout ||
               e.type == dio.DioExceptionType.sendTimeout ||
               e.type == dio.DioExceptionType.receiveTimeout)) {
            retryCount++;
            if (retryCount >= maxRetryAttempts) {
              if (!completer.isCompleted) {
                completer.completeError(e);
              }
              break;
            }
            final delay = initialRetryDelay * retryCount;
            debugPrint('🔄 Connection timeout. Waiting ${delay.inSeconds}s before retry $retryCount/$maxRetryAttempts');
            await Future.delayed(delay);
            continue;
          }
          if (!completer.isCompleted) {
            completer.completeError(e);
          }
          break;
        }
      }

      return await completer.future;
    } catch (e) {
      debugPrint('Error in shipping preview: $e');
      rethrow;
    } finally {
      timeoutTimer?.cancel();
    }
  }

  Future<void> _retryShippingPreview(
    int userLocationId,
    List<Map<String, dynamic>> items,
    dio.CancelToken? cancelToken,
    Completer<dio.Response> completer,
    int retryCount,
  ) async {
    if (cancelToken?.isCancelled == true) {
      return;
    }

    try {
      // Use exponential backoff for timeouts in debug mode
      final multiplier = kDebugMode ? (retryCount + 1) * 2 : (retryCount + 1);
      final response = await _dio.post(
        '/shipping/preview',
        data: {
          'user_location_id': userLocationId,
          'items': items,
        },
        options: dio.Options(
          sendTimeout: defaultSendTimeout * multiplier,
          receiveTimeout: defaultReceiveTimeout * multiplier,
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
        cancelToken: cancelToken,
      );

      if (!completer.isCompleted) {
        if (response.data == null) {
          completer.completeError(Exception('Server returned empty response'));
        } else {
          debugPrint('📥 Shipping preview response (retry $retryCount): ${response.data}');
          completer.complete(response);
        }
      }
    } catch (e) {
      if (!completer.isCompleted) {
        completer.completeError(e);
      }
    }
  }
}

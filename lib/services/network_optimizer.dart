import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

class NetworkOptimizer {
  static final NetworkOptimizer _instance = NetworkOptimizer._internal();
  factory NetworkOptimizer() => _instance;
  NetworkOptimizer._internal();

  late Dio _fastClient; // For quick API calls
  late Dio _streamClient; // For large downloads/streams
  
  final Map<String, Completer<Response>> _dedupMap = {};
  ConnectivityResult _currentConnectivity = ConnectivityResult.none;
  
  Future<void> initialize() async {
    // Initialize fast client for API calls
    _fastClient = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 5),
      headers: {
        'Accept': 'application/json',
        'Accept-Encoding': 'gzip, br',
        'Connection': 'keep-alive',
      },
    ));

    // Initialize streaming client for large files
    _streamClient = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Accept': 'audio/*,video/*,*/*',
        'Accept-Encoding': 'identity', // Disable compression for media
        'Connection': 'keep-alive',
        'Range': 'bytes=0-', // Enable range requests
      },
    ));

    // Add optimized interceptors
    _setupOptimizedInterceptors(_fastClient, isStreaming: false);
    _setupOptimizedInterceptors(_streamClient, isStreaming: true);

    // Monitor connectivity
    _monitorConnectivity();
  }

  void _setupOptimizedInterceptors(Dio dio, {required bool isStreaming}) {
    // Request deduplication
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final key = '${options.method}:${options.uri}';
          
          if (_dedupMap.containsKey(key)) {
            // Return cached promise
            try {
              final response = await _dedupMap[key]!.future;
              handler.resolve(response);
              return;
            } catch (e) {
              _dedupMap.remove(key);
            }
          }

          // Create new promise
          final completer = Completer<Response>();
          _dedupMap[key] = completer;
          
          handler.next(options);
        },
        onResponse: (response, handler) {
          final key = '${response.requestOptions.method}:${response.requestOptions.uri}';
          _dedupMap[key]?.complete(response);
          _dedupMap.remove(key);
          handler.next(response);
        },
        onError: (error, handler) {
          final key = '${error.requestOptions.method}:${error.requestOptions.uri}';
          _dedupMap[key]?.completeError(error);
          _dedupMap.remove(key);
          handler.next(error);
        },
      ),
    );

    // Adaptive timeout based on connection
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Adjust timeouts based on connection quality
          switch (_currentConnectivity) {
            case ConnectivityResult.wifi:
              // Keep default timeouts for WiFi
              break;
            case ConnectivityResult.mobile:
              // Increase timeouts for mobile
              options.connectTimeout = Duration(
                milliseconds: (options.connectTimeout?.inMilliseconds ?? 5000) * 2
              );
              options.receiveTimeout = Duration(
                milliseconds: (options.receiveTimeout?.inMilliseconds ?? 10000) * 2
              );
              break;
            default:
              // Shorter timeouts for unknown connections
              options.connectTimeout = const Duration(seconds: 3);
              options.receiveTimeout = const Duration(seconds: 8);
          }
          
          handler.next(options);
        },
      ),
    );

    // Smart retry with exponential backoff
    dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) async {
          if (_shouldRetry(error) && (error.requestOptions.extra['retries'] ?? 0) < 3) {
            final retries = (error.requestOptions.extra['retries'] ?? 0) + 1;
            final delay = Duration(milliseconds: ((500 * retries).clamp(500, 5000)).toInt());
            
            await Future.delayed(delay);
            
            final options = error.requestOptions;
            options.extra['retries'] = retries;
            
            try {
              final response = await dio.request(
                options.path,
                data: options.data,
                queryParameters: options.queryParameters,
                options: Options(
                  method: options.method,
                  headers: options.headers,
                  extra: options.extra,
                ),
              );
              handler.resolve(response);
              return;
            } catch (e) {
              // Continue with original error if retry fails
            }
          }
          
          handler.next(error);
        },
      ),
    );
  }

  bool _shouldRetry(DioException error) {
    // Retry on network errors, timeouts, and 5xx status codes
    return error.type == DioExceptionType.connectionTimeout ||
           error.type == DioExceptionType.receiveTimeout ||
           error.type == DioExceptionType.connectionError ||
           (error.response?.statusCode != null && error.response!.statusCode! >= 500);
  }

  void _monitorConnectivity() {
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (results.isNotEmpty) {
        _currentConnectivity = results.first;
      }
    });
  }

  /// Get optimized client for API calls
  Dio get apiClient => _fastClient;

  /// Get optimized client for streaming
  Dio get streamClient => _streamClient;

  /// Preload critical resources
  Future<void> preloadCriticalResources(List<String> urls) async {
    final futures = urls.take(3).map((url) => _preloadResource(url));
    await Future.wait(futures, eagerError: false);
  }

  Future<void> _preloadResource(String url) async {
    try {
      await _fastClient.head(url);
    } catch (e) {
      // Ignore preload failures
    }
  }

  /// Optimize image loading
  Future<Response> optimizedImageRequest(String url, {int? maxWidth, int? maxHeight}) async {
    final options = Options(
      headers: {
        if (maxWidth != null || maxHeight != null)
          'Accept': 'image/webp,image/avif,image/*,*/*;q=0.8',
      },
    );

    return _fastClient.get(url, options: options);
  }
}

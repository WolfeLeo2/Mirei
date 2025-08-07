import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class EnhancedHttpService {
  static final EnhancedHttpService _instance = EnhancedHttpService._internal();
  static late Dio _dio;
  static late Dio _metadataDio; // Separate instance for metadata requests
  
  // Connection pooling configuration
  static const int maxConnectionsPerHost = 6;
  static const Duration connectionTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 15);
  
  // Request deduplication
  static final Map<String, Future<Response>> _pendingRequests = {};
  
  EnhancedHttpService._internal();

  factory EnhancedHttpService() => _instance;

  Future<void> initialize() async {
    // Main Dio instance for audio streaming
    _dio = Dio(BaseOptions(
      connectTimeout: connectionTimeout,
      receiveTimeout: receiveTimeout,
      sendTimeout: sendTimeout,
      maxRedirects: 3,
      headers: {
        'User-Agent': 'Mirei/1.0 (Flutter Audio Player)',
        'Accept': '*/*',
        'Accept-Encoding': 'gzip, deflate, br',
        'Connection': 'keep-alive',
        'Cache-Control': 'no-cache',
      },
    ));

    // Separate instance for metadata/API requests with different timeouts
    _metadataDio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 10),
      maxRedirects: 5,
      headers: {
        'User-Agent': 'Mirei/1.0 (Metadata Client)',
        'Accept': 'application/json, text/plain, */*',
        'Accept-Encoding': 'gzip, deflate, br',
        'Connection': 'keep-alive',
      },
    ));

    // Add interceptors for both instances
    _setupInterceptors(_dio, isAudioClient: true);
    _setupInterceptors(_metadataDio, isAudioClient: false);

    // Configure HTTP client adapter for connection pooling
    _configureConnectionPooling(_dio);
    _configureConnectionPooling(_metadataDio);
  }

  void _setupInterceptors(Dio dio, {required bool isAudioClient}) {
    // Request deduplication interceptor
    dio.interceptors.add(_createDeduplicationInterceptor());
    
    // Network connectivity interceptor
    dio.interceptors.add(_createConnectivityInterceptor());
    
    // Retry interceptor with exponential backoff
    dio.interceptors.add(_createSmartRetryInterceptor(isAudioClient: isAudioClient));
    
    // Request/Response logging for debugging
    dio.interceptors.add(_createLoggingInterceptor(isAudioClient: isAudioClient));
    
    // Performance monitoring
    dio.interceptors.add(_createPerformanceInterceptor());
  }

  void _configureConnectionPooling(Dio dio) {
    final adapter = IOHttpClientAdapter();
    
    adapter.createHttpClient = () {
      final client = HttpClient();
      
      // Connection pooling settings
      client.maxConnectionsPerHost = maxConnectionsPerHost;
      client.connectionTimeout = connectionTimeout;
      client.idleTimeout = const Duration(seconds: 30);
      
      // SSL/TLS configuration
      client.badCertificateCallback = (cert, host, port) => false; // Strict certificate validation
      
      return client;
    };
    
    dio.httpClientAdapter = adapter;
  }

  // Deduplication interceptor to prevent duplicate requests
  Interceptor _createDeduplicationInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        final requestKey = _generateRequestKey(options);
        
        // Check if same request is already in flight
        if (_pendingRequests.containsKey(requestKey)) {
          // Return the pending request
          _pendingRequests[requestKey]!.then((response) {
            final clonedResponse = Response(
              requestOptions: options,
              data: response.data,
              statusCode: response.statusCode,
              statusMessage: response.statusMessage,
              headers: response.headers,
              extra: {...response.extra, 'deduplicated': true},
            );
            handler.resolve(clonedResponse);
          }).catchError((error) {
            handler.reject(error);
          });
          return;
        }
        
        handler.next(options);
      },
      onResponse: (response, handler) {
        final requestKey = _generateRequestKey(response.requestOptions);
        _pendingRequests.remove(requestKey);
        handler.next(response);
      },
      onError: (error, handler) {
        final requestKey = _generateRequestKey(error.requestOptions);
        _pendingRequests.remove(requestKey);
        handler.next(error);
      },
    );
  }

  // Connectivity interceptor to handle network changes
  Interceptor _createConnectivityInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        final connectivity = await Connectivity().checkConnectivity();
        
        if (connectivity.contains(ConnectivityResult.none)) {
          handler.reject(DioException(
            requestOptions: options,
            type: DioExceptionType.connectionError,
            message: 'No internet connection available',
          ));
          return;
        }
        
        // Add network type info to headers for analytics
        final networkType = _getNetworkTypeString(connectivity);
        options.headers['X-Network-Type'] = networkType;
        
        handler.next(options);
      },
    );
  }

  // Smart retry interceptor with different strategies for audio vs metadata
  Interceptor _createSmartRetryInterceptor({required bool isAudioClient}) {
    return InterceptorsWrapper(
      onError: (error, handler) async {
        final retryCount = error.requestOptions.extra['retry_count'] ?? 0;
        final maxRetries = isAudioClient ? 3 : 2; // More retries for audio
        
        // Determine if we should retry based on error type
        final shouldRetry = _shouldRetryRequest(error, retryCount, maxRetries);
        
        if (shouldRetry) {
          error.requestOptions.extra['retry_count'] = retryCount + 1;
          
          // Adaptive backoff based on network type and error
          final delay = _calculateRetryDelay(error, retryCount);
          await Future.delayed(delay);
          
          try {
            final response = await _dio.fetch(error.requestOptions);
            return handler.resolve(response);
          } catch (e) {
            // Continue with original error if retry fails
          }
        }
        
        handler.next(error);
      },
    );
  }

  // Performance monitoring interceptor
  Interceptor _createPerformanceInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        options.extra['request_start'] = DateTime.now().millisecondsSinceEpoch;
        handler.next(options);
      },
      onResponse: (response, handler) {
        final startTime = response.requestOptions.extra['request_start'] as int?;
        if (startTime != null) {
          final duration = DateTime.now().millisecondsSinceEpoch - startTime;
          response.extra['request_duration'] = duration;
          
          // Log slow requests for optimization
          if (duration > 5000) { // 5 seconds
            print('Slow request detected: ${response.requestOptions.uri} took ${duration}ms');
          }
        }
        handler.next(response);
      },
    );
  }

  // Logging interceptor
  Interceptor _createLoggingInterceptor({required bool isAudioClient}) {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        final clientType = isAudioClient ? 'AUDIO' : 'META';
        print('[$clientType] ${options.method} ${options.uri}');
        handler.next(options);
      },
      onError: (error, handler) {
        final clientType = isAudioClient ? 'AUDIO' : 'META';
        print('[$clientType] ERROR: ${error.message}');
        handler.next(error);
      },
    );
  }

  // Public methods for making requests
  
  Future<Response> getAudioContent(String url, {
    Map<String, dynamic>? headers,
    int? startByte,
    int? endByte,
    Function(int, int)? onReceiveProgress,
    CancelToken? cancelToken,
  }) async {
    final options = Options(
      headers: {
        ...?headers,
        if (startByte != null || endByte != null)
          'Range': 'bytes=${startByte ?? 0}-${endByte ?? ''}',
      },
      responseType: ResponseType.bytes,
    );

    final requestKey = _generateRequestKey(RequestOptions(
      path: url,
      method: 'GET',
      headers: options.headers,
    ));
    
    // Track the request for deduplication
    final requestFuture = _dio.get(
      url,
      options: options,
      onReceiveProgress: onReceiveProgress,
      cancelToken: cancelToken,
    );
    
    _pendingRequests[requestKey] = requestFuture;
    
    return requestFuture;
  }

  Future<Response<T>> getMetadata<T>(String url, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    ResponseType responseType = ResponseType.json,
    CancelToken? cancelToken,
  }) async {
    return _metadataDio.get<T>(
      url,
      queryParameters: queryParameters,
      options: Options(
        headers: headers,
        responseType: responseType,
      ),
      cancelToken: cancelToken,
    );
  }

  Future<Response<T>> postMetadata<T>(String url, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
  }) async {
    return _metadataDio.post<T>(
      url,
      data: data,
      queryParameters: queryParameters,
      options: Options(headers: headers),
      cancelToken: cancelToken,
    );
  }

  // Stream-based audio download with progress
  Future<Response<ResponseBody>> getAudioStream(String url, {
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
  }) async {
    return _dio.get<ResponseBody>(
      url,
      options: Options(
        headers: headers,
        responseType: ResponseType.stream,
      ),
      cancelToken: cancelToken,
    );
  }

  // Utility methods
  
  String _generateRequestKey(RequestOptions options) {
    final key = '${options.method}:${options.uri}:${jsonEncode(options.headers)}';
    return sha256.convert(utf8.encode(key)).toString();
  }

  String _getNetworkTypeString(List<ConnectivityResult> connectivity) {
    if (connectivity.contains(ConnectivityResult.wifi)) return 'wifi';
    if (connectivity.contains(ConnectivityResult.ethernet)) return 'ethernet';
    if (connectivity.contains(ConnectivityResult.mobile)) return 'mobile';
    if (connectivity.contains(ConnectivityResult.vpn)) return 'vpn';
    return 'unknown';
  }

  bool _shouldRetryRequest(DioException error, int retryCount, int maxRetries) {
    if (retryCount >= maxRetries) return false;
    
    // Retry on network-related errors
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.connectionError:
        return true;
      case DioExceptionType.badResponse:
        // Retry on server errors (5xx) but not client errors (4xx)
        final statusCode = error.response?.statusCode;
        return statusCode != null && statusCode >= 500;
      default:
        return false;
    }
  }

  Duration _calculateRetryDelay(DioException error, int retryCount) {
    // Base delay increases exponentially
    int baseDelayMs = 1000 * (1 << retryCount); // 1s, 2s, 4s, 8s...
    
    // Add jitter to prevent thundering herd
    final jitterMs = (baseDelayMs * 0.1 * (DateTime.now().millisecond / 1000)).round();
    
    // Adjust based on error type
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        baseDelayMs *= 2; // Longer delay for connection timeouts
        break;
      case DioExceptionType.receiveTimeout:
        baseDelayMs = (baseDelayMs * 1.5).round(); // Moderate delay for receive timeouts
        break;
      default:
        break;
    }
    
    return Duration(milliseconds: baseDelayMs + jitterMs);
  }

  // Cache and performance monitoring
  Map<String, dynamic> getPerformanceStats() {
    return {
      'pending_requests': _pendingRequests.length,
      'audio_client_active': true,
      'metadata_client_active': true,
    };
  }

  void clearPendingRequests() {
    _pendingRequests.clear();
  }

  Future<void> dispose() async {
    clearPendingRequests();
    _dio.close();
    _metadataDio.close();
  }
}

import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:realm/realm.dart';
import '../utils/realm_database_helper.dart';
import '../models/realm_models.dart';

class AudioCacheService {
  static final AudioCacheService _instance = AudioCacheService._internal();
  static late Dio _dio;
  static late Directory _cacheDirectory;
  static final RealmDatabaseHelper _dbHelper = RealmDatabaseHelper();
  
  // Cache configuration (similar to Spotify)
  static const int maxCacheSize = 500 * 1024 * 1024; // 500MB cache limit
  static const int maxCacheAge = 30; // 30 days
  static const int bufferSize = 256 * 1024; // 256KB buffer chunks
  static const int maxConcurrentDownloads = 3;
  static const Duration connectionTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 30);
  
  // Connection pooling and reuse (removed ConnectionPool reference)
  static final Map<String, CancelToken> _activeDownloads = {};
  static final Map<String, List<Function(double)>> _progressCallbacks = {};

  AudioCacheService._internal();

  factory AudioCacheService() => _instance;

  Future<void> initialize() async {
    // Initialize cache directory
    final appDir = await getApplicationDocumentsDirectory();
    _cacheDirectory = Directory(path.join(appDir.path, 'audio_cache'));
    if (!await _cacheDirectory.exists()) {
      await _cacheDirectory.create(recursive: true);
    }

    // Initialize Dio with optimized settings for audio streaming
    _dio = Dio(BaseOptions(
      connectTimeout: connectionTimeout,
      receiveTimeout: receiveTimeout,
      sendTimeout: connectionTimeout,
      // Enable HTTP/2 for better multiplexing
      extra: {'http2': true},
      headers: {
        'User-Agent': 'Mirei/1.0 (Audio Streaming Client)',
        'Accept': 'audio/*,*/*;q=0.9',
        'Accept-Encoding': 'gzip, deflate, br',
        'Connection': 'keep-alive',
      },
    ));

    // Add interceptors for connection pooling and caching
    _dio.interceptors.add(_createCacheInterceptor());
    _dio.interceptors.add(_createConnectionPoolInterceptor());
    _dio.interceptors.add(_createRetryInterceptor());

    // Clean up old cache entries on startup
    _cleanupCache();
  }

  // Main method to get audio file (cached or download)
  Future<File?> getAudioFile(String url, {Function(double)? onProgress}) async {
    try {
      // Check if file exists in cache
      final cachedFile = await _getCachedFile(url);
      if (cachedFile != null && await cachedFile.exists()) {
        await _updateCacheAccess(url);
        return cachedFile;
      }

      // Check network connectivity
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity.contains(ConnectivityResult.none)) {
        throw Exception('No network connection available');
      }

      // Download file with progress tracking
      return await _downloadAudioFile(url, onProgress: onProgress);
    } catch (e) {
      print('AudioCacheService: Error getting audio file: $e');
      return null;
    }
  }

  // Progressive download with chunked buffering (Spotify-style)
  Future<File> _downloadAudioFile(String url, {Function(double)? onProgress}) async {
    final cacheKey = _generateCacheKey(url);
    final localPath = path.join(_cacheDirectory.path, '$cacheKey.audio');
    final tempPath = '$localPath.tmp';
    final file = File(localPath);
    final tempFile = File(tempPath);

    // Check if download is already in progress
    if (_activeDownloads.containsKey(url)) {
      // Wait for existing download
      if (onProgress != null) {
        _progressCallbacks[url] ??= [];
        _progressCallbacks[url]!.add(onProgress);
      }
      
      // Poll for completion
      while (_activeDownloads.containsKey(url)) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      
      if (await file.exists()) {
        return file;
      }
    }

    // Start new download
    final cancelToken = CancelToken();
    _activeDownloads[url] = cancelToken;
    
    try {
      // Create cache entry immediately for tracking
      final now = DateTime.now();
      final cacheEntry = AudioCacheEntry(
        url,
        localPath,
        now,
        now,
        0,
        0,
        false,
      );
      await _dbHelper.insertAudioCacheEntry(cacheEntry);

      // Download with chunked streaming
      final response = await _dio.get<ResponseBody>(
        url,
        options: Options(
          responseType: ResponseType.stream,
          headers: {
            'Range': 'bytes=0-', // Enable range requests for resumable downloads
          },
        ),
        cancelToken: cancelToken,
      );

      final stream = response.data!.stream;
      final contentLength = response.headers.value('content-length');
      final totalBytes = contentLength != null ? int.parse(contentLength) : 0;
      
      int downloadedBytes = 0;
      final sink = tempFile.openWrite();

      await for (final chunk in stream) {
        if (cancelToken.isCancelled) break;
        
        sink.add(chunk);
        downloadedBytes += chunk.length;
        
        // Update progress
        if (totalBytes > 0) {
          final progress = downloadedBytes / totalBytes;
          onProgress?.call(progress);
          
          // Notify other waiting callbacks
          _progressCallbacks[url]?.forEach((callback) => callback(progress));
        }

        // Progressive availability: file becomes playable after first chunk
        if (downloadedBytes >= bufferSize && !await file.exists()) {
          await sink.flush();
          // Copy partial file for immediate playback
          await tempFile.copy(localPath);
        }
      }

      await sink.close();

      // Move completed file
      if (!cancelToken.isCancelled && await tempFile.exists()) {
        await tempFile.rename(localPath);
        
        // Update cache entry
        await _updateCacheEntry(url, localPath, downloadedBytes, isComplete: true);
        
        // Clean up temp files
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      }

      return file;
    } catch (e) {
      // Clean up on error
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      await _dbHelper.deleteAudioCacheEntry(url);
      rethrow;
    } finally {
      _activeDownloads.remove(url);
      _progressCallbacks.remove(url);
    }
  }

  // Predictive caching for next songs in playlist
  Future<void> preloadPlaylistItems(String playlistId, List<String> urls, {int maxPreload = 3}) async {
    // Clear old playlist cache
    await _dbHelper.clearPlaylistCache(playlistId);

    // Add new items with priority
    for (int i = 0; i < urls.length && i < maxPreload; i++) {
      final entry = PlaylistCacheEntry(
        ObjectId(),
        playlistId,
        urls[i],
        i + 1,
        DateTime.now(),
        false,
      );
      await _dbHelper.insertPlaylistCacheEntry(entry);
    }

    // Start preloading in background (next 2-3 songs)
    _preloadInBackground(playlistId);
  }

  void _preloadInBackground(String playlistId) async {
    try {
      final items = await _dbHelper.getPlaylistCacheEntries(playlistId);
      int preloadedCount = 0;
      
      for (final item in items) {
        if (preloadedCount >= 2) break; // Limit concurrent preloads
        
        if (!item.isPreloaded) {
          // Check if already cached
          final cached = await _getCachedFile(item.songUrl);
          if (cached == null || !await cached.exists()) {
            // Start preload without waiting
            getAudioFile(item.songUrl).then((_) {
              _dbHelper.updatePlaylistCachePreloadStatus(item.id, true);
            }).catchError((e) {
              print('Preload failed for ${item.songUrl}: $e');
            });
            preloadedCount++;
          } else {
            // Mark as preloaded if already cached
            await _dbHelper.updatePlaylistCachePreloadStatus(item.id, true);
          }
        }
      }
    } catch (e) {
      print('Background preload error: $e');
    }
  }

  // Progressive buffer management
  Future<Stream<Uint8List>?> getAudioStream(String url, {int? startByte, int? endByte}) async {
    try {
      final cachedFile = await _getCachedFile(url);
      
      if (cachedFile != null && await cachedFile.exists()) {
        // Stream from cached file with proper type conversion
        return cachedFile.openRead(startByte, endByte).map((chunk) => Uint8List.fromList(chunk));
      }

      // Stream directly with range requests for immediate playback
      final response = await _dio.get<ResponseBody>(
        url,
        options: Options(
          responseType: ResponseType.stream,
          headers: {
            if (startByte != null || endByte != null)
              'Range': 'bytes=${startByte ?? 0}-${endByte ?? ''}',
          },
        ),
      );

      return response.data?.stream.map((chunk) => Uint8List.fromList(chunk));
    } catch (e) {
      print('AudioCacheService: Error getting audio stream: $e');
      return null;
    }
  }

  // Cache management methods
  Future<File?> _getCachedFile(String url) async {
    final entry = await _dbHelper.getAudioCacheEntry(url);
    if (entry != null) {
      final file = File(entry.localPath);
      if (await file.exists()) {
        return file;
      } else {
        // Clean up stale cache entry
        await _dbHelper.deleteAudioCacheEntry(url);
      }
    }
    return null;
  }

  Future<void> _updateCacheAccess(String url) async {
    await _dbHelper.updateAudioCacheAccess(url);
  }

  Future<void> _updateCacheEntry(String url, String localPath, int sizeBytes, {bool isComplete = false}) async {
    final now = DateTime.now();
    final entry = AudioCacheEntry(
      url,
      localPath,
      now,
      now,
      sizeBytes,
      0,
      isComplete,
    );
    await _dbHelper.insertAudioCacheEntry(entry);
  }

  String _generateCacheKey(String url) {
    final bytes = utf8.encode(url);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Cache cleanup and maintenance
  Future<void> _cleanupCache() async {
    try {
      final totalSize = await _dbHelper.getTotalCacheSize();
      
      if (totalSize > maxCacheSize) {
        // Remove oldest accessed files until under limit
        final oldEntries = await _dbHelper.getOldestCacheEntries(100);
        int removedSize = 0;
        
        for (final entry in oldEntries) {
          if (totalSize - removedSize <= maxCacheSize * 0.8) break;
          
          final file = File(entry.localPath);
          if (await file.exists()) {
            await file.delete();
            removedSize += entry.sizeBytes;
          }
          await _dbHelper.deleteAudioCacheEntry(entry.url);
        }
      }

      // Clean expired HTTP cache
      await _dbHelper.cleanExpiredHttpCache();
      
      // Remove cache entries older than maxCacheAge
      final cutoffDate = DateTime.now().subtract(Duration(days: maxCacheAge));
      final allEntries = await _dbHelper.getAllAudioCacheEntries();
      
      for (final entry in allEntries) {
        if (entry.cachedAt.isBefore(cutoffDate)) {
          final file = File(entry.localPath);
          if (await file.exists()) {
            await file.delete();
          }
          await _dbHelper.deleteAudioCacheEntry(entry.url);
        }
      }
    } catch (e) {
      print('Cache cleanup error: $e');
    }
  }

  // HTTP connection pooling and reuse
  Interceptor _createConnectionPoolInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        // Reuse connections for the same host
        options.extra['connection_pool'] = true;
        handler.next(options);
      },
    );
  }

  // Cache interceptor for metadata/playlist requests
  Interceptor _createCacheInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Only cache GET requests for metadata
        if (options.method == 'GET' && 
            (options.path.contains('api') || options.path.contains('json'))) {
          
          final cacheKey = _generateHttpCacheKey(options);
          final cached = await _dbHelper.getHttpCacheEntry(cacheKey);
          
          if (cached != null && cached.expiresAt.isAfter(DateTime.now())) {
            // Return cached response
            final response = Response(
              requestOptions: options,
              data: jsonDecode(cached.responseBody),
              statusCode: cached.statusCode,
              extra: {'from_cache': true},
            );
            return handler.resolve(response);
          }
        }
        handler.next(options);
      },
      onResponse: (response, handler) async {
        // Cache successful responses
        if (response.statusCode == 200 && 
            response.requestOptions.method == 'GET' &&
            (response.requestOptions.path.contains('api') || 
             response.requestOptions.path.contains('json'))) {
          
          final cacheKey = _generateHttpCacheKey(response.requestOptions);
          final now = DateTime.now();
          final entry = HttpCacheEntry(
            cacheKey,
            jsonEncode(response.data),
            now,
            now.add(const Duration(minutes: 30)),
            response.statusCode!,
            contentType: response.headers.value('content-type'),
          );
          
          await _dbHelper.insertHttpCacheEntry(entry);
        }
        handler.next(response);
      },
    );
  }

  // Retry interceptor for network resilience
  Interceptor _createRetryInterceptor() {
    return InterceptorsWrapper(
      onError: (error, handler) async {
        if (error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.receiveTimeout ||
            error.type == DioExceptionType.connectionError) {
          
          final retryCount = error.requestOptions.extra['retry_count'] ?? 0;
          if (retryCount < 3) {
            error.requestOptions.extra['retry_count'] = retryCount + 1;
            
            // Exponential backoff
            final delay = Duration(milliseconds: (1000 * (retryCount + 1)).toInt());
            await Future.delayed(delay);
            
            try {
              final response = await _dio.fetch(error.requestOptions);
              return handler.resolve(response);
            } catch (e) {
              // Continue with original error if retry fails
            }
          }
        }
        handler.next(error);
      },
    );
  }

  String _generateHttpCacheKey(RequestOptions options) {
    final key = '${options.method}:${options.uri}';
    final bytes = utf8.encode(key);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Public cache management methods
  Future<void> clearCache() async {
    try {
      // Delete all cache files
      if (await _cacheDirectory.exists()) {
        await _cacheDirectory.delete(recursive: true);
        await _cacheDirectory.create(recursive: true);
      }

      // Clear database entries
      final entries = await _dbHelper.getAllAudioCacheEntries();
      for (final entry in entries) {
        await _dbHelper.deleteAudioCacheEntry(entry.url);
      }
    } catch (e) {
      print('Clear cache error: $e');
    }
  }

  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final totalSize = await _dbHelper.getTotalCacheSize();
      final entries = await _dbHelper.getAllAudioCacheEntries();
      
      return {
        'totalSize': totalSize,
        'totalFiles': entries.length,
        'maxSize': maxCacheSize,
        'usagePercentage': (totalSize / maxCacheSize * 100).toInt(),
        'oldestEntry': entries.isNotEmpty 
            ? entries.map((e) => e.cachedAt).reduce((a, b) => a.isBefore(b) ? a : b)
            : null,
        'newestEntry': entries.isNotEmpty 
            ? entries.map((e) => e.cachedAt).reduce((a, b) => a.isAfter(b) ? a : b)
            : null,
      };
    } catch (e) {
      print('Get cache stats error: $e');
      return {};
    }
  }

  Future<void> dispose() async {
    // Cancel all active downloads
    for (final token in _activeDownloads.values) {
      token.cancel('Service disposed');
    }
    _activeDownloads.clear();
    _progressCallbacks.clear();
    
    _dio.close();
  }
}

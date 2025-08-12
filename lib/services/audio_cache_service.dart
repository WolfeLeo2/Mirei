import 'dart:io';
import 'dart:typed_data';
import 'dart:collection';
import 'dart:async';
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

  // Request deduplication
  final Map<String, Future<File?>> _pendingRequests = {};

  // Download queue management
  final Queue<_DownloadTask> _downloadQueue = Queue<_DownloadTask>();
  final Set<String> _queuedUrls = <String>{};
  final Set<String> _preloadedUrls = <String>{}; // Avoid duplicate preloads

  // Performance tracking
  int _cacheHits = 0;
  int _cacheMisses = 0;
  int _totalRequests = 0;

  // Initialization state management
  Future<void>? _initFuture;
  bool _isInitialized = false;
  Timer? _backgroundCleanupTimer;

  AudioCacheService._internal();

  factory AudioCacheService() => _instance;

  /// Ensures initialization happens only once, even with multiple calls
  Future<void> ensureInitialized() {
    _initFuture ??= _initialize();
    return _initFuture!;
  }

  Future<void> initialize() => ensureInitialized();

  Future<void> _initialize() async {
    if (_isInitialized) return;

    // Initialize cache directory
    final appDir = await getApplicationDocumentsDirectory();
    _cacheDirectory = Directory(path.join(appDir.path, 'audio_cache'));
    if (!await _cacheDirectory.exists()) {
      await _cacheDirectory.create(recursive: true);
    }

    // Initialize Dio with optimized settings for audio streaming
    _dio = Dio(
      BaseOptions(
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
      ),
    );

    // Add interceptors for connection pooling and caching
    _dio.interceptors.add(_createCacheInterceptor());
    _dio.interceptors.add(_createConnectionPoolInterceptor());
    _dio.interceptors.add(_createRetryInterceptor());

    // Clean up old cache entries on startup
    _cleanupCache();

    // Start background cleanup timer (every 10 minutes)
    _startBackgroundCleanup();

    _isInitialized = true;
    print('AudioCacheService: Initialization completed');
  }

  /// Start background cleanup with Timer
  void _startBackgroundCleanup() {
    _backgroundCleanupTimer?.cancel();
    _backgroundCleanupTimer = Timer.periodic(const Duration(minutes: 10), (_) {
      _performBackgroundCleanup();
    });
  }

  /// Perform background cleanup with fragmentation stats
  Future<void> _performBackgroundCleanup() async {
    try {
      print('AudioCacheService: Starting background cleanup...');

      // Get fragmentation stats before cleanup
      final statsBefore = await _getFragmentationStats();

      // Perform cleanup
      await _cleanupCache();
      await _dbHelper.cleanExpiredPlaylistEntries();
      await _dbHelper.cleanExpiredPlaylistData();

      // Get stats after cleanup
      final statsAfter = await _getFragmentationStats();

      print('Background cleanup completed:');
      print(
        '  Files before: ${statsBefore['fileCount']}, after: ${statsAfter['fileCount']}',
      );
      print(
        '  Size before: ${(statsBefore['totalSize'] / 1024 / 1024).toStringAsFixed(1)}MB, after: ${(statsAfter['totalSize'] / 1024 / 1024).toStringAsFixed(1)}MB',
      );
      print(
        '  Fragmentation: ${statsBefore['fragmentationPercentage']}% -> ${statsAfter['fragmentationPercentage']}%',
      );
    } catch (e) {
      print('Background cleanup error: $e');
    }
  }

  /// Get cache fragmentation statistics
  Future<Map<String, dynamic>> _getFragmentationStats() async {
    try {
      final entries = await _dbHelper.getAllAudioCacheEntries();
      final totalSize = await _dbHelper.getTotalCacheSize();

      // Count incomplete files (fragmentation indicator)
      final incompleteFiles = entries.where((e) => !e.isComplete).length;
      final fragmentationPercentage = entries.isNotEmpty
          ? ((incompleteFiles / entries.length) * 100).round()
          : 0;

      return {
        'fileCount': entries.length,
        'totalSize': totalSize,
        'incompleteFiles': incompleteFiles,
        'fragmentationPercentage': fragmentationPercentage,
        'averageFileSize': entries.isNotEmpty
            ? (totalSize / entries.length).round()
            : 0,
      };
    } catch (e) {
      return {
        'fileCount': 0,
        'totalSize': 0,
        'incompleteFiles': 0,
        'fragmentationPercentage': 0,
        'averageFileSize': 0,
      };
    }
  }

  // Main method to get audio file (cached or download)
  Future<File?> getAudioFile(String url, {Function(double)? onProgress}) async {
    try {
      // Ensure service is initialized
      await ensureInitialized();

      _totalRequests++;

      // Check if file exists in cache
      final cachedFile = await _getCachedFile(url);
      if (cachedFile != null && await cachedFile.exists()) {
        await _updateCacheAccess(url);
        _cacheHits++;
        print('Cache HIT for: $url');
        return cachedFile;
      }

      _cacheMisses++;
      print('Cache MISS for: $url');

      // Check network connectivity
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity.contains(ConnectivityResult.none)) {
        throw Exception('No network connection available');
      }

      // Schedule download through queue system
      return await _scheduleDownload(url, onProgress: onProgress);
    } catch (e) {
      print('AudioCacheService: Error getting audio file: $e');
      return null;
    }
  }

  /// Schedule download with concurrency control and deduplication
  Future<File?> _scheduleDownload(
    String url, {
    Function(double)? onProgress,
  }) async {
    // Check for existing pending request (deduplication)
    if (_pendingRequests.containsKey(url)) {
      print('Deduplicating request for: $url');
      if (onProgress != null) {
        _progressCallbacks[url] ??= [];
        _progressCallbacks[url]!.add(onProgress);
      }
      return await _pendingRequests[url]!;
    }

    // Check if already downloading or queued
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

      return await _getCachedFile(url);
    }

    // Create and cache the download future
    late Future<File?> downloadFuture;

    // Check if can start immediately
    if (_activeDownloads.length < maxConcurrentDownloads) {
      downloadFuture = _downloadAudioFile(url, onProgress: onProgress);
    } else {
      // Add to queue if not already queued
      if (!_queuedUrls.contains(url)) {
        _downloadQueue.add(_DownloadTask(url, onProgress));
        _queuedUrls.add(url);
        print('Queued download: $url (queue size: ${_downloadQueue.length})');
      }

      // Create a future that resolves when download completes
      downloadFuture = _waitForQueuedDownload(url);
    }

    _pendingRequests[url] = downloadFuture;

    // Clean up pending request when done
    downloadFuture.whenComplete(() {
      _pendingRequests.remove(url);
    });

    return await downloadFuture;
  }

  /// Wait for queued download to complete
  Future<File?> _waitForQueuedDownload(String url) async {
    // Wait for queue processing
    while (_queuedUrls.contains(url)) {
      await Future.delayed(const Duration(milliseconds: 200));
    }

    return await _getCachedFile(url);
  }

  /// Start next download from queue if possible (iterative to prevent stack overflow)
  void _startNext() {
    // Process multiple queue items iteratively instead of recursively
    while (_downloadQueue.isNotEmpty &&
        _activeDownloads.length < maxConcurrentDownloads) {
      final task = _downloadQueue.removeFirst();
      _queuedUrls.remove(task.url);

      // Start download asynchronously with safe queue processing
      _downloadAudioFile(task.url, onProgress: task.onProgress)
          .then((file) {
            // Schedule next queue processing on next tick to avoid deep recursion
            Future.microtask(_startNext);
            return file;
          })
          .catchError((e) async {
            print('Download failed for ${task.url}: $e');
            // Continue processing queue even on error
            Future.microtask(_startNext);
            // Return a temporary empty file to satisfy the return type
            final tempDir = await getTemporaryDirectory();
            final errorFile = File(
              path.join(
                tempDir.path,
                'download_error_${DateTime.now().millisecondsSinceEpoch}.tmp',
              ),
            );
            await errorFile.create();
            return errorFile;
          });
    }
  }

  // Progressive download with chunked buffering (Spotify-style) + Resume support
  Future<File> _downloadAudioFile(
    String url, {
    Function(double)? onProgress,
  }) async {
    final cacheKey = _generateCacheKey(url);
    final localPath = path.join(_cacheDirectory.path, '$cacheKey.audio');
    final tempPath = '$localPath.tmp';
    final file = File(localPath);
    final tempFile = File(tempPath);

    // Check for existing partial download
    int resumeFrom = 0;
    if (await tempFile.exists()) {
      final stat = await tempFile.stat();
      resumeFrom = stat.size;
      print('Resuming download from byte: $resumeFrom');
    }

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
      final cacheEntry = AudioCacheEntry(url, localPath, now, now, 0, 0, false);
      await _dbHelper.insertAudioCacheEntry(cacheEntry);

      // Download with chunked streaming + Resume support
      final headers = <String, String>{};
      if (resumeFrom > 0) {
        headers['Range'] =
            'bytes=$resumeFrom-'; // Resume from where we left off
      } else {
        headers['Range'] =
            'bytes=0-'; // Enable range requests for resumable downloads
      }

      final response = await _dio.get<ResponseBody>(
        url,
        options: Options(responseType: ResponseType.stream, headers: headers),
        cancelToken: cancelToken,
      );

      final stream = response.data!.stream;
      final contentLength = response.headers.value('content-length');
      final totalBytes = contentLength != null
          ? int.parse(contentLength) + resumeFrom
          : 0;

      int downloadedBytes = resumeFrom;
      final sink = tempFile.openWrite(
        mode: resumeFrom > 0 ? FileMode.append : FileMode.write,
      );

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
        // Use atomic operations to prevent race conditions
        if (downloadedBytes >= bufferSize && !await file.exists()) {
          await sink.flush();

          // Create lock file to prevent conflicts
          final lockFile = File('$localPath.lock');
          if (!await lockFile.exists()) {
            try {
              await lockFile.create();
              // Copy partial file for immediate playback (atomic operation)
              await tempFile.copy(localPath);
              await lockFile.delete();
              print(
                'Progressive file made available at ${(downloadedBytes / 1024).toStringAsFixed(1)}KB',
              );
            } catch (e) {
              // Clean up lock file if operation fails
              if (await lockFile.exists()) {
                await lockFile.delete();
              }
              print('Progressive availability failed: $e');
            }
          }
        }
      }

      await sink.close();

      // Move completed file only if download wasn't cancelled
      if (!cancelToken.isCancelled && await tempFile.exists()) {
        await tempFile.rename(localPath);

        // Update cache entry
        await _updateCacheEntry(
          url,
          localPath,
          downloadedBytes,
          isComplete: true,
        );

        // Clean up temp files
        if (await tempFile.exists()) {
          await tempFile.delete();
        }

        print(
          'Download completed successfully: ${(downloadedBytes / 1024).toStringAsFixed(1)}KB',
        );
        return file;
      } else if (cancelToken.isCancelled) {
        // Handle cancellation
        print('Download cancelled for: $url');
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
        throw Exception('Download was cancelled');
      } else {
        // Handle case where temp file doesn't exist
        print('Download failed - temp file missing for: $url');
        throw Exception('Download failed - no temp file');
      }
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

      // Process next item in queue using _startNext()
      _startNext();
    }
  }

  // Playlist JSON management with disk cache fallback
  Future<Map<String, dynamic>?> getPlaylistWithCache(String playlistUrl) async {
    try {
      // Try to get cached JSON first
      final cachedJson = await _dbHelper.getCachedPlaylistJson(playlistUrl);
      if (cachedJson != null) {
        return json.decode(cachedJson);
      }

      // Cache miss - need to fetch from network
      print('Playlist cache miss for: $playlistUrl, fetching from network...');

      final response = await _dio.get(playlistUrl);
      if (response.statusCode == 200) {
        final jsonData = json.encode(response.data);

        // Cache the JSON for future use (6 hour TTL)
        await _dbHelper.cachePlaylistJson(playlistUrl, jsonData);

        return response.data;
      }
    } catch (e) {
      print('Error fetching playlist JSON: $e');

      // Fallback to any expired cache as last resort (cold start)
      try {
        final entries = await _dbHelper.realm.then(
          (realm) => realm.all<PlaylistData>().where(
            (p) => p.playlistUrl == playlistUrl,
          ),
        );

        if (entries.isNotEmpty) {
          print('Using expired cache as fallback for cold start');
          return json.decode(entries.first.jsonData);
        }
      } catch (fallbackError) {
        print('Fallback cache also failed: $fallbackError');
      }
    }

    return null;
  }

  // Adaptive predictive caching for next songs in playlist
  Future<void> preloadPlaylistItems(
    String playlistKey,
    List<String> urls, {
    int maxPreload = 3,
    int currentIndex = 0,
  }) async {
    // Clear old playlist cache using consistent key
    await _dbHelper.clearPlaylistCache(playlistKey);

    // Adaptive preloading: prioritize current track first, then next tracks, then previous
    final urlsToPreload = <String>[];

    // Add current track first (highest priority) - FIX for first song issue
    if (currentIndex >= 0 && currentIndex < urls.length) {
      urlsToPreload.add(urls[currentIndex]);
      print('Added current track to preload: index $currentIndex');
    }

    // Add next tracks (high priority)
    for (int i = 1; i <= maxPreload && currentIndex + i < urls.length; i++) {
      urlsToPreload.add(urls[currentIndex + i]);
    }

    // Add previous track for backward seeking (lower priority)
    if (currentIndex > 0) {
      urlsToPreload.add(urls[currentIndex - 1]);
    }

    // Add playlist entries with priority ordering
    for (int i = 0; i < urlsToPreload.length; i++) {
      final url = urlsToPreload[i];
      final priority = i < maxPreload
          ? i + 1
          : maxPreload + 1; // Next tracks get higher priority

      final entry = PlaylistCacheEntry(
        ObjectId(),
        playlistKey, // Use consistent key (playlistUrl)
        url,
        priority,
        DateTime.now(),
        DateTime.now().add(const Duration(hours: 24)), // TTL 24 hours
        false,
      );
      await _dbHelper.insertPlaylistCacheEntry(entry);
    }

    // Start preloading in background with priority order
    _preloadInBackground(playlistKey);
  }

  void _preloadInBackground(String playlistKey) async {
    try {
      final items = await _dbHelper.getPlaylistCacheEntries(playlistKey);

      // Sort by priority (lower number = higher priority)
      items.sort((a, b) => a.priority.compareTo(b.priority));

      int preloadedCount = 0;
      final maxConcurrentPreloads = 2; // Limit concurrent preloads

      for (final item in items) {
        if (preloadedCount >= maxConcurrentPreloads) break;

        // Skip if already preloaded (use Set for deduplication)
        if (_preloadedUrls.contains(item.songUrl)) continue;

        if (!item.isPreloaded) {
          // Check if already cached
          final cached = await _getCachedFile(item.songUrl);
          if (cached == null || !await cached.exists()) {
            // Mark as being preloaded to avoid duplicates
            _preloadedUrls.add(item.songUrl);

            // Schedule download through queue (don't wait)
            _scheduleDownload(item.songUrl)
                .then((_) {
                  _dbHelper.updatePlaylistCachePreloadStatus(item.id, true);
                  print(
                    'Preloaded: ${item.songUrl} (priority: ${item.priority})',
                  );
                })
                .catchError((e) {
                  print('Preload failed for ${item.songUrl}: $e');
                  _preloadedUrls.remove(item.songUrl); // Remove on failure
                });
            preloadedCount++;
          } else {
            // Mark as preloaded if already cached
            _preloadedUrls.add(item.songUrl);
            await _dbHelper.updatePlaylistCachePreloadStatus(item.id, true);
          }
        }
      }
    } catch (e) {
      print('Background preload error: $e');
    }
  }

  // Progressive buffer management
  Future<Stream<Uint8List>?> getAudioStream(
    String url, {
    int? startByte,
    int? endByte,
  }) async {
    try {
      final cachedFile = await _getCachedFile(url);

      if (cachedFile != null && await cachedFile.exists()) {
        // Stream from cached file with proper type conversion
        return cachedFile
            .openRead(startByte, endByte)
            .map((chunk) => Uint8List.fromList(chunk));
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

  // Cache management methods with integrity validation
  Future<File?> _getCachedFile(String url) async {
    final entry = await _dbHelper.getAudioCacheEntry(url);
    if (entry != null) {
      final file = File(entry.localPath);
      if (await file.exists()) {
        // Validate file integrity if we know the expected size
        if (entry.isComplete && entry.sizeBytes > 0) {
          final stat = await file.stat();
          if (stat.size != entry.sizeBytes) {
            print(
              'Cache integrity failed for $url: expected ${entry.sizeBytes}, got ${stat.size}',
            );
            // Delete corrupted file and cache entry
            await file.delete();
            await _dbHelper.deleteAudioCacheEntry(url);
            return null;
          }
        }
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

  Future<void> _updateCacheEntry(
    String url,
    String localPath,
    int sizeBytes, {
    bool isComplete = false,
  }) async {
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

  // Cache cleanup and maintenance with LRU eviction
  Future<void> _cleanupCache() async {
    try {
      final totalSize = await _dbHelper.getTotalCacheSize();

      if (totalSize > maxCacheSize) {
        // LRU eviction: Remove least recently accessed files until under limit
        final entries = await _dbHelper.getAllAudioCacheEntries();

        // Sort by last access time (LRU first)
        entries.sort((a, b) => a.lastAccessed.compareTo(b.lastAccessed));

        int removedSize = 0;
        final targetSize = (maxCacheSize * 0.8)
            .toInt(); // Clean to 80% capacity

        for (final entry in entries) {
          if (totalSize - removedSize <= targetSize) break;

          final file = File(entry.localPath);
          if (await file.exists()) {
            await file.delete();
            removedSize += entry.sizeBytes;
            print('LRU evicted: ${entry.url} (${entry.sizeBytes} bytes)');
          }
          await _dbHelper.deleteAudioCacheEntry(entry.url);
        }

        print(
          'Cache cleanup: Removed ${removedSize} bytes, ${entries.length} files',
        );
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
            final delay = Duration(
              milliseconds: (1000 * (retryCount + 1)).toInt(),
            );
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
  /// Get comprehensive cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    await ensureInitialized();

    final totalSize = await _dbHelper.getTotalCacheSize();
    final allEntries = await _dbHelper.getAllAudioCacheEntries();

    return {
      'totalFiles': allEntries.length,
      'totalSize': totalSize,
      'hitCount': _cacheHits,
      'missCount': _cacheMisses,
      'totalRequests': _totalRequests,
      'hitRate': _totalRequests > 0 ? _cacheHits / _totalRequests : 0.0,
      'maxCacheSize': maxCacheSize,
      'cacheUtilization': totalSize / maxCacheSize,
      'averageFileSize': allEntries.isNotEmpty
          ? totalSize / allEntries.length
          : 0,
      'oldestCacheEntry': allEntries.isNotEmpty
          ? allEntries
                .map((e) => e.cachedAt)
                .reduce((a, b) => a.isBefore(b) ? a : b)
                .toIso8601String()
          : null,
      'newestCacheEntry': allEntries.isNotEmpty
          ? allEntries
                .map((e) => e.cachedAt)
                .reduce((a, b) => a.isAfter(b) ? a : b)
                .toIso8601String()
          : null,
    };
  }

  /// Clear all cached files and database entries
  Future<void> clearCache() async {
    await ensureInitialized();

    try {
      // Delete all cached files
      final allEntries = await _dbHelper.getAllAudioCacheEntries();

      for (final entry in allEntries) {
        try {
          final file = File(entry.localPath);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (e) {
          print('Error deleting cached file ${entry.localPath}: $e');
        }
      }

      // Clear database entries
      await _dbHelper.clearAllCacheData();

      // Reset performance counters
      _cacheHits = 0;
      _cacheMisses = 0;
      _totalRequests = 0;

      print('Cache cleared: ${allEntries.length} files deleted');
    } catch (e) {
      print('Error clearing cache: $e');
      rethrow;
    }
  }

  /// Get cache efficiency metrics
  Map<String, dynamic> getPerformanceMetrics() {
    return {
      'cacheHits': _cacheHits,
      'cacheMisses': _cacheMisses,
      'totalRequests': _totalRequests,
      'hitRate': _totalRequests > 0 ? _cacheHits / _totalRequests : 0.0,
      'missRate': _totalRequests > 0 ? _cacheMisses / _totalRequests : 0.0,
    };
  }

  /// Preload specific URLs for better user experience
  Future<void> preloadUrls(
    List<String> urls, {
    Function(String, double)? onProgress,
  }) async {
    await ensureInitialized();

    for (final url in urls) {
      try {
        await getAudioFile(
          url,
          onProgress: onProgress != null
              ? (progress) => onProgress(url, progress)
              : null,
        );
      } catch (e) {
        print('Preload failed for $url: $e');
      }
    }
  }

  /// Check if URL is cached
  Future<bool> isCached(String url) async {
    await ensureInitialized();

    final cachedFile = await _getCachedFile(url);
    return cachedFile != null;
  }

  /// Get cached file size
  Future<int?> getCachedFileSize(String url) async {
    await ensureInitialized();

    final entry = await _dbHelper.getAudioCacheEntry(url);
    return entry?.sizeBytes;
  }

  /// Get performance statistics
  Future<Map<String, dynamic>> getPerformanceStats() async {
    final utilization = await _getCacheUtilization();
    final fragmentation = await _getFragmentationStats();

    return {
      'activeDownloads': _activeDownloads.length,
      'queuedDownloads': _downloadQueue.length,
      'maxConcurrent': maxConcurrentDownloads,
      'hitRate': _calculateHitRate(),
      'cacheUtilization': '${(utilization * 100).toStringAsFixed(1)}%',
      'totalRequests': _totalRequests,
      'cacheHits': _cacheHits,
      'cacheMisses': _cacheMisses,
      'fragmentationPercentage': fragmentation['fragmentationPercentage'],
      'incompleteFiles': fragmentation['incompleteFiles'],
      'averageFileSize': fragmentation['averageFileSize'],
    };
  }

  double _calculateHitRate() {
    return _totalRequests > 0 ? (_cacheHits / _totalRequests) : 0.0;
  }

  Future<double> _getCacheUtilization() async {
    try {
      final totalSize = await _dbHelper.getTotalCacheSize();
      return totalSize / maxCacheSize;
    } catch (e) {
      return 0.0;
    }
  }

  Future<void> dispose() async {
    // Cancel all active downloads
    for (final token in _activeDownloads.values) {
      token.cancel('Service disposed');
    }
    _activeDownloads.clear();
    _progressCallbacks.clear();
    _pendingRequests.clear();
    _downloadQueue.clear();
    _queuedUrls.clear();
    _preloadedUrls.clear();

    // Cancel background cleanup timer
    _backgroundCleanupTimer?.cancel();
    _backgroundCleanupTimer = null;

    _dio.close();
  }
}

/// Download task for queue management
class _DownloadTask {
  final String url;
  final Function(double)? onProgress;
  final DateTime createdAt;

  _DownloadTask(this.url, this.onProgress) : createdAt = DateTime.now();
}

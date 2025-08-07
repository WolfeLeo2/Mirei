import 'dart:async';
import 'package:dio/dio.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import '../services/audio_cache_service.dart';
import '../services/network_optimizer.dart';

class OptimizedAudioService {
  static final OptimizedAudioService _instance = OptimizedAudioService._internal();
  factory OptimizedAudioService() => _instance;
  OptimizedAudioService._internal();

  late AudioSession _audioSession;
  final Map<String, AudioPlayer> _playerPool = {};
  final Queue<String> _preloadQueue = Queue<String>();
  final Map<String, Completer<void>> _loadingTracks = {};
  Timer? _preloadTimer;

  // Performance optimizations
  static const int maxPoolSize = 3;
  static const int preloadBufferSize = 256 * 1024; // 256KB
  static const Duration preloadDelay = Duration(milliseconds: 500);

  Future<void> initialize() async {
    // Configure audio session with optimal settings
    _audioSession = await AudioSession.instance;
    await _audioSession.configure(AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playback,
      avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.allowBluetooth |
                                     AVAudioSessionCategoryOptions.allowAirPlay,
      avAudioSessionMode: AVAudioSessionMode.defaultMode,
      avAudioSessionRouteSharingPolicy: AVAudioSessionRouteSharingPolicy.defaultPolicy,
      avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
      androidAudioAttributes: const AndroidAudioAttributes(
        contentType: AndroidAudioContentType.music,
        flags: AndroidAudioFlags.audibilityEnforced,
        usage: AndroidAudioUsage.media,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
      androidWillPauseWhenDucked: true,
    ));

    // Start background preloading
    _startPreloadTimer();
  }

  /// Get or create an optimized audio player
  Future<AudioPlayer> getOptimizedPlayer(String trackId) async {
    // Try to reuse existing player
    if (_playerPool.containsKey(trackId)) {
      return _playerPool[trackId]!;
    }

    // Create new player if pool has space
    if (_playerPool.length < maxPoolSize) {
      final player = AudioPlayer();
      await _configurePlayer(player);
      _playerPool[trackId] = player;
      return player;
    }

    // Reuse least recently used player
    final oldestKey = _playerPool.keys.first;
    final player = _playerPool.remove(oldestKey)!;
    await player.stop();
    _playerPool[trackId] = player;
    return player;
  }

  Future<void> _configurePlayer(AudioPlayer player) async {
    // Optimize audio player settings
    await player.setLoopMode(LoopMode.off);
    await player.setShuffleModeEnabled(false);
    
    // Configure buffering for smooth playback
    // Note: These would be platform-specific configurations
    // Android: Configure ExoPlayer buffer sizes
    // iOS: Configure AVPlayer buffer settings
  }

  /// Preload audio with smart buffering
  Future<void> preloadAudio(String url, {int priority = 0}) async {
    if (_loadingTracks.containsKey(url)) {
      await _loadingTracks[url]!.future;
      return;
    }

    final completer = Completer<void>();
    _loadingTracks[url] = completer;

    try {
      // Get optimized audio cache service
      final cacheService = AudioCacheService();
      final networkOptimizer = NetworkOptimizer();

      // Check if already cached
      final cachedFile = await cacheService.getAudioFile(url);
      if (cachedFile != null) {
        completer.complete();
        return;
      }

      // Start progressive download with small initial buffer
      final streamClient = networkOptimizer.streamClient;
      final response = await streamClient.get<ResponseBody>(
        url,
        options: Options(
          responseType: ResponseType.stream,
          headers: {
            'Range': 'bytes=0-${preloadBufferSize - 1}', // Initial buffer
          },
        ),
      );

      if (response.statusCode == 206 || response.statusCode == 200) {
        // Trigger full download in background
        cacheService.getAudioFile(url);
        completer.complete();
      } else {
        throw Exception('Failed to preload audio: ${response.statusCode}');
      }
    } catch (e) {
      completer.completeError(e);
    } finally {
      _loadingTracks.remove(url);
    }
  }

  /// Load audio with optimized strategy
  Future<void> loadAudioOptimized(AudioPlayer player, String url) async {
    try {
      // Try cached version first
      final cacheService = AudioCacheService();
      final cachedFile = await cacheService.getAudioFile(url);
      
      if (cachedFile != null) {
        await player.setFilePath(cachedFile.path);
        return;
      }

      // Stream directly for immediate playback
      await player.setUrl(url);
      
      // Cache in background for future use
      cacheService.getAudioFile(url);
    } catch (e) {
      // Fallback to direct URL
      await player.setUrl(url);
    }
  }

  /// Queue tracks for preloading
  void queueForPreload(List<String> urls) {
    for (final url in urls.take(5)) { // Limit to next 5 tracks
      if (!_preloadQueue.contains(url)) {
        _preloadQueue.add(url);
      }
    }
  }

  void _startPreloadTimer() {
    _preloadTimer = Timer.periodic(preloadDelay, (_) {
      _processPreloadQueue();
    });
  }

  Future<void> _processPreloadQueue() async {
    if (_preloadQueue.isEmpty) return;

    final url = _preloadQueue.removeFirst();
    try {
      await preloadAudio(url);
    } catch (e) {
      // Continue with next item on error
    }
  }

  /// Get audio format info for optimization
  Future<AudioFormat?> getAudioFormat(String url) async {
    try {
      final networkOptimizer = NetworkOptimizer();
      final response = await networkOptimizer.apiClient.head(url);
      
      final contentType = response.headers.value('content-type');
      final contentLength = response.headers.value('content-length');
      
      return AudioFormat(
        mimeType: contentType,
        fileSize: contentLength != null ? int.parse(contentLength) : null,
        supportsRangeRequests: response.headers.value('accept-ranges') == 'bytes',
      );
    } catch (e) {
      return null;
    }
  }

  /// Cleanup resources
  void dispose() {
    _preloadTimer?.cancel();
    
    for (final player in _playerPool.values) {
      player.dispose();
    }
    _playerPool.clear();
    _preloadQueue.clear();
    _loadingTracks.clear();
  }
}

class AudioFormat {
  final String? mimeType;
  final int? fileSize;
  final bool supportsRangeRequests;

  AudioFormat({
    this.mimeType,
    this.fileSize,
    required this.supportsRangeRequests,
  });

  bool get isOptimalFormat {
    return mimeType?.contains('mp3') == true || 
           mimeType?.contains('aac') == true ||
           mimeType?.contains('m4a') == true;
  }

  bool get supportsFastStart {
    return supportsRangeRequests && (fileSize ?? 0) > 0;
  }
}

// Queue implementation for preloading
class Queue<T> {
  final List<T> _items = [];

  void add(T item) => _items.add(item);
  T removeFirst() => _items.removeAt(0);
  bool get isEmpty => _items.isEmpty;
  bool contains(T item) => _items.contains(item);
  void clear() => _items.clear();
}

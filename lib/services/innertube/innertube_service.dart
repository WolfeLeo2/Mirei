import 'dart:convert';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'models/innertube_models.dart';
import 'models/search_models.dart';
import '../../../models/youtube_music_models.dart' as ytm;

/// Main InnerTube service for YouTube Music API access
class InnerTubeService {
  static const String _baseUrl = 'https://music.youtube.com/youtubei/v1';
  static const String _pipedBaseUrl = 'https://pipedapi.kavin.rocks';
  
  final Dio _dio;
  final List<YouTubeClient> _clients;
  int _currentClientIndex = 0;
  String? _visitorData;
  
  // Rate limiting
  DateTime? _lastRequestTime;
  static const Duration _minRequestInterval = Duration(milliseconds: 100);
  
  // Caching
  final Map<String, CachedResponse> _cache = {};
  static const Duration _cacheExpiry = Duration(minutes: 30);

  InnerTubeService() : 
    _dio = Dio(),
    _clients = const [
      YouTubeClient.androidMusic,
      YouTubeClient.ios,
      YouTubeClient.webRemix,
      YouTubeClient.tvHtml5,
    ] {
    _setupDio();
  }

  void _setupDio() {
    _dio.options = BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      followRedirects: true,
      headers: {
        'Accept': 'application/json, text/plain, */*',
        'Accept-Encoding': 'gzip, deflate, br',
        'Accept-Language': 'en-US,en;q=0.9',
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'DNT': '1',
        'Connection': 'keep-alive',
        'Sec-Fetch-Dest': 'empty',
        'Sec-Fetch-Mode': 'cors',
        'Sec-Fetch-Site': 'cross-site',
      },
    );

    // Add interceptors for logging and error handling
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        print('[InnerTube] ${options.method} ${options.uri}');
        handler.next(options);
      },
      onError: (error, handler) {
        print('[InnerTube] Error: ${error.message}');
        handler.next(error);
      },
    ));
  }

  /// Initialize the service with visitor data
  Future<void> initialize() async {
    try {
      _visitorData = await _getVisitorData();
      print('[InnerTube] Initialized with visitor data: ${_visitorData?.substring(0, 10)}...');
    } catch (e) {
      print('[InnerTube] Failed to initialize visitor data: $e');
    }
  }

  /// Get streaming URLs for a video
  Future<StreamingData?> getStreamingData(String videoId) async {
    // Check cache first
    final cacheKey = 'streaming_$videoId';
    final cached = _getFromCache(cacheKey);
    if (cached != null) {
      return StreamingData.fromJson(cached.data);
    }

    // Try each client until one works
    for (int i = 0; i < _clients.length; i++) {
      try {
        final client = _clients[(_currentClientIndex + i) % _clients.length];
        final streamingData = await _getStreamingDataWithClient(videoId, client);
        
        if (streamingData != null && streamingData.adaptiveFormats.isNotEmpty) {
          // Cache successful response
          _setCache(cacheKey, streamingData.toJson());
          // Update current client for future requests
          _currentClientIndex = (_currentClientIndex + i) % _clients.length;
          return streamingData;
        }
      } catch (e) {
        print('[InnerTube] Client ${_clients[(_currentClientIndex + i) % _clients.length].clientName} failed: $e');
      }
    }

    // Fallback to multiple APIs
    print('[InnerTube] All clients failed, trying fallback APIs...');
    return await _tryFallbackApis(videoId);
  }

  Future<StreamingData?> _getStreamingDataWithClient(String videoId, YouTubeClient client) async {
    await _rateLimit();

    final response = await _dio.post(
      '$_baseUrl/player',
      data: {
        'context': client.context,
        'videoId': videoId,
        'playbackContext': {
          'contentPlaybackContext': {
            'vis': _visitorData ?? '',
            'splay': false,
            'lactMilliseconds': '1234',
            'signatureTimestamp': _getSignatureTimestamp(),
          }
        },
        'attestationRequest': {
          'omitBotguardData': true,
        },
      },
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'X-YouTube-Client-Name': client.clientName,
          'X-YouTube-Client-Version': client.clientVersion,
          'Origin': 'https://music.youtube.com',
          'Referer': 'https://music.youtube.com/',
        },
      ),
    );

    if (response.statusCode == 200) {
      final data = response.data;
      if (data['streamingData'] != null) {
        return StreamingData.fromJson(data['streamingData']);
      }
    }

    return null;
  }

  /// Fetch fresh list of Piped instances (fallback to hardcoded if fails)
  Future<List<String>> _getFreshPipedInstances() async {
    try {
      print('[InnerTube] Fetching fresh Piped instances...');
      final response = await _dio.get(
        'https://raw.githubusercontent.com/TeamPiped/documentation/main/content/docs/public-instances/index.md',
        options: Options(
          receiveTimeout: const Duration(seconds: 10),
          headers: {
            'User-Agent': 'Mozilla/5.0 (compatible; PipedAPI/1.0)',
          },
        ),
      );

      if (response.statusCode == 200) {
        final content = response.data as String;
        final instances = <String>[];
        
        // Parse markdown table for API URLs
        final lines = content.split('\n');
        for (final line in lines) {
          if (line.contains('https://') && line.contains('pipedapi') || line.contains('api.piped')) {
            final regex = RegExp(r'https://[^\s|]+');
            final match = regex.firstMatch(line);
            if (match != null) {
              final url = match.group(0)!.trim();
              if (url.contains('api') || url.contains('pipedapi')) {
                instances.add(url);
              }
            }
          }
        }
        
        if (instances.isNotEmpty) {
          print('[InnerTube] Found ${instances.length} fresh instances');
          return instances;
        }
      }
    } catch (e) {
      print('[InnerTube] Failed to fetch fresh instances: $e');
    }

    // Fallback to hardcoded list
    return [
      'https://pipedapi.kavin.rocks',        // Official
      'https://pipedapi.leptons.xyz',        // Austria 
      'https://pipedapi.nosebs.ru',          // Finland
      'https://piped-api.privacy.com.de',    // Germany
      'https://pipedapi.adminforge.de',      // Germany
      'https://api.piped.yt',                // Germany
      'https://pipedapi.drgns.space',        // US
      'https://piapi.ggtyler.dev',           // US
      'https://pipedapi.owo.si',             // Germany
      'https://pipedapi.ducks.party',        // Netherlands
      'https://piped-api.codespace.cz',      // Czech Republic
      'https://pipedapi.reallyaweso.me',     // Germany
      'https://api.piped.private.coffee',    // Austria
      'https://pipedapi.darkness.services',  // US
      'https://pipedapi.orangenet.cc',       // Slovenia
    ];
  }

  Future<StreamingData?> _tryFallbackApis(String videoId) async {
    // Get fresh instance list
    final fallbackApis = await _getFreshPipedInstances();

    for (final apiBase in fallbackApis) {
      try {
        print('[InnerTube] Trying Piped API: $apiBase');
        final response = await _dio.get(
          '$apiBase/streams/$videoId',
          options: Options(
            receiveTimeout: const Duration(seconds: 15),
            sendTimeout: const Duration(seconds: 10),
            followRedirects: true,
            headers: {
              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
              'Accept': 'application/json, text/plain, */*',
              'Accept-Language': 'en-US,en;q=0.9',
              'Accept-Encoding': 'gzip, deflate, br',
              'DNT': '1',
              'Connection': 'keep-alive',
              'Sec-Fetch-Dest': 'empty',
              'Sec-Fetch-Mode': 'cors',
              'Sec-Fetch-Site': 'cross-site',
              'Pragma': 'no-cache',
              'Cache-Control': 'no-cache',
            },
          ),
        );
        
        if (response.statusCode == 200 && response.data != null) {
          final data = response.data;
          
          // Validate response structure
          if (data is Map<String, dynamic> && 
              (data.containsKey('audioStreams') || data.containsKey('videoStreams'))) {
            print('[InnerTube] Success with $apiBase');
            return StreamingData.fromPiped(data);
          } else {
            print('[InnerTube] $apiBase returned invalid data structure');
            continue;
          }
        } else {
          print('[InnerTube] $apiBase returned status: ${response.statusCode}');
        }
      } catch (e) {
        final errorMsg = e.toString();
        if (errorMsg.contains('502')) {
          print('[InnerTube] $apiBase: Server error (502) - Instance may be down');
        } else if (errorMsg.contains('403')) {
          print('[InnerTube] $apiBase: Forbidden (403) - IP may be blocked');
        } else if (errorMsg.contains('429')) {
          print('[InnerTube] $apiBase: Rate limited (429) - Too many requests');
        } else if (errorMsg.contains('timeout')) {
          print('[InnerTube] $apiBase: Request timeout');
        } else {
          print('[InnerTube] $apiBase failed: ${errorMsg.length > 100 ? errorMsg.substring(0, 100) + "..." : errorMsg}');
        }
        
        // Add delay between requests to avoid rate limiting
        await Future.delayed(const Duration(milliseconds: 500));
        continue;
      }
    }

    // Try YouTube Explode as final fallback
    print('[InnerTube] All Piped APIs failed, trying direct extraction...');
    return await _tryDirectExtraction(videoId);
  }

  Future<StreamingData?> _tryDirectExtraction(String videoId) async {
    try {
      // This is a simplified direct extraction attempt
      // In a real implementation, you'd need to reverse engineer YouTube's player
      print('[InnerTube] Direct extraction not implemented yet');
      return null;
    } catch (e) {
      print('[InnerTube] Direct extraction failed: $e');
      return null;
    }
  }

  /// Test if Piped instances are accessible
  Future<Map<String, bool>> testPipedInstances() async {
    final instances = await _getFreshPipedInstances();
    final results = <String, bool>{};
    
    print('[InnerTube] Testing ${instances.length} Piped instances...');
    
    for (final instance in instances.take(5)) { // Test first 5 only
      try {
        final response = await _dio.get(
          '$instance/trending',
          options: Options(
            receiveTimeout: const Duration(seconds: 5),
            headers: {
              'User-Agent': 'Mozilla/5.0 (compatible; PipedTest/1.0)',
            },
          ),
        );
        
        results[instance] = response.statusCode == 200;
        print('[InnerTube] $instance: ${response.statusCode == 200 ? "✅ OK" : "❌ Failed"}');
      } catch (e) {
        results[instance] = false;
        print('[InnerTube] $instance: ❌ Error - ${e.toString().split('\n').first}');
      }
      
      // Small delay to avoid overwhelming servers
      await Future.delayed(const Duration(milliseconds: 200));
    }
    
    return results;
  }

  Future<StreamingData?> _getStreamingDataFromPiped(String videoId) async {
    try {
      final response = await _dio.get('$_pipedBaseUrl/streams/$videoId');
      
      if (response.statusCode == 200) {
        final data = response.data;
        return StreamingData.fromPiped(data);
      }
    } catch (e) {
      print('[InnerTube] Piped API failed: $e');
    }
    
    return null;
  }

  /// Search for content
  Future<SearchResult> search(String query, {String? continuation}) async {
    final cacheKey = 'search_${query}_${continuation ?? ''}';
    final cached = _getFromCache(cacheKey);
    if (cached != null) {
      return SearchResult(
        songs: (cached.data['songs'] as List).map((e) => ytm.YouTubeSong.fromJson(e)).toList(),
        artists: (cached.data['artists'] as List).map((e) => ytm.YouTubeArtist.fromJson(e)).toList(),
        albums: (cached.data['albums'] as List).map((e) => ytm.YouTubeAlbum.fromJson(e)).toList(),
        playlists: (cached.data['playlists'] as List).map((e) => ytm.YouTubePlaylist.fromJson(e)).toList(),
      );
    }

    await _rateLimit();

    final client = _clients[_currentClientIndex];
    final Map<String, dynamic> requestData = {
      'context': client.context,
      'query': query,
    };

    if (continuation != null) {
      requestData['continuation'] = continuation;
    } else {
      requestData['params'] = 'Eg-KAQwIARAAGAAgACgAMABqChAEEAUQAxAKEAk%3D'; // Music search params
    }

    try {
      final response = await _dio.post(
        '$_baseUrl/search',
        data: requestData,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'X-YouTube-Client-Name': client.clientName,
            'X-YouTube-Client-Version': client.clientVersion,
            'Origin': 'https://music.youtube.com',
            'Referer': 'https://music.youtube.com/',
          },
        ),
      );

      if (response.statusCode == 200) {
        final searchResponse = SearchResponse.fromJson(response.data);
        final result = searchResponse.parseResults();
        
        // Cache result
        _setCache(cacheKey, {
          'songs': result.songs.map((e) => e.toJson()).toList(),
          'artists': result.artists.map((e) => e.toJson()).toList(),
          'albums': result.albums.map((e) => e.toJson()).toList(),
          'playlists': result.playlists.map((e) => e.toJson()).toList(),
        });
        
        return result;
      }
    } catch (e) {
      print('[InnerTube] Search failed: $e');
    }

    return SearchResult(songs: [], artists: [], albums: [], playlists: []);
  }

  /// Get album details
  Future<ytm.YouTubeAlbum?> getAlbum(String browseId) async {
    final cacheKey = 'album_$browseId';
    final cached = _getFromCache(cacheKey);
    if (cached != null) {
      return ytm.YouTubeAlbum.fromJson(cached.data);
    }

    await _rateLimit();

    final client = _clients[_currentClientIndex];
    
    try {
      final response = await _dio.post(
        '$_baseUrl/browse',
        data: {
          'context': client.context,
          'browseId': browseId,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'X-YouTube-Client-Name': client.clientName,
            'X-YouTube-Client-Version': client.clientVersion,
            'Origin': 'https://music.youtube.com',
            'Referer': 'https://music.youtube.com/',
          },
        ),
      );

      if (response.statusCode == 200) {
        final album = _parseAlbumResponse(response.data, browseId);
        if (album != null) {
          _setCache(cacheKey, album.toJson());
        }
        return album;
      }
    } catch (e) {
      print('[InnerTube] Get album failed: $e');
    }

    return null;
  }

  /// Get playlist details
  Future<ytm.YouTubePlaylist?> getPlaylist(String playlistId) async {
    final cacheKey = 'playlist_$playlistId';
    final cached = _getFromCache(cacheKey);
    if (cached != null) {
      return ytm.YouTubePlaylist.fromJson(cached.data);
    }

    await _rateLimit();

    final client = _clients[_currentClientIndex];
    final browseId = playlistId.startsWith('VL') ? playlistId : 'VL$playlistId';
    
    try {
      final response = await _dio.post(
        '$_baseUrl/browse',
        data: {
          'context': client.context,
          'browseId': browseId,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'X-YouTube-Client-Name': client.clientName,
            'X-YouTube-Client-Version': client.clientVersion,
            'Origin': 'https://music.youtube.com',
            'Referer': 'https://music.youtube.com/',
          },
        ),
      );

      if (response.statusCode == 200) {
        final playlist = _parsePlaylistResponse(response.data, playlistId);
        if (playlist != null) {
          _setCache(cacheKey, playlist.toJson());
        }
        return playlist;
      }
    } catch (e) {
      print('[InnerTube] Get playlist failed: $e');
    }

    return null;
  }

  /// Get suggested content (home screen)
  Future<List<ytm.YouTubeSong>> getSuggestions() async {
    const cacheKey = 'suggestions';
    final cached = _getFromCache(cacheKey);
    if (cached != null) {
      return (cached.data as List).map((e) => ytm.YouTubeSong.fromJson(e)).toList();
    }

    await _rateLimit();

    final client = _clients[_currentClientIndex];
    
    try {
      final response = await _dio.post(
        '$_baseUrl/browse',
        data: {
          'context': client.context,
          'browseId': 'FEmusic_home',
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'X-YouTube-Client-Name': client.clientName,
            'X-YouTube-Client-Version': client.clientVersion,
            'Origin': 'https://music.youtube.com',
            'Referer': 'https://music.youtube.com/',
          },
        ),
      );

      if (response.statusCode == 200) {
        final suggestions = _parseSuggestionsResponse(response.data);
        _setCache(cacheKey, suggestions.map((e) => e.toJson()).toList());
        return suggestions;
      }
    } catch (e) {
      print('[InnerTube] Get suggestions failed: $e');
    }

    return [];
  }

  // Helper methods for parsing responses
  ytm.YouTubeAlbum? _parseAlbumResponse(Map<String, dynamic> data, String browseId) {
    // Complex parsing logic for album data
    // Implementation would be similar to search parsing but for album structure
    return null; // Placeholder
  }

  ytm.YouTubePlaylist? _parsePlaylistResponse(Map<String, dynamic> data, String playlistId) {
    // Complex parsing logic for playlist data
    return null; // Placeholder
  }

  List<ytm.YouTubeSong> _parseSuggestionsResponse(Map<String, dynamic> data) {
    // Parse home page suggestions
    return []; // Placeholder
  }

  // Utility methods
  Future<String?> _getVisitorData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? cached = prefs.getString('innertube_visitor_data');
      
      if (cached != null) {
        return cached;
      }

      // Get fresh visitor data
      final response = await _dio.get('https://music.youtube.com/');
      final html = response.data as String;
      
      final match = RegExp(r'"VISITOR_DATA":"([^"]+)"').firstMatch(html);
      if (match != null) {
        final visitorData = match.group(1)!;
        await prefs.setString('innertube_visitor_data', visitorData);
        return visitorData;
      }
    } catch (e) {
      print('[InnerTube] Failed to get visitor data: $e');
    }
    
    return null;
  }

  int _getSignatureTimestamp() {
    // This would normally be extracted from the YouTube page
    // For now, use a reasonable default
    return 19369;
  }

  Future<void> _rateLimit() async {
    if (_lastRequestTime != null) {
      final elapsed = DateTime.now().difference(_lastRequestTime!);
      if (elapsed < _minRequestInterval) {
        await Future.delayed(_minRequestInterval - elapsed);
      }
    }
    _lastRequestTime = DateTime.now();
  }

  CachedResponse? _getFromCache(String key) {
    final cached = _cache[key];
    if (cached != null && DateTime.now().difference(cached.timestamp) < _cacheExpiry) {
      return cached;
    }
    _cache.remove(key);
    return null;
  }

  void _setCache(String key, dynamic data) {
    _cache[key] = CachedResponse(data: data, timestamp: DateTime.now());
  }

  /// Check network connectivity
  Future<bool> hasConnection() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }

  /// Clear all caches
  void clearCache() {
    _cache.clear();
  }

  /// Dispose resources
  void dispose() {
    _dio.close();
    _cache.clear();
  }
}

class CachedResponse {
  final dynamic data;
  final DateTime timestamp;

  CachedResponse({required this.data, required this.timestamp});
}

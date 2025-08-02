import 'dart:convert';
import 'package:http/http.dart' as http;

/// Custom InnerTube client for YouTube Music streaming
/// Based on InnerTune's implementation
class InnerTubeService {
  static const String _baseUrl = 'https://music.youtube.com/youtubei/v1/';
  static const String _visitorData = 'CgtsZG1ySnZiQWtSbyiMjuGSBg%3D%3D';
  
  // Different client types for maximum compatibility
  static const Map<String, Map<String, dynamic>> _clients = {
    'ANDROID_MUSIC': {
      'clientName': 'ANDROID_MUSIC',
      'clientVersion': '6.42.52',
      'androidSdkVersion': 31,
      'userAgent': 'com.google.android.apps.youtube.music/6.42.52 (Linux; U; Android 12; SM-G973F) gzip',
    },
    'IOS': {
      'clientName': 'IOS',
      'clientVersion': '18.49.37',
      'deviceModel': 'iPhone14,2',
      'userAgent': 'com.google.ios.youtubemusic/6.42.52 (iPhone; U; CPU iPhone OS 15_6 like Mac OS X)',
    },
    'WEB_REMIX': {
      'clientName': 'WEB_REMIX',
      'clientVersion': '1.20220606.03.00',
      'userAgent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
    },
    'TVHTML5': {
      'clientName': 'TVHTML5_SIMPLY_EMBEDDED_PLAYER',
      'clientVersion': '2.0',
      'userAgent': 'Mozilla/5.0 (SMART-TV; LINUX; Tizen 6.0) AppleWebKit/537.36',
    }
  };

  final http.Client _httpClient;
  String? _cookie;

  InnerTubeService({http.Client? httpClient}) : _httpClient = httpClient ?? http.Client();

  /// Get streaming URLs for a video
  /// This is the core method that InnerTune uses
  Future<PlayerResponse?> getPlayer(String videoId, {String? playlistId}) async {
    // Try ANDROID_MUSIC first (best for logged-in users)
    if (_cookie != null) {
      final response = await _makePlayerRequest('ANDROID_MUSIC', videoId, playlistId);
      if (response?.playabilityStatus?.status == 'OK') {
        return response;
      }
    }

    // Fallback to IOS client
    final iosResponse = await _makePlayerRequest('IOS', videoId, playlistId);
    if (iosResponse?.playabilityStatus?.status == 'OK') {
      return iosResponse;
    }

    // Last resort: TVHTML5 with external streams
    final tvResponse = await _makePlayerRequest('TVHTML5', videoId, playlistId);
    if (tvResponse?.playabilityStatus?.status != 'OK') {
      return iosResponse; // Return the iOS response even if failed
    }

    // Try to get audio streams from Piped API as fallback
    try {
      final pipedStreams = await _getPipedStreams(videoId);
      if (pipedStreams != null && pipedStreams.isNotEmpty) {
        // Merge TV response with Piped audio streams
        return _mergeWithPipedStreams(tvResponse!, pipedStreams);
      }
    } catch (e) {
      print('Piped API fallback failed: $e');
    }

    return tvResponse;
  }

  Future<PlayerResponse?> _makePlayerRequest(String clientType, String videoId, String? playlistId) async {
    final client = _clients[clientType]!;
    final url = Uri.parse('${_baseUrl}player');
    
    final body = {
      'context': {
        'client': client,
        'user': {'lockedSafetyMode': false},
        'request': {'useSsl': true},
      },
      'videoId': videoId,
      if (playlistId != null) 'playlistId': playlistId,
    };

    // Special handling for TVHTML5 embedded player
    if (clientType == 'TVHTML5') {
      final context = body['context'] as Map<String, dynamic>?;
      if (context != null) {
        context['thirdParty'] = {
          'embedUrl': 'https://www.youtube.com/watch?v=$videoId'
        };
      }
    }

    try {
      final response = await _httpClient.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': client['userAgent'],
          'X-Goog-Api-Format-Version': '1',
          'X-YouTube-Client-Name': client['clientName'],
          'X-YouTube-Client-Version': client['clientVersion'],
          if (_cookie != null) 'Cookie': _cookie!,
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return PlayerResponse.fromJson(data);
      }
    } catch (e) {
      print('Player request failed for $clientType: $e');
    }

    return null;
  }

  /// Fallback to Piped API for audio streams
  Future<List<AudioStream>?> _getPipedStreams(String videoId) async {
    try {
      final url = Uri.parse('https://pipedapi.kavin.rocks/streams/$videoId');
      final response = await _httpClient.get(url);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final audioStreams = data['audioStreams'] as List?;
        
        return audioStreams?.map((stream) => AudioStream.fromJson(stream)).toList();
      }
    } catch (e) {
      print('Piped API request failed: $e');
    }
    return null;
  }

  PlayerResponse _mergeWithPipedStreams(PlayerResponse tvResponse, List<AudioStream> pipedStreams) {
    // This would merge the TV response with Piped audio streams
    // Implementation would be complex and require careful stream matching
    return tvResponse; // Simplified for now
  }

  /// Search YouTube Music
  Future<SearchResponse?> search(String query) async {
    final url = Uri.parse('${_baseUrl}search');
    
    final body = {
      'context': {
        'client': _clients['WEB_REMIX']!,
      },
      'query': query,
      'params': 'EgWKAQIIAWoKEAkQBRAKEAMQBA%3D%3D', // Music search filter
    };

    try {
      final response = await _httpClient.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': _clients['WEB_REMIX']!['userAgent'],
          if (_cookie != null) 'Cookie': _cookie!,
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return SearchResponse.fromJson(data);
      }
    } catch (e) {
      print('Search request failed: $e');
    }

    return null;
  }

  void setCookie(String cookie) {
    _cookie = cookie;
  }

  void dispose() {
    _httpClient.close();
  }
}

// Data models (simplified versions of InnerTune's models)
class PlayerResponse {
  final PlayabilityStatus? playabilityStatus;
  final StreamingData? streamingData;
  final VideoDetails? videoDetails;

  PlayerResponse({
    this.playabilityStatus,
    this.streamingData,
    this.videoDetails,
  });

  factory PlayerResponse.fromJson(Map<String, dynamic> json) {
    return PlayerResponse(
      playabilityStatus: json['playabilityStatus'] != null 
          ? PlayabilityStatus.fromJson(json['playabilityStatus']) 
          : null,
      streamingData: json['streamingData'] != null 
          ? StreamingData.fromJson(json['streamingData']) 
          : null,
      videoDetails: json['videoDetails'] != null 
          ? VideoDetails.fromJson(json['videoDetails']) 
          : null,
    );
  }
}

class PlayabilityStatus {
  final String status;
  final String? reason;

  PlayabilityStatus({required this.status, this.reason});

  factory PlayabilityStatus.fromJson(Map<String, dynamic> json) {
    return PlayabilityStatus(
      status: json['status'] ?? '',
      reason: json['reason'],
    );
  }
}

class StreamingData {
  final List<Format> adaptiveFormats;
  final int expiresInSeconds;

  StreamingData({required this.adaptiveFormats, required this.expiresInSeconds});

  factory StreamingData.fromJson(Map<String, dynamic> json) {
    final formats = (json['adaptiveFormats'] as List?)
        ?.map((f) => Format.fromJson(f))
        .where((f) => f.isAudio) // Only audio formats
        .toList() ?? [];
    
    return StreamingData(
      adaptiveFormats: formats,
      expiresInSeconds: json['expiresInSeconds'] ?? 0,
    );
  }
}

class Format {
  final int itag;
  final String? url;
  final String mimeType;
  final int bitrate;
  final int? audioSampleRate;

  Format({
    required this.itag,
    this.url,
    required this.mimeType,
    required this.bitrate,
    this.audioSampleRate,
  });

  bool get isAudio => mimeType.startsWith('audio/') && url != null;

  factory Format.fromJson(Map<String, dynamic> json) {
    return Format(
      itag: json['itag'] ?? 0,
      url: json['url'],
      mimeType: json['mimeType'] ?? '',
      bitrate: json['bitrate'] ?? 0,
      audioSampleRate: int.tryParse(json['audioSampleRate']?.toString() ?? '0'),
    );
  }
}

class VideoDetails {
  final String videoId;
  final String title;
  final String author;
  final String lengthSeconds;

  VideoDetails({
    required this.videoId,
    required this.title,
    required this.author,
    required this.lengthSeconds,
  });

  factory VideoDetails.fromJson(Map<String, dynamic> json) {
    return VideoDetails(
      videoId: json['videoId'] ?? '',
      title: json['title'] ?? '',
      author: json['author'] ?? '',
      lengthSeconds: json['lengthSeconds'] ?? '0',
    );
  }
}

class AudioStream {
  final String url;
  final int bitrate;
  final String mimeType;

  AudioStream({required this.url, required this.bitrate, required this.mimeType});

  factory AudioStream.fromJson(Map<String, dynamic> json) {
    return AudioStream(
      url: json['url'] ?? '',
      bitrate: json['bitrate'] ?? 0,
      mimeType: json['mimeType'] ?? '',
    );
  }
}

class SearchResponse {
  // Simplified search response structure
  final List<dynamic> contents;

  SearchResponse({required this.contents});

  factory SearchResponse.fromJson(Map<String, dynamic> json) {
    return SearchResponse(
      contents: json['contents'] ?? [],
    );
  }
}

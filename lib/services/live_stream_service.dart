import 'package:dio/dio.dart';
import 'package:just_audio/just_audio.dart';

class LiveStreamService {
  /// Play LoFi Hip Hop live stream using internal API extraction
  Future<bool> playLofiHipHop(AudioPlayer player) async {
    const lofiUrl = 'https://youtu.be/28KRPhVzCus';
    print('LiveStreamService: Attempting to play LoFi Hip Hop live stream');
    final streamUrl = await extractStreamUrlWithInternalApi(lofiUrl);
    if (streamUrl == null) {
      print('LiveStreamService: Failed to extract LoFi Hip Hop stream URL');
      return false;
    }
    print('LiveStreamService: LoFi Hip Hop stream URL: $streamUrl');
    try {
      await player.setAudioSource(
        AudioSource.uri(
          Uri.parse(streamUrl),
          headers: {
            'User-Agent': 'Mozilla/5.0',
            'Referer': 'https://www.youtube.com/',
          },
        ),
      );
      await player.play();
      return true;
    } catch (e) {
      print('LiveStreamService: Error playing LoFi Hip Hop: $e');
      return false;
    }
  }

  /// Extract stream URL using YouTube internal API (ViMusic approach)
  Future<String?> extractStreamUrlWithInternalApi(String youtubeUrl) async {
    try {
      final videoId = _extractVideoId(youtubeUrl);
      if (videoId == null) throw Exception('Invalid YouTube URL');

      final endpoint =
          'https://www.youtube.com/youtubei/v1/player?key=AIzaSyAO_FJ2SlqU8Q4STEHLGCilw_Y9_11qcW8'; // Example key, replace with a valid one if needed
      final payload = {
        'context': {
          'client': {
            'clientName': 'ANDROID',
            'clientVersion': '17.31.35',
            'androidSdkVersion': 30,
            'userAgent':
                'com.google.android.youtube/17.31.35 (Linux; U; Android 11)',
          },
        },
        'videoId': videoId,
        'playbackContext': {
          'contentPlaybackContext': {
            'signatureTimestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
          },
        },
      };

      final headers = {
        'Content-Type': 'application/json',
        'User-Agent':
            'com.google.android.youtube/17.31.35 (Linux; U; Android 11)',
        'X-YouTube-Client-Name': '3',
        'X-YouTube-Client-Version': '17.31.35',
      };

      final response = await Dio().post(
        endpoint,
        data: payload,
        options: Options(headers: headers),
      );
      if (response.statusCode == 200) {
        final data = response.data;
        // Try to get HLS manifest URL
        final hlsManifestUrl = data['streamingData']?['hlsManifestUrl'];
        if (hlsManifestUrl != null) {
          return hlsManifestUrl;
        }
        // Try to get audio-only URL
        final adaptiveFormats = data['streamingData']?['adaptiveFormats'] ?? [];
        for (final format in adaptiveFormats) {
          if ((format['mimeType'] ?? '').contains('audio')) {
            return format['url'];
          }
        }
      }
    } catch (e) {
      print('LiveStreamService: Internal API extraction failed: $e');
    }
    return null;
  }

  static final LiveStreamService _instance = LiveStreamService._internal();
  factory LiveStreamService() => _instance;
  LiveStreamService._internal();

  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
        'Accept':
            'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
        'Accept-Language': 'en-US,en;q=0.5',
        'Accept-Encoding': 'gzip, deflate',
        'DNT': '1',
        'Connection': 'keep-alive',
        'Upgrade-Insecure-Requests': '1',
      },
    ),
  );

  /// Predefined live streaming channels
  static const Map<String, String> liveChannels = {
    'LoFi Hip Hop Radio':
        'https://youtu.be/28KRPhVzCus', // ChilledCow/Lofi Girl
    'Chillhop Radio': 'https://www.youtube.com/watch?v=5yx6BWlEVcY',
    'Jazz Radio': 'https://www.youtube.com/watch?v=kgx4WGK0oNU',
    'Study Radio': 'https://www.youtube.com/watch?v=lTRiuFIWV54',
    'Ambient Music': 'https://www.youtube.com/watch?v=4xDzrJKXOOY',
    'Piano Radio': 'https://www.youtube.com/watch?v=2MsN8gpT6jY',
  };

  /// Extract audio stream URL from YouTube video
  Future<String?> getYouTubeAudioUrl(String youtubeUrl) async {
    try {
      print('LiveStreamService: Extracting audio URL from: $youtubeUrl');

      // Extract video ID from URL
      final videoId = _extractVideoId(youtubeUrl);
      if (videoId == null) {
        throw Exception('Invalid YouTube URL');
      }

      // Method 1: Try youtube-dl approach (requires server-side processing)
      String? audioUrl = await _extractWithYoutubeDl(videoId);
      if (audioUrl != null) {
        print('LiveStreamService: Audio URL extracted: $audioUrl');
        return audioUrl;
      }

      // Method 2: Try direct m3u8 extraction for live streams
      audioUrl = await _extractLiveStreamUrl(videoId);
      if (audioUrl != null) {
        print('LiveStreamService: Live stream URL extracted: $audioUrl');
        return audioUrl;
      }

      // Method 3: Try YouTube internal API (ViMusic approach)
      audioUrl = await extractStreamUrlWithInternalApi(youtubeUrl);
      if (audioUrl != null) {
        print(
          'LiveStreamService: Internal API stream URL extracted: $audioUrl',
        );
        return audioUrl;
      }

      throw Exception('Could not extract audio URL');
    } catch (e) {
      print('LiveStreamService: Error extracting YouTube URL: $e');
      return null;
    }
  }

  /// Extract video ID from various YouTube URL formats
  String? _extractVideoId(String url) {
    final regExp = RegExp(
      r'(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})',
      caseSensitive: false,
    );

    final match = regExp.firstMatch(url);
    return match?.group(1);
  }

  /// Method 1: Use youtube-dl API (requires backend service)
  Future<String?> _extractWithYoutubeDl(String videoId) async {
    try {
      // You'll need to implement a backend service that runs youtube-dl
      // This is a placeholder for the API endpoint
      const apiEndpoint = 'https://your-backend.com/api/youtube-extract';

      final response = await _dio.post(
        apiEndpoint,
        data: {'video_id': videoId, 'format': 'audio'},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return data['audio_url'];
      }
    } catch (e) {
      print('LiveStreamService: youtube-dl extraction failed: $e');
    }
    return null;
  }

  /// Method 2: Extract live stream m3u8 URL directly
  Future<String?> _extractLiveStreamUrl(String videoId) async {
    try {
      final watchUrl = 'https://www.youtube.com/watch?v=$videoId';
      final response = await _dio.get(watchUrl);

      if (response.statusCode == 200) {
        final htmlContent = response.data;

        // Look for HLS manifest URLs in the page source
        final hlsRegex = RegExp(r'"hlsManifestUrl":"([^"]+)"');
        final match = hlsRegex.firstMatch(htmlContent);

        if (match != null) {
          String manifestUrl = match.group(1)!;
          manifestUrl = manifestUrl.replaceAll(r'\u0026', '&');

          // Get audio-only stream from manifest
          return await _getAudioFromManifest(manifestUrl);
        }
      }
    } catch (e) {
      print('LiveStreamService: Live stream extraction failed: $e');
    }
    return null;
  }

  /// Extract audio stream from HLS manifest
  Future<String?> _getAudioFromManifest(String manifestUrl) async {
    try {
      final response = await _dio.get(manifestUrl);

      if (response.statusCode == 200) {
        final manifestContent = response.data;
        final lines = manifestContent.split('\n');

        // Find audio-only .m3u8 streams
        for (int i = 0; i < lines.length; i++) {
          final line = lines[i];
          if (line.contains('TYPE=AUDIO') && i + 1 < lines.length) {
            final url = lines[i + 1].trim();
            if (url.endsWith('.m3u8')) return url;
          }
        }

        // Fallback: return first .m3u8 stream URL
        for (final line in lines) {
          if (line.startsWith('https://') && line.trim().endsWith('.m3u8')) {
            return line.trim();
          }
        }
      }
    } catch (e) {
      print('LiveStreamService: Manifest parsing failed: $e');
    }
    return null;
  }

  /// Setup live stream for audio player
  Future<bool> setupLiveStream(AudioPlayer player, String youtubeUrl) async {
    try {
      print('LiveStreamService: Setting up live stream for: $youtubeUrl');

      final audioUrl = await getYouTubeAudioUrl(youtubeUrl);
      if (audioUrl == null) {
        throw Exception('Could not extract audio stream');
      }

      // Configure for live streaming
      await player.setAudioSource(
        AudioSource.uri(
          Uri.parse(audioUrl),
          headers: {
            'User-Agent': 'Mozilla/5.0',
            'Referer': 'https://www.youtube.com/',
          },
        ),
      );

      print('LiveStreamService: Live stream setup complete');
      return true;
    } catch (e) {
      print('LiveStreamService: Setup failed: $e');
      return false;
    }
  }

  /// Get predefined live channel info
  List<Map<String, String>> getLiveChannels() {
    return liveChannels.entries
        .map((entry) => {'name': entry.key, 'url': entry.value, 'type': 'live'})
        .toList();
  }

  /// Check if URL is a live stream
  Future<bool> isLiveStream(String youtubeUrl) async {
    try {
      final videoId = _extractVideoId(youtubeUrl);
      if (videoId == null) return false;

      final apiUrl =
          'https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v=$videoId&format=json';
      final response = await _dio.get(apiUrl);

      if (response.statusCode == 200) {
        final data = response.data;
        final title = data['title']?.toString().toLowerCase() ?? '';

        // Check for live indicators in title
        return title.contains('live') ||
            title.contains('24/7') ||
            title.contains('radio') ||
            title.contains('stream');
      }
    } catch (e) {
      print('LiveStreamService: Live check failed: $e');
    }
    return false;
  }

  /// Monitor live stream health
  Stream<StreamHealth> monitorStreamHealth(AudioPlayer player) async* {
    while (true) {
      await Future.delayed(const Duration(seconds: 10));

      final processingState = player.processingState;
      final playing = player.playing;

      if (processingState == ProcessingState.completed && playing) {
        yield StreamHealth.ended;
      } else if (processingState == ProcessingState.buffering) {
        yield StreamHealth.buffering;
      } else if (processingState == ProcessingState.ready && playing) {
        yield StreamHealth.healthy;
      } else {
        yield StreamHealth.unknown;
      }
    }
  }
}

enum StreamHealth { healthy, buffering, ended, unknown }

/// Core InnerTube API models based on InnerTune implementation
/// These models mirror YouTube's internal API structure

class YouTubeClient {
  final String clientName;
  final String clientVersion;
  final String? userAgent;
  final String? apiKey;
  final int? androidSdkVersion;
  final String? deviceModel;
  final String? osName;
  final String? osVersion;

  const YouTubeClient({
    required this.clientName,
    required this.clientVersion,
    this.userAgent,
    this.apiKey,
    this.androidSdkVersion,
    this.deviceModel,
    this.osName,
    this.osVersion,
  });

  Map<String, dynamic> toContext(String gl, String hl, String visitorData) => {
    'client': {
      'clientName': clientName,
      'clientVersion': clientVersion,
      if (androidSdkVersion != null) 'androidSdkVersion': androidSdkVersion,
      if (deviceModel != null) 'deviceModel': deviceModel,
      if (osName != null) 'osName': osName,
      if (osVersion != null) 'osVersion': osVersion,
      'gl': gl,
      'hl': hl,
      'visitorData': visitorData,
    },
    'user': {'lockedSafetyMode': false},
    'request': {'useSsl': true, 'internalExperimentFlags': []},
  };

  // Context getter for backward compatibility
  Map<String, dynamic> get context => toContext('US', 'en', '');

  // Predefined clients based on InnerTune
  static const androidMusic = YouTubeClient(
    clientName: 'ANDROID_MUSIC',
    clientVersion: '6.42.52',
    userAgent: 'com.google.android.apps.youtube.music/6.42.52 (Linux; U; Android 12; SM-G973F) gzip',
    apiKey: 'AIzaSyC9XL3ZjWddXya6X74dJoCTL-WEYFDNX30',
    androidSdkVersion: 31,
    osName: 'Android',
    osVersion: '12',
  );

  static const ios = YouTubeClient(
    clientName: 'IOS',
    clientVersion: '18.49.37',
    userAgent: 'com.google.ios.youtubemusic/6.42.52 (iPhone; U; CPU iPhone OS 15_6 like Mac OS X)',
    apiKey: 'AIzaSyBAETezhkwP0ZWA02RsqT1zu78Fpt0bC_s',
    deviceModel: 'iPhone14,2',
    osName: 'iOS',
    osVersion: '15.6',
  );

  static const webRemix = YouTubeClient(
    clientName: 'WEB_REMIX',
    clientVersion: '1.20220918.00.00',
    userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/105.0.0.0 Safari/537.36',
    apiKey: 'AIzaSyC9XL3ZjWddXya6X74dJoCTL-WEYFDNX30',
  );

  static const tvHtml5 = YouTubeClient(
    clientName: 'TVHTML5_SIMPLY_EMBEDDED_PLAYER',
    clientVersion: '2.0',
    userAgent: 'Mozilla/5.0 (SMART-TV; LINUX; Tizen 6.0) AppleWebKit/537.36 (KHTML, like Gecko) Version/6.0 TV Safari/537.36',
  );
}

class PlayerResponse {
  final PlayabilityStatus? playabilityStatus;
  final StreamingData? streamingData;
  final VideoDetails? videoDetails;
  final PlayerConfig? playerConfig;

  PlayerResponse({
    this.playabilityStatus,
    this.streamingData,
    this.videoDetails,
    this.playerConfig,
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
      playerConfig: json['playerConfig'] != null 
          ? PlayerConfig.fromJson(json['playerConfig']) 
          : null,
    );
  }
}

class PlayabilityStatus {
  final String status;
  final String? reason;
  final String? errorScreen;

  PlayabilityStatus({
    required this.status,
    this.reason,
    this.errorScreen,
  });

  factory PlayabilityStatus.fromJson(Map<String, dynamic> json) {
    return PlayabilityStatus(
      status: json['status'] ?? '',
      reason: json['reason'],
      errorScreen: json['errorScreen'],
    );
  }

  bool get isOk => status == 'OK';
}

class StreamingData {
  final List<Format> adaptiveFormats;
  final List<Format>? formats;
  final int expiresInSeconds;

  StreamingData({
    required this.adaptiveFormats,
    this.formats,
    required this.expiresInSeconds,
  });

  factory StreamingData.fromJson(Map<String, dynamic> json) {
    final adaptiveFormats = (json['adaptiveFormats'] as List?)
        ?.map((f) => Format.fromJson(f))
        .toList() ?? [];
    
    final formats = (json['formats'] as List?)
        ?.map((f) => Format.fromJson(f))
        .toList();
    
    return StreamingData(
      adaptiveFormats: adaptiveFormats,
      formats: formats,
      expiresInSeconds: int.tryParse(json['expiresInSeconds']?.toString() ?? '0') ?? 0,
    );
  }

  /// Get best audio format for playback
  Format? get bestAudioFormat {
    final audioFormats = adaptiveFormats.where((f) => f.isAudioOnly).toList();
    if (audioFormats.isEmpty) return null;
    
    // Sort by preference: opus first, then by bitrate
    audioFormats.sort((a, b) {
      // Prefer opus codec
      final aIsOpus = a.mimeType?.contains('opus') == true;
      final bIsOpus = b.mimeType?.contains('opus') == true;
      
      if (aIsOpus && !bIsOpus) return -1;
      if (!aIsOpus && bIsOpus) return 1;
      
      // Prefer mp4a for compatibility
      final aIsMp4a = a.mimeType?.contains('mp4a') == true;
      final bIsMp4a = b.mimeType?.contains('mp4a') == true;
      
      if (aIsMp4a && !bIsMp4a) return -1;
      if (!aIsMp4a && bIsMp4a) return 1;
      
      // Higher bitrate wins
      return (b.bitrate ?? 0).compareTo(a.bitrate ?? 0);
    });

    return audioFormats.first;
  }

  /// Get best video format for playback
  Format? get bestVideoFormat {
    final videoFormats = adaptiveFormats.where((f) => f.isVideoOnly).toList();
    if (videoFormats.isEmpty) return null;
    
    // Sort by quality (highest first)
    videoFormats.sort((a, b) => b.videoQualityLevel.compareTo(a.videoQualityLevel));
    
    return videoFormats.first;
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'adaptiveFormats': adaptiveFormats.map((f) => f.toJson()).toList(),
      'formats': formats?.map((f) => f.toJson()).toList(),
      'expiresInSeconds': expiresInSeconds,
    };
  }

  /// Create from Piped API response
  factory StreamingData.fromPiped(Map<String, dynamic> json) {
    final audioStreams = json['audioStreams'] as List? ?? [];
    final videoStreams = json['videoStreams'] as List? ?? [];
    
    final adaptiveFormats = <Format>[];
    
    // Convert audio streams
    for (final stream in audioStreams) {
      adaptiveFormats.add(Format(
        url: stream['url'],
        mimeType: stream['mimeType'],
        bitrate: stream['bitrate'],
        audioQuality: stream['quality'],
      ));
    }
    
    // Convert video streams
    for (final stream in videoStreams) {
      adaptiveFormats.add(Format(
        url: stream['url'],
        mimeType: stream['mimeType'],
        bitrate: stream['bitrate'],
        width: stream['width'],
        height: stream['height'],
        qualityLabel: stream['quality'],
      ));
    }
    
    return StreamingData(
      adaptiveFormats: adaptiveFormats,
      expiresInSeconds: 21600, // 6 hours default for Piped
    );
  }
}

class Format {
  final String? itag;
  final String? url;
  final String? mimeType;
  final int? bitrate;
  final int? width;
  final int? height;
  final String? qualityLabel;
  final String? fps;
  final String? audioSampleRate;
  final String? audioChannels;
  final String? approxDurationMs;
  final String? audioQuality;

  Format({
    this.itag,
    this.url,
    this.mimeType,
    this.bitrate,
    this.width,
    this.height,
    this.qualityLabel,
    this.fps,
    this.audioSampleRate,
    this.audioChannels,
    this.approxDurationMs,
    this.audioQuality,
  });

  factory Format.fromJson(Map<String, dynamic> json) {
    return Format(
      itag: json['itag']?.toString(),
      url: json['url'] as String?,
      mimeType: json['mimeType'] as String?,
      bitrate: json['bitrate'] as int?,
      width: json['width'] as int?,
      height: json['height'] as int?,
      qualityLabel: json['qualityLabel'] as String?,
      fps: json['fps']?.toString(),
      audioSampleRate: json['audioSampleRate']?.toString(),
      audioChannels: json['audioChannels']?.toString(),
      approxDurationMs: json['approxDurationMs']?.toString(),
      audioQuality: json['audioQuality'] as String?,
    );
  }

  /// Check if this format is audio-only
  bool get isAudioOnly => mimeType?.contains('audio/') == true && width == null && height == null;

  /// Check if this format is video-only  
  bool get isVideoOnly => mimeType?.contains('video/') == true && audioChannels == null;

  /// Get audio quality level for sorting
  int get audioQualityLevel {
    switch (audioQuality?.toLowerCase()) {
      case 'audio_quality_high':
        return 3;
      case 'audio_quality_medium':
        return 2;
      case 'audio_quality_low':
        return 1;
      default:
        return 0;
    }
  }

  /// Get video quality level for sorting
  int get videoQualityLevel {
    if (height == null) return 0;
    if (height! >= 2160) return 5; // 4K
    if (height! >= 1440) return 4; // 1440p
    if (height! >= 1080) return 3; // 1080p
    if (height! >= 720) return 2;  // 720p
    if (height! >= 480) return 1;  // 480p
    return 0;
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'itag': itag,
      'url': url,
      'mimeType': mimeType,
      'bitrate': bitrate,
      'width': width,
      'height': height,
      'qualityLabel': qualityLabel,
      'fps': fps,
      'audioSampleRate': audioSampleRate,
      'audioChannels': audioChannels,
      'approxDurationMs': approxDurationMs,
      'audioQuality': audioQuality,
    };
  }
}

class VideoDetails {
  final String videoId;
  final String title;
  final String author;
  final String channelId;
  final String lengthSeconds;
  final String? shortDescription;
  final List<Thumbnail>? thumbnail;

  VideoDetails({
    required this.videoId,
    required this.title,
    required this.author,
    required this.channelId,
    required this.lengthSeconds,
    this.shortDescription,
    this.thumbnail,
  });

  factory VideoDetails.fromJson(Map<String, dynamic> json) {
    return VideoDetails(
      videoId: json['videoId'] ?? '',
      title: json['title'] ?? '',
      author: json['author'] ?? '',
      channelId: json['channelId'] ?? '',
      lengthSeconds: json['lengthSeconds'] ?? '0',
      shortDescription: json['shortDescription'],
      thumbnail: (json['thumbnail']?['thumbnails'] as List?)
          ?.map((t) => Thumbnail.fromJson(t))
          .toList(),
    );
  }

  Duration get duration => Duration(seconds: int.tryParse(lengthSeconds) ?? 0);
}

class PlayerConfig {
  final AudioConfig? audioConfig;

  PlayerConfig({this.audioConfig});

  factory PlayerConfig.fromJson(Map<String, dynamic> json) {
    return PlayerConfig(
      audioConfig: json['audioConfig'] != null 
          ? AudioConfig.fromJson(json['audioConfig']) 
          : null,
    );
  }
}

class AudioConfig {
  final double? loudnessDb;
  final double? perceptualLoudnessDb;

  AudioConfig({this.loudnessDb, this.perceptualLoudnessDb});

  factory AudioConfig.fromJson(Map<String, dynamic> json) {
    return AudioConfig(
      loudnessDb: double.tryParse(json['loudnessDb']?.toString() ?? ''),
      perceptualLoudnessDb: double.tryParse(json['perceptualLoudnessDb']?.toString() ?? ''),
    );
  }
}

class Thumbnail {
  final String url;
  final int width;
  final int height;

  Thumbnail({
    required this.url,
    required this.width,
    required this.height,
  });

  factory Thumbnail.fromJson(Map<String, dynamic> json) {
    return Thumbnail(
      url: json['url'] ?? '',
      width: json['width'] ?? 0,
      height: json['height'] ?? 0,
    );
  }
}

// Piped API models for fallback
class PipedResponse {
  final List<AudioStream> audioStreams;
  final String title;
  final String uploader;
  final int duration;

  PipedResponse({
    required this.audioStreams,
    required this.title,
    required this.uploader,
    required this.duration,
  });

  factory PipedResponse.fromJson(Map<String, dynamic> json) {
    return PipedResponse(
      audioStreams: (json['audioStreams'] as List?)
          ?.map((s) => AudioStream.fromJson(s))
          .toList() ?? [],
      title: json['title'] ?? '',
      uploader: json['uploader'] ?? '',
      duration: json['duration'] ?? 0,
    );
  }
}

class AudioStream {
  final String url;
  final int bitrate;
  final String mimeType;
  final String quality;
  final String codec;

  AudioStream({
    required this.url,
    required this.bitrate,
    required this.mimeType,
    required this.quality,
    required this.codec,
  });

  factory AudioStream.fromJson(Map<String, dynamic> json) {
    return AudioStream(
      url: json['url'] ?? '',
      bitrate: json['bitrate'] ?? 0,
      mimeType: json['mimeType'] ?? '',
      quality: json['quality'] ?? '',
      codec: json['codec'] ?? '',
    );
  }
}

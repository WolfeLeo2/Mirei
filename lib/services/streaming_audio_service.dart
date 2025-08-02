import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import '../services/innertube_service.dart';
import '../models/youtube_music_models.dart';

/// Enhanced audio service with YouTube Music streaming support
class StreamingAudioService {
  static final StreamingAudioService _instance = StreamingAudioService._internal();
  factory StreamingAudioService() => _instance;
  StreamingAudioService._internal();

  final AudioPlayer _player = AudioPlayer();
  final InnerTubeService _innerTube = InnerTubeService();
  
  // Cache for streaming URLs (URLs expire after some time)
  final Map<String, _CachedStream> _streamCache = {};

  AudioPlayer get player => _player;

  /// Play a YouTube song with streaming URL resolution
  Future<bool> playYouTubeSong(YouTubeSong song) async {
    try {
      // Check if we have a cached valid stream URL
      final cached = _streamCache[song.videoId];
      if (cached != null && cached.isValid) {
        await _playFromUrl(cached.url, song);
        return true;
      }

      // Get streaming URL from InnerTube
      final playerResponse = await _innerTube.getPlayer(song.videoId);
      
      if (playerResponse?.streamingData?.adaptiveFormats.isEmpty ?? true) {
        print('No streaming data available for ${song.title}');
        return false;
      }

      // Select best audio format (prefer opus/webm, then highest bitrate)
      final formats = playerResponse!.streamingData!.adaptiveFormats;
      final bestFormat = _selectBestAudioFormat(formats);

      if (bestFormat?.url == null) {
        print('No playable audio format found for ${song.title}');
        return false;
      }

      final url = bestFormat!.url!; // Safe to use ! since we checked above

      // Cache the stream URL  
      _streamCache[song.videoId] = _CachedStream(
        url: url,
        expiresAt: DateTime.now().add(
          Duration(seconds: playerResponse.streamingData!.expiresInSeconds - 60), // 1 min buffer
        ),
      );

      await _playFromUrl(url, song);
      return true;
    } catch (e) {
      print('Error playing YouTube song: $e');
      return false;
    }
  }

  Format? _selectBestAudioFormat(List<Format> formats) {
    // Sort by preference: opus/webm first, then by bitrate
    formats.sort((a, b) {
      // Prefer opus codec
      final aIsOpus = a.mimeType.contains('opus');
      final bIsOpus = b.mimeType.contains('opus');
      
      if (aIsOpus && !bIsOpus) return -1;
      if (!aIsOpus && bIsOpus) return 1;
      
      // Then prefer webm container
      final aIsWebm = a.mimeType.contains('webm');
      final bIsWebm = b.mimeType.contains('webm');
      
      if (aIsWebm && !bIsWebm) return -1;
      if (!aIsWebm && bIsWebm) return 1;
      
      // Finally, prefer higher bitrate
      return b.bitrate.compareTo(a.bitrate);
    });

    return formats.firstOrNull;
  }

  Future<void> _playFromUrl(String url, YouTubeSong song) async {
    final audioSource = AudioSource.uri(
      Uri.parse(url),
      tag: MediaItem(
        id: song.videoId,
        album: song.album?.title ?? '',
        title: song.title,
        artist: song.artists.map((a) => a.name).join(', '),
        duration: song.duration,
        artUri: song.thumbnailUrl.isNotEmpty ? Uri.parse(song.thumbnailUrl) : null,
      ),
    );

    await _player.setAudioSource(audioSource);
    await _player.play();
  }

  /// Queue multiple YouTube songs
  Future<void> setYouTubePlaylist(List<YouTubeSong> songs) async {
    final audioSources = <AudioSource>[];
    
    for (final song in songs) {
      try {
        // For playlists, we might want to resolve URLs lazily
        // For now, we'll create a simple URI source and resolve on demand
        final audioSource = AudioSource.uri(
          Uri.parse('youtube://video/${song.videoId}'), // Custom scheme
          tag: MediaItem(
            id: song.videoId,
            album: song.album?.title ?? '',
            title: song.title,
            artist: song.artists.map((a) => a.name).join(', '),
            duration: song.duration,
            artUri: song.thumbnailUrl.isNotEmpty ? Uri.parse(song.thumbnailUrl) : null,
          ),
        );
        audioSources.add(audioSource);
      } catch (e) {
        print('Error adding ${song.title} to queue: $e');
      }
    }

    if (audioSources.isNotEmpty) {
      await _player.setAudioSource(ConcatenatingAudioSource(children: audioSources));
    }
  }

  /// Clear expired cache entries
  void _cleanupCache() {
    final now = DateTime.now();
    _streamCache.removeWhere((key, cached) => cached.expiresAt.isBefore(now));
  }

  /// Preload next song in queue for seamless playback
  Future<void> preloadNext() async {
    if (_player.hasNext) {
      // Implementation would preload the next song's streaming URL
      // This is complex and would require custom audio source management
    }
  }

  void dispose() {
    _streamCache.clear();
    _innerTube.dispose();
    _player.dispose();
  }
}

class _CachedStream {
  final String url;
  final DateTime expiresAt;

  _CachedStream({required this.url, required this.expiresAt});

  bool get isValid => DateTime.now().isBefore(expiresAt);
}

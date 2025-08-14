import 'package:just_audio/just_audio.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

/// A result object for YouTube audio requests.
class YouTubeAudioResult {
  final Duration? duration;
  final bool isLive;

  YouTubeAudioResult({this.duration, this.isLive = false});
}

class YouTubeLiveAudioService {
  final YoutubeExplode _ytExplode = YoutubeExplode();

  /// Plays a YouTube video's audio and returns its properties.
  ///
  /// This service now correctly identifies live streams and returns a [YouTubeAudioResult]
  /// indicating whether the stream is live and what its duration is (if not live).
  Future<YouTubeAudioResult> playLiveAudio(
    String videoUrl,
    AudioPlayer player,
  ) async {
    try {
      final videoId =
          VideoId.parseVideoId(videoUrl) ?? videoUrl.split('/').last;

      // Fetch video details first to check if it's live
      final video = await _ytExplode.videos.get(videoId);
      final isLive = video.isLive;

      // Get audio stream manifest
      final manifest =
          await _ytExplode.videos.streamsClient.getManifest(videoId);
      final audioStreams = manifest.audioOnly;

      if (audioStreams.isEmpty) {
        throw Exception('No audio-only stream found for this video.');
      }

      // Select a medium bitrate stream for balanced quality and performance
      // Select the highest quality audio-only stream
      final sortedStreams = audioStreams.toList()
        ..sort((a, b) => b.bitrate.compareTo(a.bitrate));
      final maxBitrateStream = sortedStreams.first;
      final streamUrl = maxBitrateStream.url.toString();

      // Set the audio source
      await player.setAudioSource(AudioSource.uri(Uri.parse(streamUrl)));

      // If it's a live stream, duration is irrelevant. Otherwise, return video duration.
      if (isLive) {
        print('🎥 Detected Live Stream: ${video.title}');
        return YouTubeAudioResult(isLive: true, duration: null);
      } else {
        print('🎬 Detected VOD: ${video.title} (${video.duration})');
        return YouTubeAudioResult(isLive: false, duration: video.duration);
      }
    } catch (e) {
      print('❌ Error playing YouTube audio: $e');
      rethrow;
    }
  }
}

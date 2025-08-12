import 'package:just_audio/just_audio.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class YouTubeLiveAudioService {
  final YoutubeExplode _ytExplode = YoutubeExplode();

  Future<Duration?> playLiveAudio(String videoUrl, AudioPlayer player) async {
    try {
      final videoId =
          VideoId.parseVideoId(videoUrl) ?? videoUrl.split('/').last;
      final manifest = await _ytExplode.videos.streamsClient.getManifest(
        videoId,
      );
      final audioStreams = manifest.audioOnly;
      if (audioStreams.isEmpty) throw Exception('No audio stream found');
      // Select medium bitrate (closest to median)
      final sortedStreams = audioStreams.toList()
        ..sort((a, b) => a.bitrate.compareTo(b.bitrate));
      final medianIndex = sortedStreams.length ~/ 2;
      final mediumStream = sortedStreams[medianIndex];
      final audioUrl = mediumStream.url.toString();
      await player.setAudioSource(AudioSource.uri(Uri.parse(audioUrl)));
      // Fetch video details for duration
      final video = await _ytExplode.videos.get(videoId);
      final duration = video.duration;
      await player.play();
      return duration;
    } catch (e) {
      print('Error playing YouTube live audio: $e');
      rethrow;
    }
  }
}

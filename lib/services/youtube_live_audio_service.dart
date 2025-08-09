import 'package:just_audio/just_audio.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class YouTubeLiveAudioService {
  final YoutubeExplode _ytExplode = YoutubeExplode();

  Future<void> playLiveAudio(String videoUrl, AudioPlayer player) async {
    try {
      final videoId = VideoId.parseVideoId(videoUrl) ?? videoUrl.split('/').last;
      final manifest = await _ytExplode.videos.streamsClient.getManifest(videoId);
      final audioStreams = manifest.audioOnly;
      if (audioStreams.isEmpty) throw Exception('No audio stream found');
      final audioStreamInfo = audioStreams.withHighestBitrate();
      final audioUrl = audioStreamInfo.url.toString();
      await player.setAudioSource(AudioSource.uri(Uri.parse(audioUrl)));
      await player.play();
    } catch (e) {
      print('Error playing YouTube live audio: $e');
      rethrow;
    }
  }
}

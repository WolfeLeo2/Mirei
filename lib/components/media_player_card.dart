import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_media_metadata/flutter_media_metadata.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class MediaPlayerCard extends StatefulWidget {
  final String assetPath;
  const MediaPlayerCard({super.key, required this.assetPath});

  @override
  State<MediaPlayerCard> createState() => _MediaPlayerCardState();
}

class _MediaPlayerCardState extends State<MediaPlayerCard> {
  late AudioPlayer _audioPlayer;
  Duration? _duration;
  Duration _position = Duration.zero;
  String _artist = 'Unknown Artist';
  String _title = 'Unknown Title';
  String _mp3Path = '';
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _initAudio();
  }

  Future<void> _initAudio() async {
    try {
      final bytes = await rootBundle.load(widget.assetPath);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/media_temp.mp3');
      await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
      _mp3Path = file.path;

      final metadata = await MetadataRetriever.fromFile(file);
      setState(() {
        _artist = (metadata.trackArtistNames != null && metadata.trackArtistNames!.isNotEmpty)
            ? metadata.trackArtistNames!.join(', ')
            : (metadata.authorName ?? 'Unknown Artist');
        _title = metadata.trackName ?? 'Unknown Title';
        _duration = metadata.trackDuration != null
            ? Duration(milliseconds: metadata.trackDuration!)
            : null;
      });

      await _audioPlayer.setFilePath(_mp3Path);
      _audioPlayer.positionStream.listen((pos) {
        setState(() {
          _position = pos;
        });
      });
      _audioPlayer.playerStateStream.listen((state) {
        setState(() {
          _isPlaying = state.playing;
        });
      });
    } catch (e) {
      // Handle error
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  String formatTime(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final min = twoDigits(d.inMinutes.remainder(60));
    final sec = twoDigits(d.inSeconds.remainder(60));
    return '$min:$sec';
  }

  @override
  Widget build(BuildContext context) {
    final duration = _duration ?? Duration.zero;
    final position = _position;
    final artist = _artist;
    final title = _title;
    final progress = duration.inMilliseconds > 0
        ? position.inMilliseconds / duration.inMilliseconds
        : 0.0;

    if (!_isPlaying) {
      // Idle state
      return Container(
        width: 265,
        height: 265,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFfdf6f0), Color(0xFFf9e3e3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.music_note,
              color: const Color(0xFF1a237e).withOpacity(0.15),
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF1a237e),
                fontWeight: FontWeight.w500,
                fontSize: 18,
                letterSpacing: -1.0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              artist,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFbcaaa4),
                fontWeight: FontWeight.w400,
                fontSize: 15,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: ClipOval(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: () async {
                        await _audioPlayer.play();
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.55),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.7),
                            width: 2,
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.play_arrow,
                            color: Color(0xFFe57373),
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // Playing state
      return Container(
        width: 265,
        height: 265,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFfdf6f0), Color(0xFFf9e3e3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.09),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 4),
              Text(
                artist,
                style: TextStyle(
                  color: const Color(0xFFe57373).withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF4e342e),
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  letterSpacing: -1.0,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "${formatTime(position)} / ${formatTime(duration)}",
                style: TextStyle(
                  color: const Color(0xFFbcaaa4).withOpacity(0.85),
                  fontWeight: FontWeight.w500,
                  fontSize: 17,
                  letterSpacing: -0.5,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  backgroundColor: const Color(0xFFf9e3e3),
                  color: const Color(0xFFe57373),
                  minHeight: 4,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Material(
                    color: Colors.transparent,
                    shape: const CircleBorder(),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () async {
                        final newPosition =
                            _position - const Duration(seconds: 15);
                        await _audioPlayer.seek(
                          newPosition < Duration.zero
                              ? Duration.zero
                              : newPosition,
                        );
                      },
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: Icon(
                          Icons.replay_10,
                          color: const Color.fromARGB(169, 177, 151, 130)
                              .withOpacity(0.5),
                          size: 44,
                        ),
                      ),
                    ),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          const Color.fromARGB(169, 177, 151, 130),
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(0),
                      minimumSize: const Size(64, 64),
                      maximumSize: const Size(64, 64),
                      elevation: 0,
                    ),
                    onPressed: () async {
                      await _audioPlayer.pause();
                    },
                    child: const Icon(
                      Icons.pause,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                  Material(
                    color: const Color.fromARGB(169, 177, 151, 130),
                    shape: const CircleBorder(),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () {},
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: Icon(
                          Icons.arrow_forward,
                          color: const Color.fromARGB(255, 255, 255, 255)
                              .withOpacity(0.7),
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      );
    }
  }
}

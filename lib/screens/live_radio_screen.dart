import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import '../services/live_stream_service.dart';

class LiveRadioScreen extends StatefulWidget {
  const LiveRadioScreen({super.key});

  @override
  _LiveRadioScreenState createState() => _LiveRadioScreenState();
}

class _LiveRadioScreenState extends State<LiveRadioScreen>
    with TickerProviderStateMixin {
  late AudioPlayer _audioPlayer;
  late LiveStreamService _liveStreamService;
  late AnimationController _rotationController;

  bool isPlaying = false;
  bool isLoading = false;
  bool isBuffering = false;
  double volume = 0.7;
  String? currentStation;
  String? currentStationUrl;
  StreamHealth streamHealth = StreamHealth.unknown;

  // UI Colors
  static const Color primaryColor = Color(0xFF115e5a);
  static const Color backgroundColor = Color(0xFFF5F7FA);
  static const Color cardColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    _audioPlayer = AudioPlayer();
    _liveStreamService = LiveStreamService();

    _rotationController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    );

    // Listen to player state changes
    _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          isPlaying = state.playing;
          isBuffering = state.processingState == ProcessingState.buffering;
        });

        if (isPlaying) {
          _rotationController.repeat();
        } else {
          _rotationController.stop();
        }
      }
    });

    // Monitor stream health
    _liveStreamService.monitorStreamHealth(_audioPlayer).listen((health) {
      if (mounted) {
        setState(() {
          streamHealth = health;
        });

        // Auto-reconnect if stream ends
        if (health == StreamHealth.ended && currentStationUrl != null) {
          _reconnectStream();
        }
      }
    });
  }

  Future<void> _playLiveStream(String stationName, String youtubeUrl) async {
    try {
      setState(() {
        isLoading = true;
        currentStation = stationName;
        currentStationUrl = youtubeUrl;
      });

      // Stop current stream
      await _audioPlayer.stop();

      // Setup new live stream
      final success = await _liveStreamService.setupLiveStream(
        _audioPlayer,
        youtubeUrl,
      );

      if (success) {
        await _audioPlayer.setVolume(volume);
        await _audioPlayer.play();

        HapticFeedback.mediumImpact();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Now playing: $stationName'),
            backgroundColor: primaryColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        throw Exception('Failed to setup live stream');
      }
    } catch (e) {
      print('Error playing live stream: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to play $stationName'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _reconnectStream() async {
    if (currentStationUrl != null && currentStation != null) {
      print('LiveRadio: Reconnecting to stream...');
      await Future.delayed(const Duration(seconds: 2));
      await _playLiveStream(currentStation!, currentStationUrl!);
    }
  }

  void _togglePlayPause() async {
    HapticFeedback.mediumImpact();

    if (isPlaying) {
      await _audioPlayer.pause();
    } else {
      if (currentStationUrl != null) {
        await _audioPlayer.play();
      }
    }
  }

  void _adjustVolume(double newVolume) {
    setState(() {
      volume = newVolume;
    });
    _audioPlayer.setVolume(volume);
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: primaryColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Live Radio',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: primaryColor,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Current Station Display
          if (currentStation != null) _buildCurrentStationCard(),

          // Live Stations List
          Expanded(child: _buildStationsList()),
        ],
      ),
    );
  }

  Widget _buildCurrentStationCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Station Artwork
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(60),
            ),
            child: RotationTransition(
              turns: _rotationController,
              child: Icon(Icons.radio, size: 60, color: primaryColor),
            ),
          ),

          const SizedBox(height: 16),

          // Station Name
          Text(
            currentStation!,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: primaryColor,
            ),
            textAlign: TextAlign.center,
          ),

          // Stream Status
          Text(
            _getStatusText(),
            style: GoogleFonts.inter(fontSize: 12, color: _getStatusColor()),
          ),

          const SizedBox(height: 20),

          // Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Play/Pause Button
              GestureDetector(
                onTap: isLoading ? null : _togglePlayPause,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        )
                      : Icon(
                          isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 30,
                        ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Volume Control
          Row(
            children: [
              Icon(Icons.volume_down, color: primaryColor, size: 20),
              Expanded(
                child: Slider(
                  value: volume,
                  onChanged: _adjustVolume,
                  activeColor: primaryColor,
                  inactiveColor: primaryColor.withOpacity(0.3),
                ),
              ),
              Icon(Icons.volume_up, color: primaryColor, size: 20),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStationsList() {
    final stations = _liveStreamService.getLiveChannels();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: stations.length,
      itemBuilder: (context, index) {
        final station = stations[index];
        final isCurrentStation = currentStation == station['name'];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isCurrentStation ? primaryColor.withOpacity(0.1) : cardColor,
            borderRadius: BorderRadius.circular(12),
            border: isCurrentStation
                ? Border.all(color: primaryColor, width: 2)
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Icon(Icons.radio, color: primaryColor, size: 24),
            ),
            title: Text(
              station['name']!,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isCurrentStation ? primaryColor : Colors.black87,
              ),
            ),
            subtitle: Text(
              'Live Stream • 24/7',
              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
            ),
            trailing: isCurrentStation && isPlaying
                ? Icon(Icons.graphic_eq, color: primaryColor)
                : Icon(Icons.play_circle_outline, color: primaryColor),
            onTap: () => _playLiveStream(station['name']!, station['url']!),
          ),
        );
      },
    );
  }

  String _getStatusText() {
    switch (streamHealth) {
      case StreamHealth.healthy:
        return isPlaying ? 'LIVE • Playing' : 'LIVE • Paused';
      case StreamHealth.buffering:
        return 'LIVE • Buffering...';
      case StreamHealth.ended:
        return 'LIVE • Reconnecting...';
      case StreamHealth.unknown:
        return 'LIVE • Ready';
    }
  }

  Color _getStatusColor() {
    switch (streamHealth) {
      case StreamHealth.healthy:
        return Colors.green;
      case StreamHealth.buffering:
        return Colors.orange;
      case StreamHealth.ended:
        return Colors.red;
      case StreamHealth.unknown:
        return Colors.grey;
    }
  }
}

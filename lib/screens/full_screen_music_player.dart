import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/music_player_bloc.dart';
import '../models/youtube_music_models.dart';
import '../services/music_player_service.dart';
import '../utils/duration_extensions.dart';

class FullScreenMusicPlayer extends StatefulWidget {
  const FullScreenMusicPlayer({super.key});

  @override
  State<FullScreenMusicPlayer> createState() => _FullScreenMusicPlayerState();
}

class _FullScreenMusicPlayerState extends State<FullScreenMusicPlayer>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  
  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1a1a2e),
              Color(0xFF16213e),
              Color(0xFF0f3460),
            ],
          ),
        ),
        child: BlocConsumer<MusicPlayerBloc, MusicPlayerState>(
          listener: (context, state) {
            if (state is MusicPlayerReady) {
              if (state.isPlaying) {
                _rotationController.repeat();
                _pulseController.repeat(reverse: true);
              } else {
                _rotationController.stop();
                _pulseController.stop();
              }
            }
          },
          builder: (context, state) {
            if (state is MusicPlayerReady && state.currentSong != null) {
              return _buildPlayerUI(context, state);
            } else if (state is MusicPlayerLoading) {
              return _buildLoadingUI();
            } else if (state is MusicPlayerError) {
              return _buildErrorUI(state.message);
            } else {
              return _buildEmptyUI();
            }
          },
        ),
      ),
    );
  }

  Widget _buildPlayerUI(BuildContext context, MusicPlayerReady state) {
    final song = state.currentSong!;
    
    return SafeArea(
      child: Column(
        children: [
          // Header with back button and menu
          _buildHeader(context),
          
          // Album art and song info
          Expanded(
            flex: 3,
            child: _buildAlbumArtSection(song, state.isPlaying),
          ),
          
          // Song title and artist
          _buildSongInfo(song),
          
          // Progress bar
          _buildProgressSection(state),
          
          // Player controls
          _buildPlayerControls(state),
          
          // Bottom controls (queue, lyrics, etc.)
          _buildBottomControls(state),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 28),
          ),
          const Text(
            'Now Playing',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          IconButton(
            onPressed: () => _showPlayerMenu(context),
            icon: const Icon(Icons.more_vert, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumArtSection(YouTubeSong song, bool isPlaying) {
    return Center(
      child: AnimatedBuilder(
        animation: _rotationController,
        builder: (context, child) {
          return Transform.rotate(
            angle: _rotationController.value * 2 * 3.14159,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 30,
                        spreadRadius: isPlaying ? 10 + (_pulseController.value * 5) : 10,
                      ),
                      BoxShadow(
                        color: Theme.of(context).primaryColor.withOpacity(isPlaying ? 0.3 : 0.1),
                        blurRadius: 50,
                        spreadRadius: isPlaying ? 15 + (_pulseController.value * 10) : 5,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: song.thumbnailUrl.isNotEmpty
                        ? Image.network(
                            song.thumbnailUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => _buildDefaultArt(),
                          )
                        : _buildDefaultArt(),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildDefaultArt() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.purple.withOpacity(0.7),
            Colors.blue.withOpacity(0.7),
          ],
        ),
      ),
      child: const Icon(
        Icons.music_note,
        size: 100,
        color: Colors.white,
      ),
    );
  }

  Widget _buildSongInfo(YouTubeSong song) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Column(
        children: [
          Text(
            song.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            song.artist,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (song.album?.title != null) ...[
            const SizedBox(height: 4),
            Text(
              song.album!.title,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressSection(MusicPlayerReady state) {
    final position = state.position;
    final duration = state.duration ?? Duration.zero;
    final progress = duration.inMilliseconds > 0 
        ? position.inMilliseconds / duration.inMilliseconds 
        : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              activeTrackColor: Colors.white,
              inactiveTrackColor: Colors.white.withOpacity(0.3),
              thumbColor: Colors.white,
              overlayColor: Colors.white.withOpacity(0.1),
            ),
            child: Slider(
              value: progress.clamp(0.0, 1.0),
              onChanged: (value) {
                final newPosition = Duration(
                  milliseconds: (value * duration.inMilliseconds).round(),
                );
                context.read<MusicPlayerBloc>().add(SeekToPosition(newPosition));
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  position.formatted,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
                Text(
                  duration.formatted,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerControls(MusicPlayerReady state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            onPressed: () => context.read<MusicPlayerBloc>().add(const ToggleShuffle()),
            icon: Icon(
              Icons.shuffle,
              color: state.shuffleEnabled ? Theme.of(context).primaryColor : Colors.white.withOpacity(0.7),
              size: 24,
            ),
          ),
          IconButton(
            onPressed: () => context.read<MusicPlayerBloc>().add(const SkipToPrevious()),
            icon: const Icon(Icons.skip_previous, color: Colors.white, size: 36),
          ),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: IconButton(
              onPressed: () => context.read<MusicPlayerBloc>().add(const TogglePlayPause()),
              icon: Icon(
                state.isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.black,
                size: 32,
              ),
            ),
          ),
          IconButton(
            onPressed: () => context.read<MusicPlayerBloc>().add(const SkipToNext()),
            icon: const Icon(Icons.skip_next, color: Colors.white, size: 36),
          ),
          IconButton(
            onPressed: () => context.read<MusicPlayerBloc>().add(const ToggleRepeat()),
            icon: Icon(
              state.repeatMode == RepeatMode.one ? Icons.repeat_one : Icons.repeat,
              color: state.repeatMode != RepeatMode.off ? Theme.of(context).primaryColor : Colors.white.withOpacity(0.7),
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls(MusicPlayerReady state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            onPressed: () => _showQueue(context, state.playlist, state.currentIndex),
            icon: const Icon(Icons.queue_music, color: Colors.white, size: 24),
          ),
          IconButton(
            onPressed: () => _showVolumeControl(context, state.volume),
            icon: const Icon(Icons.volume_up, color: Colors.white, size: 24),
          ),
          IconButton(
            onPressed: () {
              // TODO: Show lyrics
            },
            icon: const Icon(Icons.lyrics, color: Colors.white, size: 24),
          ),
          IconButton(
            onPressed: () {
              // TODO: Add to favorites
            },
            icon: const Icon(Icons.favorite_border, color: Colors.white, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingUI() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 16),
          Text(
            'Loading music player...',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorUI(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 64),
          const SizedBox(height: 16),
          Text(
            'Error',
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.music_off, color: Colors.white, size: 64),
          const SizedBox(height: 16),
          const Text(
            'No Music Playing',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Select a song to start playing',
            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
          ),
        ],
      ),
    );
  }

  void _showPlayerMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1a1a2e),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share, color: Colors.white),
              title: const Text('Share', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                // TODO: Share functionality
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.white),
              title: const Text('Song Info', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                // TODO: Show song info
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showQueue(BuildContext context, List<YouTubeSong> playlist, int currentIndex) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Color(0xFF1a1a2e),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Queue',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: playlist.length,
                itemBuilder: (context, index) {
                  final song = playlist[index];
                  final isCurrentSong = index == currentIndex;
                  
                  return ListTile(
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey.withOpacity(0.3),
                      ),
                      child: song.thumbnailUrl.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                song.thumbnailUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => 
                                    const Icon(Icons.music_note, color: Colors.white),
                              ),
                            )
                          : const Icon(Icons.music_note, color: Colors.white),
                    ),
                    title: Text(
                      song.title,
                      style: TextStyle(
                        color: isCurrentSong ? Theme.of(context).primaryColor : Colors.white,
                        fontWeight: isCurrentSong ? FontWeight.bold : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      song.artist,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      onPressed: () {
                        context.read<MusicPlayerBloc>().add(RemoveFromQueue(index));
                      },
                      icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                    ),
                    onTap: () {
                      // TODO: Skip to this song
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showVolumeControl(BuildContext context, double currentVolume) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        title: const Text('Volume', style: TextStyle(color: Colors.white)),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.volume_down, color: Colors.white),
                    Expanded(
                      child: Slider(
                        value: currentVolume,
                        min: 0.0,
                        max: 1.0,
                        divisions: 100,
                        onChanged: (value) {
                          setState(() {
                            // Update local state for immediate feedback
                          });
                          context.read<MusicPlayerBloc>().add(SetVolume(value));
                        },
                      ),
                    ),
                    const Icon(Icons.volume_up, color: Colors.white),
                  ],
                ),
                Text(
                  '${(currentVolume * 100).round()}%',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

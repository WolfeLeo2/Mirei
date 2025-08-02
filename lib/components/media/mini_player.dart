import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/music_player_bloc.dart';
import '../../screens/full_screen_music_player.dart';
import '../../services/music_player_service.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MusicPlayerBloc, MusicPlayerState>(
      builder: (context, state) {
        if (state is MusicPlayerReady && state.currentSong != null) {
          return _buildMiniPlayer(context, state);
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildMiniPlayer(BuildContext context, MusicPlayerReady state) {
    final song = state.currentSong!;
    
    return GestureDetector(
      onTap: () => _openFullScreenPlayer(context),
      child: Container(
        height: 70,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.grey[200]!, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Album art
            _buildAlbumArt(song),
            
            // Song info
            Expanded(
              child: _buildSongInfo(song, state),
            ),
            
            // Play/pause button
            _buildPlayPauseButton(context, state),
            
            // Next button
            _buildNextButton(context),
            
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildAlbumArt(song) {
    return Container(
      width: 56,
      height: 56,
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.grey[100],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: song.thumbnailUrl.isNotEmpty
            ? Image.network(
                song.thumbnailUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => 
                    Icon(Icons.music_note, color: Colors.grey[400], size: 24),
              )
            : Icon(Icons.music_note, color: Colors.grey[400], size: 24),
      ),
    );
  }

  Widget _buildSongInfo(song, MusicPlayerReady state) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            song.title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Expanded(
                child: Text(
                  song.artist,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Loading indicator
              if (state.playerState == PlayerState.loading)
                Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.only(right: 8),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayPauseButton(BuildContext context, MusicPlayerReady state) {
    return Container(
      width: 40,
      height: 40,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey[100],
      ),
      child: IconButton(
        onPressed: () => context.read<MusicPlayerBloc>().add(const TogglePlayPause()),
        icon: Icon(
          state.isPlaying ? Icons.pause : Icons.play_arrow,
          size: 20,
          color: Colors.black87,
        ),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildNextButton(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey[100],
      ),
      child: IconButton(
        onPressed: () => context.read<MusicPlayerBloc>().add(const SkipToNext()),
        icon: const Icon(
          Icons.skip_next,
          size: 20,
          color: Colors.black87,
        ),
        padding: EdgeInsets.zero,
      ),
    );
  }

  void _openFullScreenPlayer(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const FullScreenMusicPlayer(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }
}

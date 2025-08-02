import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/youtube_music_bloc.dart';
import '../../models/youtube_music_models.dart';
import '../../utils/duration_extensions.dart';
import '../../services/youtube_music_auth_helper.dart';

class QuickAccessSection extends StatefulWidget {
  const QuickAccessSection({super.key});

  @override
  State<QuickAccessSection> createState() => _QuickAccessSectionState();
}

class _QuickAccessSectionState extends State<QuickAccessSection> {
  @override
  void initState() {
    super.initState();
    // Load YouTube Music quick picks
    // Note: Using public search since authentication is not available yet
    context.read<YouTubeMusicBloc>().add(const SearchYouTubeMusicSongs('popular music', limit: 10));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Quick Access',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 16),
        BlocBuilder<YouTubeMusicBloc, YouTubeMusicState>(
          builder: (context, state) {
            if (state is YouTubeMusicLoading) {
              return _buildLoadingState();
            } else if (state is YouTubeMusicSongsLoaded) {
              return _buildQuickPicksList(state.songs);
            } else if (state is YouTubeMusicError) {
              return _buildErrorState(state.message);
            } else {
              return _buildFallbackContent();
            }
          },
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: List.generate(4, (index) => _buildShimmerSongItem()),
    );
  }

  Widget _buildQuickPicksList(List<YouTubeSong> songs) {
    if (songs.isEmpty) {
      return _buildFallbackContent();
    }

    return Column(
      children: songs
          .take(4)
          .map((song) => _buildYouTubeSongItem(song))
          .toList(),
    );
  }

  Widget _buildErrorState(String error) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: Colors.grey[400], size: 48),
          const SizedBox(height: 12),
          Text(
            'Failed to load YouTube Music content',
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              context.read<YouTubeMusicBloc>().add(const SearchYouTubeMusicSongs('popular music', limit: 10));
            },
            child: const Text('Retry', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackContent() {
    // Fallback to original content when YouTube Music is unavailable
    return Column(
      children: [
        _buildSongItem(
          albumArt: 'assets/images/image1.jpg',
          title: 'Sacrifices (feat. Smino & Saba)',
          artist: 'Dreamville, EARTHGANG & J...',
          isExplicit: true,
        ),
        _buildSongItem(
          albumArt: 'assets/images/image2.jpg',
          title: 'FIJI (feat. Cruza)',
          artist: 'Eem Triplin • 1.5M plays',
          isExplicit: true,
        ),
        _buildSongItem(
          albumArt: 'assets/images/gradient.png',
          title: 'Survivor\'s Guilt',
          artist: 'Dave • 7.8M plays',
          isExplicit: true,
        ),
        _buildSongItem(
          albumArt: 'assets/images/gradient-2.png',
          title: 'Do for Love',
          artist: '2Pac • 290M plays',
          isExplicit: true,
        ),
      ],
    );
  }

  Widget _buildYouTubeSongItem(YouTubeSong song) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      child: InkWell(
        onTap: () {
          // Handle song play - get streaming URL
        },
        child: Row(
          children: [
            // Album Art
            Container(
              width: 60,
              height: 60,
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[800],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  song.thumbnailUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(Icons.music_note, color: Colors.grey[400]);
                  },
                ),
              ),
            ),
            // Song Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      // YouTube Music indicator
                      Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: const Text(
                          'YT',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          song.artists.isNotEmpty
                              ? song.artists.map((a) => a.name).join(', ')
                              : 'Unknown Artist',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[400],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (song.duration != null)
                        Text(
                          song.duration!.formatted,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            // More options
            IconButton(
              icon: Icon(Icons.more_vert, color: Colors.grey[400], size: 20),
              onPressed: () {
                _showSongOptions(context, song);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerSongItem() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[800],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 14,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 12,
                  width: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.more_vert, color: Colors.grey[400], size: 20),
            onPressed: null,
          ),
        ],
      ),
    );
  }

  void _showSongOptions(BuildContext context, YouTubeSong song) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.play_arrow, color: Colors.white),
            title: const Text(
              'Play Now',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.queue_music, color: Colors.white),
            title: const Text(
              'Add to Queue',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              Navigator.pop(context);
              // Handle add to queue
            },
          ),
          ListTile(
            leading: const Icon(Icons.favorite_border, color: Colors.white),
            title: const Text(
              'Add to Favorites',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              Navigator.pop(context);
              // Handle add to favorites
            },
          ),
          ListTile(
            leading: const Icon(Icons.album, color: Colors.white),
            title: const Text(
              'Go to Album',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSongItem({
    required String albumArt,
    required String title,
    required String artist,
    required bool isExplicit,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      child: Row(
        children: [
          // Album Art
          Container(
            width: 60,
            height: 60,
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: AssetImage(albumArt),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Song Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (isExplicit)
                      Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[600],
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: const Text(
                          'E',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    Expanded(
                      child: Text(
                        artist,
                        style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // More options
          IconButton(
            icon: Icon(Icons.more_vert, color: Colors.grey[400], size: 20),
            onPressed: () {
              // Handle more options
            },
          ),
        ],
      ),
    );
  }
}

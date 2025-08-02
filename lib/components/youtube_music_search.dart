import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/youtube_music_bloc.dart';
import '../bloc/music_player_bloc.dart';
import '../models/youtube_music_models.dart';
import '../utils/duration_extensions.dart';

class YouTubeMusicSearch extends StatefulWidget {
  const YouTubeMusicSearch({super.key});

  @override
  State<YouTubeMusicSearch> createState() => _YouTubeMusicSearchState();
}

class _YouTubeMusicSearchState extends State<YouTubeMusicSearch> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search Bar
        Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(25),
          ),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search YouTube Music...',
              hintStyle: TextStyle(color: Colors.grey[400]),
              prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: Colors.grey[400]),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 15,
              ),
            ),
            onChanged: (value) {
              setState(() {});
            },
            onSubmitted: (value) {
              if (value.isNotEmpty) {
                context.read<YouTubeMusicBloc>().add(SearchYouTubeMusic(value));
              }
            },
          ),
        ),

        // Search Results or Suggestions
        Expanded(
          child: BlocBuilder<YouTubeMusicBloc, YouTubeMusicState>(
            builder: (context, state) {
              if (state is YouTubeMusicLoading) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              } else if (state is YouTubeMusicSearchResultsLoaded) {
                return _buildSearchResults(state);
              } else if (state is YouTubeMusicError) {
                return _buildErrorWidget(state.message);
              } else {
                return _buildDefaultContent();
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResults(YouTubeMusicSearchResultsLoaded results) {
    return _buildSongsList(results.searchResult.songs);
  }

  Widget _buildSongsList(List<YouTubeSong> songs) {
    if (songs.isEmpty) {
      return const Center(
        child: Text('No songs found', style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      itemCount: songs.length,
      itemBuilder: (context, index) {
        final song = songs[index];
        return ListTile(
          leading: Container(
            width: 50,
            height: 50,
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
          title: Text(
            song.title,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            song.artists.isNotEmpty
                ? song.artists.map((a) => a.name).join(', ')
                : 'Unknown Artist',
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (song.duration != null)
                Text(
                  song.duration!.formatted,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              const SizedBox(width: 8),
              // Play button
              IconButton(
                icon: const Icon(Icons.play_arrow, color: Colors.white, size: 20),
                onPressed: () => _playSong(song),
              ),
              IconButton(
                icon: Icon(Icons.more_vert, color: Colors.grey[400], size: 20),
                onPressed: () => _showSongOptions(song),
              ),
            ],
          ),
          onTap: () => _playSong(song),
        );
      },
    );
  }

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.grey[400], size: 64),
          const SizedBox(height: 16),
          Text(
            'Failed to search',
            style: TextStyle(color: Colors.grey[400], fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              if (_searchController.text.isNotEmpty) {
                context.read<YouTubeMusicBloc>().add(
                  SearchYouTubeMusic(_searchController.text),
                );
              }
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultContent() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Search YouTube Music',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Find songs, albums, artists, and playlists',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }

  void _playSong(YouTubeSong song) {
    context.read<MusicPlayerBloc>().add(PlaySong(song));
  }

  void _showSongOptions(YouTubeSong song) {
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
              _playSong(song);
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
              context.read<MusicPlayerBloc>().add(AddToQueue(song));
            },
          ),
          ListTile(
            leading: const Icon(Icons.favorite_border, color: Colors.white),
            title: const Text(
              'Add to Favorites',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {},
          ),
          if (song.album != null)
            ListTile(
              leading: const Icon(Icons.album, color: Colors.white),
              title: const Text(
                'Go to Album',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement load album
              },
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

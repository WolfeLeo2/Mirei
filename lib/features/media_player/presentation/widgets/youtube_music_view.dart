import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../bloc/youtube_music_bloc.dart';
import '../../../../bloc/music_player_bloc.dart';
import '../../../../models/youtube_music_models.dart';
import '../../../../utils/duration_extensions.dart';
import '../../../../components/audio_streaming_info.dart';
import '../../../../services/youtube_music_streaming_service.dart';

class YouTubeMusicView extends StatefulWidget {
  const YouTubeMusicView({super.key});

  @override
  State<YouTubeMusicView> createState() => _YouTubeMusicViewState();
}

class _YouTubeMusicViewState extends State<YouTubeMusicView>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    // Load initial popular content
    context.read<YouTubeMusicBloc>().add(const SearchYouTubeMusic('popular music', limit: 20));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      child: Column(
        children: [
          // Search Bar
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1e3a8a).withOpacity(0.1), // Navy blue with opacity
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFF1e3a8a).withOpacity(0.2)), // Navy blue with opacity
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Color(0xFF1e3a8a)), // Navy blue
              decoration: InputDecoration(
                hintText: 'Search songs, artists, albums...',
                hintStyle: TextStyle(color: const Color(0xFF1e3a8a).withOpacity(0.6)), // Navy blue with opacity
                prefixIcon: Icon(Icons.search, color: const Color(0xFF1e3a8a).withOpacity(0.6)), // Navy blue with opacity
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: const Color(0xFF1e3a8a).withOpacity(0.6)), // Navy blue with opacity
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
              onChanged: (value) => setState(() {}),
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  context.read<YouTubeMusicBloc>().add(SearchYouTubeMusic(value));
                }
              },
            ),
          ),

          // Tab Bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF1e3a8a).withOpacity(0.05), // Navy blue with opacity
              borderRadius: BorderRadius.circular(25),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: const Color(0xFF1e3a8a).withOpacity(0.2), // Navy blue with opacity
                borderRadius: BorderRadius.circular(25),
              ),
              indicatorPadding: const EdgeInsets.all(4),
              labelColor: const Color(0xFF1e3a8a), // Navy blue
              unselectedLabelColor: const Color(0xFF1e3a8a).withOpacity(0.6), // Navy blue with opacity
              labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400, fontSize: 14),
              tabs: const [
                Tab(text: 'Songs'),
                Tab(text: 'Artists'),
                Tab(text: 'Albums'),
                Tab(text: 'Playlists'),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSongsTab(),
                _buildArtistsTab(),
                _buildAlbumsTab(),
                _buildPlaylistsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSongsTab() {
    return BlocBuilder<YouTubeMusicBloc, YouTubeMusicState>(
      builder: (context, state) {
        if (state is YouTubeMusicLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF1e3a8a)), // Navy blue
          );
        } else if (state is YouTubeMusicSearchResultsLoaded) {
          return _buildSongsList(state.searchResult.songs);
        } else if (state is YouTubeMusicSongsLoaded) {
          return _buildSongsList(state.songs);
        } else if (state is YouTubeMusicError) {
          return _buildErrorWidget(state.message);
        } else {
          return _buildDefaultContent();
        }
      },
    );
  }

  Widget _buildSongsList(List<YouTubeSong> songs) {
    if (songs.isEmpty) {
      return const Center(
        child: Text(
          'No songs found',
          style: TextStyle(color: Color(0xFF1e3a8a), fontSize: 16), // Navy blue
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: songs.length,
      itemBuilder: (context, index) {
        final song = songs[index];
        return _buildSongItem(song);
      },
    );
  }

  Widget _buildSongItem(YouTubeSong song) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.white.withOpacity(0.1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: song.thumbnailUrl.isNotEmpty
                ? Image.network(
                    song.thumbnailUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Icon(Icons.music_note, color: const Color(0xFF1e3a8a).withOpacity(0.5)), // Navy blue
                  )
                : Icon(Icons.music_note, color: const Color(0xFF1e3a8a).withOpacity(0.5)), // Navy blue
          ),
        ),
        title: Text(
          song.title,
          style: const TextStyle(
            color: Color(0xFF1e3a8a), // Navy blue
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          song.artists.isNotEmpty
              ? song.artists.map((a) => a.name).join(', ')
              : 'Unknown Artist',
          style: TextStyle(
            color: const Color(0xFF1e3a8a).withOpacity(0.7), // Navy blue with opacity
            fontSize: 13,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (song.duration != null)
              Text(
                song.duration!.formatted,
                style: TextStyle(
                  color: const Color(0xFF1e3a8a).withOpacity(0.5), // Navy blue with opacity
                  fontSize: 12,
                ),
              ),
            const SizedBox(width: 12),
            IconButton(
              icon: const Icon(Icons.play_arrow, color: Color(0xFF1e3a8a)), // Navy blue
              onPressed: () => _playSong(song),
            ),
            IconButton(
              icon: Icon(Icons.more_vert, color: const Color(0xFF1e3a8a).withOpacity(0.7)), // Navy blue with opacity
              onPressed: () => _showSongOptions(song),
            ),
          ],
        ),
        onTap: () => _playSong(song),
      ),
    );
  }

  Widget _buildArtistsTab() {
    return BlocBuilder<YouTubeMusicBloc, YouTubeMusicState>(
      builder: (context, state) {
        if (state is YouTubeMusicLoading) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF1e3a8a))); // Navy blue
        } else if (state is YouTubeMusicSearchResultsLoaded) {
          return _buildArtistsList(state.searchResult.artists);
        } else if (state is YouTubeMusicArtistsLoaded) {
          return _buildArtistsList(state.artists);
        } else {
          return _buildDefaultContent();
        }
      },
    );
  }

  Widget _buildArtistsList(List<YouTubeArtist> artists) {
    if (artists.isEmpty) {
      return const Center(
        child: Text('No artists found', style: TextStyle(color: Color(0xFF1e3a8a))), // Navy blue
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: artists.length,
      itemBuilder: (context, index) {
        final artist = artists[index];
        return _buildArtistCard(artist);
      },
    );
  }

  Widget _buildArtistCard(YouTubeArtist artist) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
              child: ClipOval(
                child: artist.thumbnailUrl != null && artist.thumbnailUrl!.isNotEmpty
                    ? Image.network(
                        artist.thumbnailUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Icon(Icons.person, color: const Color(0xFF1e3a8a).withOpacity(0.5), size: 40), // Navy blue
                      )
                    : Icon(Icons.person, color: const Color(0xFF1e3a8a).withOpacity(0.5), size: 40), // Navy blue
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Text(
                  artist.name,
                  style: const TextStyle(
                    color: Color(0xFF1e3a8a), // Navy blue
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                if (artist.subscriberCount.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    artist.subscriberCount,
                    style: TextStyle(
                      color: const Color(0xFF1e3a8a).withOpacity(0.7), // Navy blue with opacity
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumsTab() {
    return BlocBuilder<YouTubeMusicBloc, YouTubeMusicState>(
      builder: (context, state) {
        if (state is YouTubeMusicLoading) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF1e3a8a))); // Navy blue
        } else if (state is YouTubeMusicSearchResultsLoaded) {
          return _buildAlbumsList(state.searchResult.albums);
        } else if (state is YouTubeMusicAlbumsLoaded) {
          return _buildAlbumsList(state.albums);
        } else {
          return _buildDefaultContent();
        }
      },
    );
  }

  Widget _buildAlbumsList(List<YouTubeAlbum> albums) {
    if (albums.isEmpty) {
      return const Center(
        child: Text('No albums found', style: TextStyle(color: Color(0xFF1e3a8a))), // Navy blue
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: albums.length,
      itemBuilder: (context, index) {
        final album = albums[index];
        return _buildAlbumItem(album);
      },
    );
  }

  Widget _buildAlbumItem(YouTubeAlbum album) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.white.withOpacity(0.1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: album.thumbnailUrl != null && album.thumbnailUrl!.isNotEmpty
                ? Image.network(
                    album.thumbnailUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Icon(Icons.album, color: const Color(0xFF1e3a8a).withOpacity(0.5)), // Navy blue
                  )
                : Icon(Icons.album, color: const Color(0xFF1e3a8a).withOpacity(0.5)), // Navy blue
          ),
        ),
        title: Text(
          album.title,
          style: const TextStyle(
            color: Color(0xFF1e3a8a), // Navy blue
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (album.artists.isNotEmpty)
              Text(
                album.artists.map((a) => a.name).join(', '),
                style: TextStyle(
                  color: const Color(0xFF1e3a8a).withOpacity(0.7), // Navy blue with opacity
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            if (album.year.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                album.year,
                style: TextStyle(
                  color: const Color(0xFF1e3a8a).withOpacity(0.5), // Navy blue with opacity
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.more_vert, color: const Color(0xFF1e3a8a).withOpacity(0.7)), // Navy blue with opacity
          onPressed: () => _showAlbumOptions(album),
        ),
      ),
    );
  }

  Widget _buildPlaylistsTab() {
    return BlocBuilder<YouTubeMusicBloc, YouTubeMusicState>(
      builder: (context, state) {
        if (state is YouTubeMusicLoading) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF1e3a8a))); // Navy blue
        } else if (state is YouTubeMusicSearchResultsLoaded) {
          return _buildPlaylistsList(state.searchResult.playlists);
        } else if (state is YouTubeMusicPlaylistsLoaded) {
          return _buildPlaylistsList(state.playlists);
        } else {
          return _buildDefaultContent();
        }
      },
    );
  }

  Widget _buildPlaylistsList(List<YouTubePlaylist> playlists) {
    if (playlists.isEmpty) {
      return const Center(
        child: Text('No playlists found', style: TextStyle(color: Color(0xFF1e3a8a))), // Navy blue
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: playlists.length,
      itemBuilder: (context, index) {
        final playlist = playlists[index];
        return _buildPlaylistItem(playlist);
      },
    );
  }

  Widget _buildPlaylistItem(YouTubePlaylist playlist) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.white.withOpacity(0.1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: playlist.thumbnailUrl != null && playlist.thumbnailUrl!.isNotEmpty
                ? Image.network(
                    playlist.thumbnailUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Icon(Icons.playlist_play, color: const Color(0xFF1e3a8a).withOpacity(0.5)), // Navy blue
                  )
                : Icon(Icons.playlist_play, color: const Color(0xFF1e3a8a).withOpacity(0.5)), // Navy blue
          ),
        ),
        title: Text(
          playlist.title,
          style: const TextStyle(
            color: Color(0xFF1e3a8a), // Navy blue
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (playlist.author != null && playlist.author!.isNotEmpty)
              Text(
                playlist.author!,
                style: TextStyle(
                  color: const Color(0xFF1e3a8a).withOpacity(0.7), // Navy blue
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            if (playlist.videoCount != null) ...[
              const SizedBox(height: 2),
              Text(
                '${playlist.videoCount} videos',
                style: TextStyle(
                  color: const Color(0xFF1e3a8a).withOpacity(0.5), // Navy blue
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.more_vert, color: const Color(0xFF1e3a8a).withOpacity(0.7)), // Navy blue with opacity
          onPressed: () => _showPlaylistOptions(playlist),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: const Color(0xFF1e3a8a).withOpacity(0.5), size: 64), // Navy blue
          const SizedBox(height: 16),
          Text(
            'Failed to load content',
            style: TextStyle(color: const Color(0xFF1e3a8a).withOpacity(0.7), fontSize: 18), // Navy blue
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(color: const Color(0xFF1e3a8a).withOpacity(0.5), fontSize: 14), // Navy blue
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              context.read<YouTubeMusicBloc>().add(const SearchYouTubeMusic('popular music'));
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
          Icon(Icons.search, size: 64, color: Color(0xFF1e3a8a)), // Navy blue
          SizedBox(height: 16),
          Text(
            'Search YouTube Music',
            style: TextStyle(
              color: const Color(0xFF1e3a8a), // Navy blue
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Find songs, albums, artists, and playlists',
            style: TextStyle(color: const Color(0xFF1e3a8a), fontSize: 14), // Navy blue
          ),
        ],
      ),
    );
  }

  void _playSong(YouTubeSong song) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF1e3a8a)),
      ),
    );

    try {
      // Use the new InnerTube streaming service
      final streamingService = YouTubeMusicStreamingService();
      final success = await streamingService.playYouTubeSong(song);
      
      // Dismiss loading
      if (mounted) Navigator.of(context).pop();
      
      if (success) {
        // Update the player UI to show the selected song
        context.read<MusicPlayerBloc>().add(PlaySong(song));
        
        // Show success feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Now playing: ${song.title}'),
            backgroundColor: const Color(0xFF1e3a8a),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        // Show error with retry option
        _showPlaybackError(song);
      }
    } catch (e) {
      // Dismiss loading
      if (mounted) Navigator.of(context).pop();
      
      print('[YouTubeMusicView] Playback error: $e');
      _showPlaybackError(song);
    }
  }

  void _showPlaybackError(YouTubeSong song) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Playback Error',
          style: TextStyle(color: Color(0xFF1e3a8a)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Unable to play "${song.title}". This could be due to:',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 12),
            const Text(
              '• Regional restrictions',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const Text(
              '• Age restrictions',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const Text(
              '• Network connectivity issues',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const Text(
              '• Content not available for streaming',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _playSong(song); // Retry
            },
            child: const Text(
              'Retry',
              style: TextStyle(color: Color(0xFF1e3a8a)),
            ),
          ),
        ],
      ),
    );
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
            leading: const Icon(Icons.play_arrow, color: Color(0xFF1e3a8a)), // Navy blue
            title: const Text('Play Now', style: TextStyle(color: Color(0xFF1e3a8a))), // Navy blue
            onTap: () {
              Navigator.pop(context);
              _playSong(song);
            },
          ),
          ListTile(
            leading: const Icon(Icons.queue_music, color: Color(0xFF1e3a8a)), // Navy blue
            title: const Text('Add to Queue', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              context.read<MusicPlayerBloc>().add(AddToQueue(song));
            },
          ),
          ListTile(
            leading: const Icon(Icons.favorite_border, color: Colors.white),
            title: const Text('Add to Favorites', style: TextStyle(color: Colors.white)),
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showAlbumOptions(YouTubeAlbum album) {
    // TODO: Implement album options
  }

  void _showPlaylistOptions(YouTubePlaylist playlist) {
    // TODO: Implement playlist options
  }
}

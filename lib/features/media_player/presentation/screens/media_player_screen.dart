import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:mirei/features/media_player/presentation/bloc/media_player_bloc.dart';
import 'package:mirei/features/media_player/presentation/widgets/library_view.dart';
import 'package:mirei/features/media_player/presentation/widgets/streaming_view.dart';
import 'package:mirei/components/media/mini_player.dart';

class MediaPlayerScreen extends StatelessWidget {
  const MediaPlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MediaPlayerBloc(),
      child: const _MediaPlayerView(),
    );
  }
}

class _MediaPlayerView extends StatelessWidget {
  const _MediaPlayerView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MediaPlayerBloc, MediaPlayerMode>(
      builder: (context, mode) {
        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1e3a8a), // Navy blue
                  Color(0xFF1e40af), // Medium blue
                  Color.fromARGB(255, 7, 3, 54),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
            child: Stack(
              children: [
                SafeArea(
                  child: CustomScrollView(
                    slivers: [
                      // Modern header with unified search
                      SliverAppBar(
                        expandedHeight: 80,
                        floating: false,
                        pinned: false,
                        snap: false,
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        automaticallyImplyLeading: false,
                        flexibleSpace: FlexibleSpaceBar(
                          titlePadding: const EdgeInsets.only(
                            left: 20,
                            bottom: 16,
                            right: 20,
                          ),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Mirei',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Agne',
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.search,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      // Handle unified search
                                      showSearch(
                                        context: context,
                                        delegate: UnifiedSearchDelegate(),
                                      );
                                    },
                                  ),
                                  _buildMenuButton(context, mode),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      mode == MediaPlayerMode.library
                          ? const LibraryView()
                          : const StreamingView(),
                    ],
                  ),
                ),
                // Mini Player positioned above navigation
                Positioned(
                  bottom:
                      MediaQuery.of(context).size.height *
                      0.12, // 12% from bottom, responsive to screen height
                  left:
                      MediaQuery.of(context).size.width *
                      0.02, // 2% margin from left
                  right:
                      MediaQuery.of(context).size.width *
                      0.02, // 2% margin from right
                  child: MiniPlayer(
                    currentTrack: 'Girls',
                    currentArtist: 'Unknown Artist',
                    isPlaying: false,
                    onPlayPause: () {
                      // Handle play/pause
                    },
                    onNext: () {
                      // Handle next track
                    },
                    onTap: () {
                      // Handle tap to open full player
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuButton(BuildContext context, MediaPlayerMode currentMode) {
    return PullDownButton(
      itemBuilder: (context) => [
        PullDownMenuItem(
          title: currentMode == MediaPlayerMode.library
              ? 'Library'
              : 'Listen Now',
          icon: currentMode == MediaPlayerMode.library
              ? Icons.library_music
              : Icons.play_circle_outline,
          onTap: () => context.read<MediaPlayerBloc>().toggleMode(),
        ),
        const PullDownMenuDivider.large(),
        PullDownMenuItem(title: 'Settings', icon: Icons.settings, onTap: () {}),
        PullDownMenuItem(title: 'Help', icon: Icons.help_outline, onTap: () {}),
      ],
      position: PullDownMenuPosition.automatic,
      buttonBuilder: (context, showMenu) => IconButton(
        icon: const Icon(Icons.menu, color: Colors.white),
        onPressed: showMenu,
      ),
    );
  }
}

class UnifiedSearchDelegate extends SearchDelegate<String> {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return const Center(child: Text('Search results will appear here'));
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return ListView(
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Search across Mirei Originals and connected streaming services',
            style: TextStyle(color: Colors.grey),
          ),
        ),
        if (query.isEmpty) ...[
          const ListTile(
            leading: Icon(Icons.trending_up),
            title: Text('Trending wellness tracks'),
          ),
          const ListTile(
            leading: Icon(Icons.history),
            title: Text('Recent searches'),
          ),
        ],
      ],
    );
  }
}

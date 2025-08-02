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
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                  Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.3),
                  Theme.of(context).colorScheme.tertiaryContainer.withOpacity(0.3),
                ],
                stops: const [0.0, 0.5, 1.0],
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
                      
                      // Service Selection Cards
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildServiceCard(
                                  context,
                                  title: 'Mirei',
                                  subtitle: 'Local Music',
                                  icon: Icons.library_music,
                                  color: Theme.of(context).colorScheme.primary,
                                  isSelected: mode == MediaPlayerMode.library,
                                  onTap: () => context.read<MediaPlayerBloc>().setMode(MediaPlayerMode.library),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildServiceCard(
                                  context,
                                  title: 'YouTube',
                                  subtitle: 'Music & Videos',
                                  icon: Icons.play_circle_outline,
                                  color: Colors.red,
                                  isSelected: mode == MediaPlayerMode.streaming,
                                  onTap: () => context.read<MediaPlayerBloc>().setMode(MediaPlayerMode.streaming),
                                ),
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
                  child: const MiniPlayer(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildServiceCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? color.withOpacity(0.2)
              : Theme.of(context).colorScheme.surface.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
                ? color.withOpacity(0.5)
                : Colors.white.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? color : Colors.white70,
                  size: 24,
                ),
                const Spacer(),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: color,
                    size: 20,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
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

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/youtube_music_bloc.dart';

class YouTubeMusicTestScreen extends StatefulWidget {
  const YouTubeMusicTestScreen({super.key});

  @override
  State<YouTubeMusicTestScreen> createState() => _YouTubeMusicTestScreenState();
}

class _YouTubeMusicTestScreenState extends State<YouTubeMusicTestScreen> {
  String _testResults = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('YouTube Music API Test'),
        backgroundColor: Colors.red,
      ),
      body: Container(
        color: Colors.black,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _testResults = 'Testing Quick Picks...';
                });
                context.read<YouTubeMusicBloc>().add(const SearchYouTubeMusicSongs('popular music', limit: 10));
              },
              child: const Text('Test Quick Picks'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _testResults = 'Testing Search...';
                });
                context.read<YouTubeMusicBloc>().add(
                  const SearchYouTubeMusic('hello'),
                );
              },
              child: const Text('Test Search'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _testResults = 'Testing Song Search...';
                });
                context.read<YouTubeMusicBloc>().add(
                  const SearchYouTubeMusicSongs('hello'),
                );
              },
              child: const Text('Test Song Search'),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: BlocListener<YouTubeMusicBloc, YouTubeMusicState>(
                  listener: (context, state) {
                    setState(() {
                      if (state is YouTubeMusicLoading) {
                        _testResults = 'Loading...';
                      } else if (state is YouTubeMusicError) {
                        _testResults = 'ERROR: ${state.message}';
                      } else if (state is YouTubeMusicSongsLoaded) {
                        _testResults =
                            'Songs SUCCESS:\n'
                            'Query: ${state.query}\n'
                            'Songs: ${state.songs.length}';
                      } else if (state is YouTubeMusicSearchResultsLoaded) {
                        _testResults =
                            'Search SUCCESS:\n'
                            'Query: ${state.query}\n'
                            'Songs: ${state.searchResult.songs.length}\n'
                            'Albums: ${state.searchResult.albums.length}\n'
                            'Artists: ${state.searchResult.artists.length}\n'
                            'Playlists: ${state.searchResult.playlists.length}';
                      } else if (state is YouTubeMusicAlbumsLoaded) {
                        _testResults =
                            'Albums SUCCESS:\n'
                            'Query: ${state.query}\n'
                            'Albums: ${state.albums.length}';
                      }
                    });
                  },
                  child: SingleChildScrollView(
                    child: Text(
                      _testResults.isEmpty
                          ? 'Tap a button to test YouTube Music API'
                          : _testResults,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'monospace',
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:spotify/spotify.dart' as SpotifyApi;
import 'dart:convert';
import '../bloc/media_player_bloc.dart';
import '../bloc/media_player_event.dart';
import '../bloc/media_player_state.dart';
import '../services/spotify_service.dart';

class Material3MediaPlayerScreen extends StatefulWidget {
  final String trackTitle;
  final String artistName;
  final String albumArt;
  final String? audioUrl;
  final List<Map<String, dynamic>>? playlist;
  final int? currentIndex;
  final SpotifyApi.Track? spotifyTrack;
  final bool isSpotifyTrack;
  final bool hasSpotifyPremium;
  final SpotifyService? spotifyService;

  const Material3MediaPlayerScreen({
    super.key,
    required this.trackTitle,
    required this.artistName,
    required this.albumArt,
    this.audioUrl,
    this.playlist,
    this.currentIndex,
    this.spotifyTrack,
    this.isSpotifyTrack = false,
    this.hasSpotifyPremium = false,
    this.spotifyService,
  });

  @override
  State<Material3MediaPlayerScreen> createState() =>
      _Material3MediaPlayerScreenState();
}

class _Material3MediaPlayerScreenState
    extends State<Material3MediaPlayerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePlayer();
    });
  }

  void _initializePlayer() {
    if (widget.isSpotifyTrack &&
        widget.spotifyTrack != null &&
        widget.spotifyService != null) {
      // Initialize Spotify track
      context.read<MediaPlayerBloc>().add(
        InitializeSpotify(
          spotifyTrack: widget.spotifyTrack!,
          spotifyService: widget.spotifyService!,
          hasSpotifyPremium: widget.hasSpotifyPremium,
        ),
      );
    } else {
      // Initialize local track
      context.read<MediaPlayerBloc>().add(
        Initialize(
          trackTitle: widget.trackTitle,
          artistName: widget.artistName,
          albumArt: widget.albumArt,
          audioUrl: widget.audioUrl,
          playlist: widget.playlist,
          currentIndex: widget.currentIndex,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MediaPlayerBloc, MediaPlayerState>(
      buildWhen: (previous, current) {
        // Only rebuild when essential properties change
        return previous.isLoading != current.isLoading ||
            previous.trackTitle != current.trackTitle ||
            previous.artistName != current.artistName ||
            previous.albumArt != current.albumArt ||
            previous.hasError != current.hasError;
      },
      builder: (context, state) {
        if (state.isLoading) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          );
        }

        return Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      BlocBuilder<MediaPlayerBloc, MediaPlayerState>(
                        buildWhen: (previous, current) =>
                            previous.albumArt != current.albumArt,
                        builder: (context, state) => _buildAlbumArt(state),
                      ),
                      const SizedBox(height: 32),
                      BlocBuilder<MediaPlayerBloc, MediaPlayerState>(
                        buildWhen: (previous, current) =>
                            previous.trackTitle != current.trackTitle ||
                            previous.artistName != current.artistName,
                        builder: (context, state) => _buildTrackInfo(state),
                      ),
                      const SizedBox(height: 32),
                      BlocBuilder<MediaPlayerBloc, MediaPlayerState>(
                        buildWhen: (previous, current) =>
                            previous.position != current.position ||
                            previous.duration != current.duration,
                        builder: (context, state) =>
                            _buildProgressSection(state),
                      ),
                      const SizedBox(height: 32),
                      BlocBuilder<MediaPlayerBloc, MediaPlayerState>(
                        buildWhen: (previous, current) =>
                            previous.isPlaying != current.isPlaying ||
                            previous.isLoading != current.isLoading,
                        builder: (context, state) => _buildControls(state),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAlbumArt(MediaPlayerState state) {
    return Container(
      width: 300,
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: state.albumArt.isNotEmpty
            ? (state.albumArt.startsWith('data:image')
                  ? Image.memory(
                      base64Decode(state.albumArt.split(',')[1]),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildPlaceholder(),
                    )
                  : (widget.isSpotifyTrack
                        ? () {
                            final convertedUrl =
                                SpotifyService.convertSpotifyImageUri(
                                  state.albumArt,
                                );
                            return convertedUrl != null
                                ? CachedNetworkImage(
                                    imageUrl: convertedUrl,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) =>
                                        _buildPlaceholder(),
                                    errorWidget: (context, url, error) =>
                                        _buildPlaceholder(),
                                  )
                                : _buildPlaceholder();
                          }()
                        : CachedNetworkImage(
                            imageUrl: state.albumArt,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => _buildPlaceholder(),
                            errorWidget: (context, url, error) =>
                                _buildPlaceholder(),
                          )))
            : _buildPlaceholder(),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: Icon(
        Icons.music_note,
        size: 120,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildTrackInfo(MediaPlayerState state) {
    return Column(
      children: [
        Text(
          state.trackTitle,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Text(
          state.artistName,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(
                Icons.favorite_border,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              onPressed: () {},
            ),
            const SizedBox(width: 16),
            IconButton(
              icon: Icon(
                Icons.share,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              onPressed: () {},
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressSection(MediaPlayerState state) {
    final progress = state.duration.inMilliseconds > 0
        ? state.position.inMilliseconds / state.duration.inMilliseconds
        : 0.0;

    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
          ),
          child: Slider(
            value: progress.clamp(0.0, 1.0),
            onChanged: (value) {
              final newPosition = Duration(
                milliseconds: (value * state.duration.inMilliseconds).round(),
              );
              context.read<MediaPlayerBloc>().add(Seek(newPosition));
            },
            activeColor: Theme.of(context).colorScheme.primary,
            inactiveColor: Theme.of(context).colorScheme.outline,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(state.position),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                _formatDuration(state.duration),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControls(MediaPlayerState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          icon: const Icon(Icons.skip_previous),
          iconSize: 40,
          onPressed: () =>
              context.read<MediaPlayerBloc>().add(const SkipToPrevious()),
        ),
        _buildPlayPauseButton(state),
        IconButton(
          icon: const Icon(Icons.skip_next),
          iconSize: 40,
          onPressed: () =>
              context.read<MediaPlayerBloc>().add(const SkipToNext()),
        ),
      ],
    );
  }

  Widget _buildPlayPauseButton(MediaPlayerState state) {
    if (state.isLoading) {
      return Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),
        ),
      );
    }

    return FilledButton(
      onPressed: () {
        if (state.isPlaying) {
          context.read<MediaPlayerBloc>().add(Pause());
        } else {
          context.read<MediaPlayerBloc>().add(Play());
        }
      },
      style: FilledButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        shape: const CircleBorder(),
        padding: const EdgeInsets.all(16),
      ),
      child: Icon(state.isPlaying ? Icons.pause : Icons.play_arrow, size: 32),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _formatDurationFromMs(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    return _formatDuration(duration);
  }
}

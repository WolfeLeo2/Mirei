import 'package:flutter/material.dart';
import 'package:spotify/spotify.dart' as SpotifyApi;
import '../screens/material3_media_player_screen.dart';
import '../services/spotify_service.dart';

/// Show the FIXED unified media player modal - uses existing MediaPlayerBloc
Future<void> showNewMediaPlayerModal(
  BuildContext context, {
  // For Spotify tracks
  SpotifyApi.Track? spotifyTrack,

  // For local tracks
  String? localTrackId,
  String? trackTitle,
  String? artistName,
  String? albumArt,
  String? audioUrl,
  Duration? duration,

  // Playlist data for skip functionality
  List<Map<String, dynamic>>? playlist,
  int? currentIndex,

  // Services
  SpotifyService? spotifyService,
}) async {
  if (spotifyTrack != null) {
    // For Spotify tracks - use the existing Spotify system
    return showSpotifyPlayerModal(context, spotifyTrack, spotifyService!);
  } else if (trackTitle != null && artistName != null && audioUrl != null) {
    // For local tracks - use existing MediaPlayerBloc system
    await showModalBottomSheet(
      context: context, 
      isScrollControlled: true,
      useSafeArea: true,
      enableDrag: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height,
        maxWidth: MediaQuery.of(context).size.width,
      ),
      backgroundColor: Colors.transparent,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: Material3MediaPlayerScreen(
          trackTitle: trackTitle,
          artistName: artistName,
          albumArt: albumArt ?? '',
          audioUrl: audioUrl,
          playlist: playlist,
          currentIndex: currentIndex,
        ),
      ),
    );
  } else {
    throw ArgumentError(
      'Either spotifyTrack or local track parameters must be provided',
    );
  }
}

/// Convenience method for Spotify tracks - FIXED to use working system!
Future<void> showSpotifyPlayerModal(
  BuildContext context,
  SpotifyApi.Track spotifyTrack,
  SpotifyService spotifyService,
) async {
  final artistNames =
      spotifyTrack.artists?.map((a) => a.name).join(', ') ?? 'Unknown Artist';
  final albumImageUrl = spotifyTrack.album?.images?.isNotEmpty == true
      ? spotifyTrack.album!.images!.first.url
      : null;

  // Use the NEW beautiful RedesignedMediaPlayerScreen!
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Material3MediaPlayerScreen(
      trackTitle: spotifyTrack.name ?? 'Unknown Track',
      artistName: artistNames,
      albumArt: albumImageUrl ?? 'assets/images/lofi.png',
      audioUrl: null, // Spotify SDK handles playbook
      spotifyTrack: spotifyTrack,
      isSpotifyTrack: true,
      hasSpotifyPremium: true, // Assuming premium since we're playing
      spotifyService: spotifyService,
    ),
  );
}

/// Convenience method for local tracks
Future<void> showLocalPlayerModal(
  BuildContext context, {
  required String title,
  required String artist,
  required String audioUrl,
  String? albumArt,
  Duration? duration,
  List<Map<String, dynamic>>? playlist,
  int? currentIndex,
}) async {
  return showNewMediaPlayerModal(
    context,
    trackTitle: title,
    artistName: artist,
    audioUrl: audioUrl,
    albumArt: albumArt,
    duration: duration,
    playlist: playlist,
    currentIndex: currentIndex,
  );
}

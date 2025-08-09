import 'package:flutter/material.dart';
import '../screens/media_player_screen.dart';

/// Utility function to show MediaPlayerScreen as a full-screen modal bottom sheet
Future<void> showMediaPlayerModal({
  required BuildContext context,
  required String trackTitle,
  required String artistName,
  required String albumArt,
  String? audioUrl,
  List<Map<String, dynamic>>? playlist,
  int? currentIndex,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true, // Allows full-screen height
    backgroundColor: Colors.transparent, // Make background transparent
    barrierColor: Colors.black.withOpacity(0.5), // Custom barrier color
    enableDrag: true, // Disable drag since we removed the handle
    isDismissible: true, // Allow tapping outside to close
    useSafeArea: false, // Let the MediaPlayerScreen handle safe areas
    builder: (BuildContext context) {
      return MediaPlayerBottomSheet(
        trackTitle: trackTitle,
        artistName: artistName,
        albumArt: albumArt,
        audioUrl: audioUrl,
        playlist: playlist,
        currentIndex: currentIndex,
      );
    },
  );
}

/// Wrapper widget for MediaPlayerScreen optimized for modal bottom sheet
class MediaPlayerBottomSheet extends StatelessWidget {
  final String trackTitle;
  final String artistName;
  final String albumArt;
  final String? audioUrl;
  final List<Map<String, dynamic>>? playlist;
  final int? currentIndex;

  const MediaPlayerBottomSheet({
    super.key,
    required this.trackTitle,
    required this.artistName,
    required this.albumArt,
    this.audioUrl,
    this.playlist,
    this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height, // Full height
      decoration: const BoxDecoration(
        color: Color.fromARGB(
          255,
          231,
          218,
          239,
        ), // Same background as original
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20), // Rounded top corners for modal feel
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: MediaPlayerScreen(
          trackTitle: trackTitle,
          artistName: artistName,
          albumArt: albumArt,
          audioUrl: audioUrl,
          playlist: playlist,
          currentIndex: currentIndex,
        ),
      ),
    );
  }
}

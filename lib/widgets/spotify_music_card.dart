import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:spotify/spotify.dart' as SpotifyApi;

class SpotifyMusicCard extends StatelessWidget {
  final SpotifyApi.Track? track;
  final SpotifyApi.PlaylistSimple? playlist;
  final VoidCallback onTap;

  const SpotifyMusicCard({
    super.key,
    this.track,
    this.playlist,
    required this.onTap,
  }) : assert(track != null || playlist != null, 'Either track or playlist must be provided');

  @override
  Widget build(BuildContext context) {
    final isPlaylist = playlist != null;
    final title = isPlaylist ? playlist!.name ?? 'Unknown Playlist' : track!.name ?? 'Unknown Track';
    final subtitle = isPlaylist 
        ? 'Playlist' // Simple label for playlists
        : track!.artists?.map((a) => a.name).join(', ') ?? 'Unknown Artist';
    final imageUrl = isPlaylist 
        ? (playlist!.images?.isNotEmpty == true ? playlist!.images!.first.url : null)
        : (track!.album?.images?.isNotEmpty == true ? track!.album!.images!.first.url : null);

    return RepaintBoundary(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 200,
          margin: const EdgeInsets.only(right: 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Album/Playlist artwork container
              RepaintBoundary(
                child: Container(
                  width: 180,
                  height: 200,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: imageUrl != null
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => _buildDefaultImage(isPlaylist),
                          )
                        : _buildDefaultImage(isPlaylist),
                  ),
                ),
              ),
              // Text section
              RepaintBoundary(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        color: Colors.black87.withOpacity(0.6),
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultImage(bool isPlaylist) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.green.withOpacity(0.6),
            Colors.green.withOpacity(0.8),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          isPlaylist ? FontAwesome.list_solid : FontAwesome.music_solid,
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }
} 
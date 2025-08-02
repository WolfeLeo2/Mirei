import '../../../models/youtube_music_models.dart';

/// Search response models for InnerTube API
class SearchResponse {
  final List<dynamic> contents;
  final String? estimatedResults;
  final String? continuation;

  SearchResponse({
    required this.contents,
    this.estimatedResults,
    this.continuation,
  });

  factory SearchResponse.fromJson(Map<String, dynamic> json) {
    final contents = <dynamic>[];
    
    // Navigate the complex YouTube response structure
    final tabRenderer = json['contents']?['tabbedSearchResultsRenderer']?['tabs']?[0]?['tabRenderer'];
    final sectionList = tabRenderer?['content']?['sectionListRenderer']?['contents'];
    
    if (sectionList != null) {
      for (final section in sectionList) {
        if (section['musicShelfRenderer'] != null) {
          final musicShelf = section['musicShelfRenderer'];
          if (musicShelf['contents'] != null) {
            contents.addAll(musicShelf['contents']);
          }
        }
      }
    }

    return SearchResponse(
      contents: contents,
      estimatedResults: json['estimatedResults'],
      continuation: _extractContinuation(json),
    );
  }

  static String? _extractContinuation(Map<String, dynamic> json) {
    // Extract continuation token for pagination
    try {
      final tabRenderer = json['contents']?['tabbedSearchResultsRenderer']?['tabs']?[0]?['tabRenderer'];
      final sectionList = tabRenderer?['content']?['sectionListRenderer']?['contents'];
      
      if (sectionList != null) {
        for (final section in sectionList) {
          final continuations = section['musicShelfRenderer']?['continuations'];
          if (continuations != null && continuations.isNotEmpty) {
            return continuations[0]['nextContinuationData']?['continuation'];
          }
        }
      }
    } catch (e) {
      // Ignore extraction errors
    }
    return null;
  }

  /// Parse search results into typed objects
  SearchResult parseResults() {
    final songs = <YouTubeSong>[];
    final artists = <YouTubeArtist>[];
    final albums = <YouTubeAlbum>[];
    final playlists = <YouTubePlaylist>[];

    for (final content in contents) {
      final renderer = content['musicResponsiveListItemRenderer'];
      if (renderer == null) continue;

      try {
        final item = _parseRenderer(renderer);
        if (item is YouTubeSong) {
          songs.add(item);
        } else if (item is YouTubeArtist) {
          artists.add(item);
        } else if (item is YouTubeAlbum) {
          albums.add(item);
        } else if (item is YouTubePlaylist) {
          playlists.add(item);
        }
      } catch (e) {
        // Skip malformed items
        continue;
      }
    }

    return SearchResult(
      songs: songs,
      artists: artists,
      albums: albums,
      playlists: playlists,
    );
  }

  dynamic _parseRenderer(Map<String, dynamic> renderer) {
    final flexColumns = renderer['flexColumns'] as List? ?? [];
    final fixedColumns = renderer['fixedColumns'] as List? ?? [];
    final navigationEndpoint = renderer['navigationEndpoint'];
    final thumbnail = renderer['thumbnail']?['musicThumbnailRenderer']?['thumbnail'];

    if (flexColumns.isEmpty) return null;

    final titleRuns = flexColumns[0]?['musicResponsiveListItemFlexColumnRenderer']?['text']?['runs'] as List? ?? [];
    if (titleRuns.isEmpty) return null;

    final title = titleRuns[0]?['text'] ?? '';
    final videoId = navigationEndpoint?['watchEndpoint']?['videoId'];
    final browseId = navigationEndpoint?['browseEndpoint']?['browseId'];

    // Determine item type based on navigation endpoint and structure
    if (videoId != null) {
      // It's a song
      final artists = <YouTubeArtist>[];
      YouTubeAlbum? album;
      Duration? duration;

      // Parse artist information from subtitle
      if (flexColumns.length > 1) {
        final subtitleRuns = flexColumns[1]?['musicResponsiveListItemFlexColumnRenderer']?['text']?['runs'] as List? ?? [];
        
        for (int i = 0; i < subtitleRuns.length; i += 2) {
          final run = subtitleRuns[i];
          final artistName = run?['text'];
          final artistId = run?['navigationEndpoint']?['browseEndpoint']?['browseId'];
          
          if (artistName != null && artistName.isNotEmpty) {
            artists.add(YouTubeArtist(
              id: artistId ?? '',
              name: artistName,
              thumbnailUrl: null,
              subscriberCount: '',
            ));
          }
        }
      }

      // Parse album information
      if (flexColumns.length > 2) {
        final albumRuns = flexColumns[2]?['musicResponsiveListItemFlexColumnRenderer']?['text']?['runs'] as List? ?? [];
        if (albumRuns.isNotEmpty) {
          final albumName = albumRuns[0]?['text'];
          final albumId = albumRuns[0]?['navigationEndpoint']?['browseEndpoint']?['browseId'];
          
          if (albumName != null && albumName.isNotEmpty) {
            album = YouTubeAlbum(
              id: albumId ?? '',
              title: albumName,
              artists: artists,
              year: '',
              thumbnailUrl: _getThumbnailUrl(thumbnail),
            );
          }
        }
      }

      // Parse duration
      if (fixedColumns.isNotEmpty) {
        final durationText = fixedColumns[0]?['musicResponsiveListItemFlexColumnRenderer']?['text']?['runs']?[0]?['text'];
        if (durationText != null) {
          duration = _parseDuration(durationText);
        }
      }

      return YouTubeSong(
        id: videoId,
        title: title,
        artist: artists.isNotEmpty ? artists.first.name : 'Unknown Artist',
        artists: artists,
        album: album,
        duration: duration,
        thumbnailUrl: _getThumbnailUrl(thumbnail) ?? '',
      );
    } else if (browseId != null) {
      // Determine if it's artist, album, or playlist based on browseId prefix
      if (browseId.startsWith('UC') || browseId.startsWith('MPLA')) {
        // Artist
        String subscriberCount = '';
        if (flexColumns.length > 1) {
          final subtitleRuns = flexColumns[1]?['musicResponsiveListItemFlexColumnRenderer']?['text']?['runs'] as List? ?? [];
          if (subtitleRuns.isNotEmpty) {
            subscriberCount = subtitleRuns[0]?['text'] ?? '';
          }
        }

        return YouTubeArtist(
          id: browseId,
          name: title,
          thumbnailUrl: _getThumbnailUrl(thumbnail),
          subscriberCount: subscriberCount,
        );
      } else if (browseId.startsWith('MPREb_')) {
        // Album
        final artists = <YouTubeArtist>[];
        String year = '';

        if (flexColumns.length > 1) {
          final subtitleRuns = flexColumns[1]?['musicResponsiveListItemFlexColumnRenderer']?['text']?['runs'] as List? ?? [];
          
          for (int i = 0; i < subtitleRuns.length; i += 2) {
            final run = subtitleRuns[i];
            final artistName = run?['text'];
            final artistId = run?['navigationEndpoint']?['browseEndpoint']?['browseId'];
            
            if (artistName != null && artistName.isNotEmpty && !RegExp(r'^\d{4}$').hasMatch(artistName)) {
              artists.add(YouTubeArtist(
                id: artistId ?? '',
                name: artistName,
                thumbnailUrl: null,
                subscriberCount: '',
              ));
            } else if (artistName != null && RegExp(r'^\d{4}$').hasMatch(artistName)) {
              year = artistName;
            }
          }
        }

        return YouTubeAlbum(
          id: browseId,
          title: title,
          artists: artists,
          year: year,
          thumbnailUrl: _getThumbnailUrl(thumbnail),
        );
      } else if (browseId.startsWith('VL') || browseId.startsWith('PL')) {
        // Playlist
        String? author;
        int? videoCount;

        if (flexColumns.length > 1) {
          final subtitleRuns = flexColumns[1]?['musicResponsiveListItemFlexColumnRenderer']?['text']?['runs'] as List? ?? [];
          if (subtitleRuns.isNotEmpty) {
            author = subtitleRuns[0]?['text'];
          }
          
          // Look for video count
          for (final run in subtitleRuns) {
            final text = run?['text'] ?? '';
            final match = RegExp(r'(\d+)').firstMatch(text);
            if (match != null) {
              videoCount = int.tryParse(match.group(1) ?? '');
              break;
            }
          }
        }

        return YouTubePlaylist(
          id: browseId.startsWith('VL') ? browseId.substring(2) : browseId,
          name: title,
          author: author,
          trackCount: videoCount,
          thumbnailUrl: _getThumbnailUrl(thumbnail),
        );
      }
    }

    return null;
  }

  String? _getThumbnailUrl(Map<String, dynamic>? thumbnail) {
    if (thumbnail == null) return null;
    
    final thumbnails = thumbnail['thumbnails'] as List? ?? [];
    if (thumbnails.isEmpty) return null;
    
    // Get the highest quality thumbnail
    final lastThumbnail = thumbnails.last;
    return lastThumbnail['url'];
  }

  Duration? _parseDuration(String durationText) {
    // Parse duration in format "MM:SS" or "HH:MM:SS"
    final parts = durationText.split(':').map(int.tryParse).where((e) => e != null).cast<int>().toList();
    
    if (parts.length == 2) {
      return Duration(minutes: parts[0], seconds: parts[1]);
    } else if (parts.length == 3) {
      return Duration(hours: parts[0], minutes: parts[1], seconds: parts[2]);
    }
    
    return null;
  }
}

class SearchResult {
  final List<YouTubeSong> songs;
  final List<YouTubeArtist> artists;
  final List<YouTubeAlbum> albums;
  final List<YouTubePlaylist> playlists;

  SearchResult({
    required this.songs,
    required this.artists,
    required this.albums,
    required this.playlists,
  });
}

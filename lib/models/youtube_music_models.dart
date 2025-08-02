/// YouTube Music data models
/// Based on InnerTune implementation patterns

/// Search filter enum following InnerTune patterns
enum YouTubeSearchFilter {
  songs('EgWKAQIIAWoKEAkQBRAKEAMQBA%3D%3D'),
  videos('EgWKAQIQAWoKEAkQChAFEAMQBA%3D%3D'),
  albums('EgWKAQIYAWoKEAkQChAFEAMQBA%3D%3D'),
  artists('EgWKAQIgAWoKEAkQChAFEAMQBA%3D%3D'),
  playlists('EgeKAQQoADgBagwQDhAKEAMQBRAJEAQ%3D');

  const YouTubeSearchFilter(this._value);
  final String _value;

  String get value => _value;
}

/// Search result model
class YouTubeSearchResult {
  final List<YouTubeSong> songs;
  final List<YouTubeAlbum> albums;
  final List<YouTubeArtist> artists;
  final List<YouTubePlaylist> playlists;
  final String query;

  YouTubeSearchResult({
    this.songs = const [],
    this.albums = const [],
    this.artists = const [],
    this.playlists = const [],
    this.query = '',
  });

  factory YouTubeSearchResult.fromMixedResults({
    required List<dynamic> results,
    required String query,
  }) {
    final songs = <YouTubeSong>[];
    final albums = <YouTubeAlbum>[];
    final artists = <YouTubeArtist>[];
    final playlists = <YouTubePlaylist>[];

    for (final result in results) {
      if (result is Map<String, dynamic>) {
        final category = result['category'] ?? result['resultType'] ?? '';
        
        switch (category.toLowerCase()) {
          case 'song':
          case 'songs':
          case 'top result':
            if (result['videoId'] != null || result['title'] != null) {
              songs.add(YouTubeSong.fromYTMusicResult(result));
            }
            break;
          case 'album':
          case 'albums':
            if (result['browseId'] != null || result['title'] != null) {
              albums.add(YouTubeAlbum.fromYTMusicResult(result));
            }
            break;
          case 'artist':
          case 'artists':
            if (result['browseId'] != null || result['artist'] != null) {
              artists.add(YouTubeArtist.fromYTMusicResult(result));
            }
            break;
          case 'playlist':
          case 'playlists':
            if (result['playlistId'] != null || result['browseId'] != null) {
              playlists.add(YouTubePlaylist.fromYTMusicResult(result));
            }
            break;
        }
      }
    }

    return YouTubeSearchResult(
      songs: songs,
      albums: albums,
      artists: artists,
      playlists: playlists,
      query: query,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'songs': songs.map((s) => s.toJson()).toList(),
      'albums': albums.map((a) => a.toJson()).toList(),
      'artists': artists.map((a) => a.toJson()).toList(),
      'playlists': playlists.map((p) => p.toJson()).toList(),
      'query': query,
    };
  }

  int get totalResults => songs.length + albums.length + artists.length + playlists.length;
  
  bool get isEmpty => totalResults == 0;
  bool get isNotEmpty => totalResults > 0;
}

/// Related content model
class YouTubeRelatedContent {
  final List<YouTubeSong> songs;
  final List<YouTubeAlbum> albums;
  final List<YouTubeArtist> artists;

  YouTubeRelatedContent({
    this.songs = const [],
    this.albums = const [],
    this.artists = const [],
  });
}

/// Song model
class YouTubeSong {
  final String id;
  final String title;
  final String artist;
  final List<YouTubeArtist> artists;
  final String thumbnailUrl;
  final YouTubeAlbum? album;
  final Duration? duration;

  YouTubeSong({
    required this.id,
    required this.title,
    required this.artist,
    List<YouTubeArtist>? artists,
    required this.thumbnailUrl,
    this.album,
    this.duration,
  }) : artists =
           artists ?? [YouTubeArtist(id: '', name: artist, thumbnailUrl: null)];

  /// Factory constructor for ytmusicapi_dart search results
  factory YouTubeSong.fromYTMusicResult(Map<String, dynamic> json) {
    final thumbnails = json['thumbnails'] as List<dynamic>? ?? [];
    final thumbnailUrl = thumbnails.isNotEmpty 
        ? thumbnails.last['url'] as String? ?? ''
        : '';

    final artistsData = json['artists'] as List<dynamic>? ?? [];
    final artists = artistsData
        .map((artist) => YouTubeArtist.fromYTMusicResult(artist))
        .toList();

    final durationText = json['duration_seconds'];
    Duration? duration;
    if (durationText != null) {
      final seconds = int.tryParse(durationText.toString());
      if (seconds != null) {
        duration = Duration(seconds: seconds);
      }
    }

    return YouTubeSong(
      id: json['videoId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      artist: artists.isNotEmpty ? artists.first.name : 'Unknown Artist',
      artists: artists,
      thumbnailUrl: thumbnailUrl,
      duration: duration,
    );
  }

  factory YouTubeSong.fromJson(Map<String, dynamic> json) {
    final artistsData = json['artists'] as List<dynamic>? ?? [];
    final artists = artistsData
        .map((artist) => YouTubeArtist.fromJson(artist))
        .toList();

    final durationSeconds = json['duration'] as int?;
    Duration? duration;
    if (durationSeconds != null) {
      duration = Duration(seconds: durationSeconds);
    }

    YouTubeAlbum? album;
    if (json['album'] != null) {
      album = YouTubeAlbum.fromJson(json['album']);
    }

    return YouTubeSong(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      artist: json['artist'] as String? ?? '',
      artists: artists,
      thumbnailUrl: json['thumbnailUrl'] as String? ?? '',
      album: album,
      duration: duration,
    );
  }

  /// Convenience getter for video ID (used by InnerTube)
  String get videoId => id;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'artists': artists.map((a) => a.toJson()).toList(),
      'thumbnailUrl': thumbnailUrl,
      'album': album?.toJson(),
      'duration': duration?.inSeconds,
    };
  }
}

/// Streaming data model
class YouTubeStreamingData {
  final String videoId;
  final String? audioUrl;
  final String? videoUrl;
  final int? bitrate;
  final String? mimeType;

  YouTubeStreamingData({
    required this.videoId,
    this.audioUrl,
    this.videoUrl,
    this.bitrate,
    this.mimeType,
  });
}

/// Album model
class YouTubeAlbum {
  final String id;
  final String title;
  final String? artist;
  final List<YouTubeArtist> artists;
  final String? thumbnailUrl;
  final String year;

  YouTubeAlbum({
    required this.id,
    required this.title,
    this.artist,
    List<YouTubeArtist>? artists,
    this.thumbnailUrl,
    this.year = '',
  }) : artists =
           artists ??
           (artist != null
               ? [YouTubeArtist(id: '', name: artist, thumbnailUrl: null)]
               : []);

  /// Factory constructor for ytmusicapi_dart search results
  factory YouTubeAlbum.fromYTMusicResult(Map<String, dynamic> json) {
    final thumbnails = json['thumbnails'] as List<dynamic>? ?? [];
    final thumbnailUrl = thumbnails.isNotEmpty 
        ? thumbnails.last['url'] as String? ?? ''
        : '';

    final artistsData = json['artists'] as List<dynamic>? ?? [];
    final artists = artistsData
        .map((artist) => YouTubeArtist.fromYTMusicResult(artist))
        .toList();

    return YouTubeAlbum(
      id: json['browseId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      artist: artists.isNotEmpty ? artists.first.name : null,
      artists: artists,
      thumbnailUrl: thumbnailUrl.isEmpty ? null : thumbnailUrl,
      year: json['year'] as String? ?? '',
    );
  }

  factory YouTubeAlbum.fromJson(Map<String, dynamic> json) {
    final artistsData = json['artists'] as List<dynamic>? ?? [];
    final artists = artistsData
        .map((artist) => YouTubeArtist.fromJson(artist))
        .toList();

    return YouTubeAlbum(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      artist: json['artist'] as String?,
      artists: artists,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      year: json['year'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'artists': artists.map((a) => a.toJson()).toList(),
      'thumbnailUrl': thumbnailUrl,
      'year': year,
    };
  }
}

/// Artist model
class YouTubeArtist {
  final String id;
  final String name;
  final String? thumbnailUrl;
  final String subscriberCount;

  YouTubeArtist({
    required this.id, 
    required this.name, 
    this.thumbnailUrl,
    this.subscriberCount = '',
  });

  /// Factory constructor for ytmusicapi_dart search results
  factory YouTubeArtist.fromYTMusicResult(Map<String, dynamic> json) {
    final thumbnails = json['thumbnails'] as List<dynamic>? ?? [];
    final thumbnailUrl = thumbnails.isNotEmpty 
        ? thumbnails.last['url'] as String? ?? ''
        : '';

    return YouTubeArtist(
      id: json['browseId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      thumbnailUrl: thumbnailUrl.isEmpty ? null : thumbnailUrl,
      subscriberCount: json['subscribers'] as String? ?? '',
    );
  }

  factory YouTubeArtist.fromJson(Map<String, dynamic> json) {
    return YouTubeArtist(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      thumbnailUrl: json['thumbnailUrl'] as String?,
      subscriberCount: json['subscriberCount'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'thumbnailUrl': thumbnailUrl,
      'subscriberCount': subscriberCount,
    };
  }
}

/// Playlist model
class YouTubePlaylist {
  final String id;
  final String name;
  final String? description;
  final int? trackCount;
  final String? thumbnailUrl;
  final String? author;
  
  // Alias getters for compatibility
  String get title => name;
  int? get videoCount => trackCount;

  YouTubePlaylist({
    required this.id,
    required this.name,
    this.description,
    this.trackCount,
    this.thumbnailUrl,
    this.author,
  });

  factory YouTubePlaylist.fromYTMusicResult(Map<String, dynamic> json) {
    // Extract thumbnail URL from nested structure
    String? thumbnailUrl;
    if (json['thumbnails'] != null && (json['thumbnails'] as List).isNotEmpty) {
      final thumbnails = json['thumbnails'] as List;
      final thumbnail = thumbnails.isNotEmpty ? thumbnails.first : null;
      thumbnailUrl = thumbnail?['url'];
    }

    return YouTubePlaylist(
      id: json['playlistId'] ?? json['browseId'] ?? '',
      name: json['title'] ?? '',
      description: json['description'],
      trackCount: json['count'] is int ? json['count'] : 
                   (json['count'] is String ? int.tryParse(json['count'].replaceAll(RegExp(r'[^\d]'), '')) : null),
      thumbnailUrl: thumbnailUrl,
      author: json['author']?['name'] ?? json['author'],
    );
  }

  factory YouTubePlaylist.fromJson(Map<String, dynamic> json) {
    return YouTubePlaylist(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      trackCount: json['trackCount'] as int?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      author: json['author'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'trackCount': trackCount,
      'thumbnailUrl': thumbnailUrl,
      'author': author,
    };
  }
}

/// YouTube client configuration following InnerTune patterns
class YouTubeClient {
  final String clientName;
  final String clientVersion;
  final String apiKey;
  final String userAgent;
  final String? osVersion;
  final String? referer;

  const YouTubeClient({
    required this.clientName,
    required this.clientVersion,
    required this.apiKey,
    required this.userAgent,
    this.osVersion,
    this.referer,
  });
}

/// Exception class for YouTube Music API errors
class YouTubeMusicException implements Exception {
  final String message;
  YouTubeMusicException(this.message);

  @override
  String toString() => 'YouTubeMusicException: $message';
}

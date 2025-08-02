# YouTube Music Authentication Implementation Guide

## Option 1: Official YouTube Data API v3 with OAuth2 (Recommended)

### Required Dependencies
```yaml
dependencies:
  google_sign_in: ^6.2.1
  googleapis: ^13.2.0
  googleapis_auth: ^1.6.0
  http: ^1.2.1
```

### Implementation Steps

#### 1. Google Cloud Console Setup
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing one
3. Enable YouTube Data API v3
4. Create OAuth2 credentials:
   - Application type: Mobile app (for Flutter)
   - Download the configuration files

#### 2. Flutter Configuration

**android/app/src/main/res/values/strings.xml:**
```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="default_web_client_id">YOUR_WEB_CLIENT_ID</string>
</resources>
```

**ios/Runner/Info.plist:**
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>REVERSED_CLIENT_ID</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>YOUR_REVERSED_CLIENT_ID</string>
        </array>
    </dict>
</array>
```

#### 3. Authentication Service Implementation

```dart
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/youtube/v3.dart';
import 'package:googleapis_auth/googleapis_auth.dart';

class YouTubeAuthService {
  static const List<String> _scopes = [
    'https://www.googleapis.com/auth/youtube.readonly',
    'https://www.googleapis.com/auth/youtube.upload',
    'https://www.googleapis.com/auth/youtubepartner',
  ];

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: _scopes,
  );

  YoutubeApi? _youtubeApi;
  GoogleSignInAccount? _currentUser;

  // Sign in and get authenticated API client
  Future<bool> signIn() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account != null) {
        _currentUser = account;
        final GoogleSignInAuthentication auth = await account.authentication;
        
        final AccessCredentials credentials = AccessCredentials(
          AccessToken('Bearer', auth.accessToken!, DateTime.now().add(Duration(hours: 1))),
          auth.idToken,
          _scopes,
        );

        final AuthClient authClient = authenticatedClient(
          http.Client(),
          credentials,
        );

        _youtubeApi = YoutubeApi(authClient);
        return true;
      }
      return false;
    } catch (error) {
      print('Sign in failed: $error');
      return false;
    }
  }

  // Get user's playlists
  Future<List<Playlist>> getUserPlaylists() async {
    if (_youtubeApi == null) throw Exception('Not authenticated');
    
    final response = await _youtubeApi!.playlists.list(
      ['snippet', 'contentDetails'],
      mine: true,
      maxResults: 50,
    );
    
    return response.items?.toList() ?? [];
  }

  // Get user's liked videos
  Future<List<Video>> getLikedVideos() async {
    if (_youtubeApi == null) throw Exception('Not authenticated');
    
    // Get the 'Liked videos' playlist
    final channelsResponse = await _youtubeApi!.channels.list(
      ['contentDetails'],
      mine: true,
    );
    
    final likedPlaylistId = channelsResponse.items?.first.contentDetails?.relatedPlaylists?.likes;
    
    if (likedPlaylistId != null) {
      final playlistResponse = await _youtubeApi!.playlistItems.list(
        ['snippet'],
        playlistId: likedPlaylistId,
        maxResults: 50,
      );
      
      final videoIds = playlistResponse.items
          ?.map((item) => item.snippet?.resourceId?.videoId)
          .where((id) => id != null)
          .toList() ?? [];
      
      if (videoIds.isNotEmpty) {
        final videosResponse = await _youtubeApi!.videos.list(
          ['snippet', 'contentDetails'],
          id: videoIds,
        );
        return videosResponse.items?.toList() ?? [];
      }
    }
    
    return [];
  }

  // Get user's subscriptions
  Future<List<Subscription>> getUserSubscriptions() async {
    if (_youtubeApi == null) throw Exception('Not authenticated');
    
    final response = await _youtubeApi!.subscriptions.list(
      ['snippet'],
      mine: true,
      maxResults: 50,
    );
    
    return response.items?.toList() ?? [];
  }

  // Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
    _youtubeApi = null;
  }

  bool get isSignedIn => _currentUser != null;
  GoogleSignInAccount? get currentUser => _currentUser;
}
```

#### 4. Integration with Existing Models

Create a bridge service to convert YouTube API data to your existing models:

```dart
class YouTubePersonalDataService {
  final YouTubeAuthService _authService = YouTubeAuthService();

  Future<bool> authenticate() => _authService.signIn();

  Future<List<YouTubeSong>> getPersonalLikedSongs() async {
    final likedVideos = await _authService.getLikedVideos();
    return likedVideos.map((video) => YouTubeSong(
      id: video.id!,
      title: video.snippet?.title ?? 'Unknown',
      artist: video.snippet?.channelTitle ?? 'Unknown',
      thumbnailUrl: video.snippet?.thumbnails?.medium?.url ?? '',
      duration: _parseDuration(video.contentDetails?.duration),
    )).toList();
  }

  Future<List<YouTubePlaylist>> getPersonalPlaylists() async {
    final playlists = await _authService.getUserPlaylists();
    return playlists.map((playlist) => YouTubePlaylist(
      id: playlist.id!,
      title: playlist.snippet?.title ?? 'Unknown',
      thumbnailUrl: playlist.snippet?.thumbnails?.medium?.url,
      author: playlist.snippet?.channelTitle,
      songCount: playlist.contentDetails?.itemCount,
    )).toList();
  }

  Duration? _parseDuration(String? isoDuration) {
    if (isoDuration == null) return null;
    // Parse ISO 8601 duration format (PT4M13S)
    final RegExp regex = RegExp(r'PT(?:(\d+)M)?(?:(\d+)S)?');
    final match = regex.firstMatch(isoDuration);
    if (match != null) {
      final minutes = int.tryParse(match.group(1) ?? '0') ?? 0;
      final seconds = int.tryParse(match.group(2) ?? '0') ?? 0;
      return Duration(minutes: minutes, seconds: seconds);
    }
    return null;
  }
}
```

### Benefits:
- ✅ Access to personal data (playlists, liked songs, subscriptions)
- ✅ Official Google API with proper authentication
- ✅ No API key limits for personal data
- ✅ Secure OAuth2 flow
- ✅ Maintains user privacy

### Limitations:
- ❌ Requires user to sign in with Google account
- ❌ Limited to YouTube Data API capabilities (no direct YouTube Music API)
- ❌ Some YouTube Music specific features not available

## Option 2: Hybrid Approach (Recommended for Your Use Case)

Combine both approaches:
1. Use `youtube_explode_dart` for general music discovery and streaming
2. Use YouTube Data API for personal data when user is authenticated

```dart
class HybridYouTubeMusicService {
  final YouTubeMusicService _publicService = YouTubeMusicService();
  final YouTubePersonalDataService _personalService = YouTubePersonalDataService();

  // Public search (no auth required)
  Future<YouTubeSearchResult> search(String query) => _publicService.search(query);

  // Streaming (no auth required)
  Future<YouTubeStreamingData> getStreamingData(String videoId) => 
      _publicService.getStreamingData(videoId);

  // Personal data (auth required)
  Future<List<YouTubeSong>> getPersonalLikedSongs() async {
    if (!await _personalService.authenticate()) {
      throw Exception('Authentication required');
    }
    return _personalService.getPersonalLikedSongs();
  }

  Future<List<YouTubePlaylist>> getPersonalPlaylists() async {
    if (!await _personalService.authenticate()) {
      throw Exception('Authentication required');
    }
    return _personalService.getPersonalPlaylists();
  }
}
```

This gives you the best of both worlds - public content access without authentication, and personal data access when the user chooses to sign in.

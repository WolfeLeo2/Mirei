import 'package:realm/realm.dart';
import 'dart:convert';

part 'realm_models.realm.dart';

// Plain data class for audio recordings (not a Realm model)
class AudioRecordingData {
  final String path;
  final Duration duration;
  final DateTime timestamp;

  AudioRecordingData({
    required this.path,
    required this.duration,
    required this.timestamp,
  });

  String toJson() {
    return jsonEncode({
      'path': path,
      'duration': duration.inMilliseconds,
      'timestamp': timestamp.toIso8601String(),
    });
  }

  factory AudioRecordingData.fromJson(String jsonString) {
    final data = jsonDecode(jsonString);
    return AudioRecordingData(
      path: data['path'],
      duration: Duration(milliseconds: data['duration']),
      timestamp: DateTime.parse(data['timestamp']),
    );
  }
}

@RealmModel()
class _UserProfileRealm {
  @PrimaryKey()
  late String uid; // Firebase UID as primary key

  late String email;
  String? displayName;
  String? photoURL; // Firebase profile picture URL
  String? customAvatarUrl; // User-selected custom avatar
  late String provider; // 'google', 'facebook', 'apple', 'email'
  late bool isEmailVerified;
  late DateTime lastUpdated;
  late DateTime createdAt;

  // Helper method to get effective avatar URL
  String get effectiveAvatarUrl {
    if (customAvatarUrl != null && customAvatarUrl!.isNotEmpty) {
      return customAvatarUrl!;
    }
    if (photoURL != null && photoURL!.isNotEmpty) {
      return photoURL!;
    }
    // Generate default avatar based on UID
    final seed = uid.hashCode.abs();
    return 'https://api.dicebear.com/7.x/avataaars/png?seed=$seed&size=150';
  }

  // Helper method to get effective display name
  String get effectiveDisplayName {
    if (displayName != null && displayName!.isNotEmpty) {
      return displayName!;
    }
    // Extract name from email (before @)
    return email.split('@').first.replaceAll('.', ' ').trim();
  }
}

@RealmModel()
class _MoodEntryRealm {
  @PrimaryKey()
  late ObjectId id;

  late String mood;
  @Indexed() // Index for date-based queries (most common query pattern)
  late DateTime createdAt;
  String? note;
}

@RealmModel()
class _JournalEntryRealm {
  @PrimaryKey()
  late ObjectId id;

  late String title;
  late String content;
  @Indexed() // Index for date-based queries and sorting
  late DateTime createdAt;
  // Removed mood field - moods are stored separately in MoodEntryRealm

  // Store image paths as a single string with delimiter
  String? imagePathsString;

  // Store audio recordings as JSON string
  String? audioRecordingsString;

  // Helper getters/setters for backward compatibility
  List<String> get imagePaths {
    if (imagePathsString == null || imagePathsString!.isEmpty) return [];
    return imagePathsString!.split('|||');
  }

  set imagePaths(List<String> paths) {
    imagePathsString = paths.join('|||');
  }

  List<AudioRecordingData> get audioRecordings {
    if (audioRecordingsString == null || audioRecordingsString!.isEmpty)
      return [];
    return audioRecordingsString!
        .split('|||')
        .where((s) => s.isNotEmpty)
        .map((s) => AudioRecordingData.fromJson(s))
        .toList();
  }

  set audioRecordings(List<AudioRecordingData> recordings) {
    audioRecordingsString = recordings.map((r) => r.toJson()).join('|||');
  }
}

// Cache models for audio streaming
@RealmModel()
class _AudioCacheEntry {
  @PrimaryKey()
  late String url; // URL is the primary key

  late String localPath; // Local file path
  late DateTime cachedAt;
  @Indexed() // Index for LRU cache cleanup queries
  late DateTime lastAccessed;
  late int sizeBytes;
  String? mimeType;
  late int accessCount;
  late bool isComplete; // Whether the file is fully downloaded
}

// Predictive caching for playlist items
@RealmModel()
class _PlaylistCacheEntry {
  @PrimaryKey()
  late ObjectId id;

  @Indexed() // Index for playlist-based queries
  late String playlistId; // Identifier for the playlist
  late String songUrl;
  late int priority; // 1 = next song, 2 = second next, etc.
  late DateTime createdAt;
  @Indexed() // Index for TTL cleanup queries
  late DateTime expiresAt; // TTL for playlist entries
  late bool isPreloaded;
}

// Playlist JSON data cache with TTL
@RealmModel()
class _PlaylistData {
  @PrimaryKey()
  late String playlistUrl; // URL/key for the playlist

  late String jsonData; // JSON string of the playlist
  late DateTime cachedAt;
  @Indexed() // Index for TTL cleanup queries
  late DateTime expiresAt; // TTL for playlist JSON
  late int trackCount;
  String? title;
}

// Network request cache for metadata
@RealmModel()
class _HttpCacheEntry {
  @PrimaryKey()
  late String key; // Hash of URL + headers

  late String responseBody;
  late DateTime cachedAt;
  @Indexed() // Index for TTL cleanup queries
  late DateTime expiresAt;
  late int statusCode;
  String? contentType;
}

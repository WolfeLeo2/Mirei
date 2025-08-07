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
class _MoodEntryRealm {
  @PrimaryKey()
  late ObjectId id;
  
  late String mood;
  late DateTime createdAt;
  String? note;
}

@RealmModel()
class _JournalEntryRealm {
  @PrimaryKey()
  late ObjectId id;
  
  late String title;
  late String content;
  late DateTime createdAt;
  String? mood;
  
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
    if (audioRecordingsString == null || audioRecordingsString!.isEmpty) return [];
    return audioRecordingsString!.split('|||')
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
  
  late String playlistId; // Identifier for the playlist
  late String songUrl;
  late int priority; // 1 = next song, 2 = second next, etc.
  late DateTime createdAt;
  late bool isPreloaded;
}

// Network request cache for metadata
@RealmModel()
class _HttpCacheEntry {
  @PrimaryKey()
  late String key; // Hash of URL + headers
  
  late String responseBody;
  late DateTime cachedAt;
  late DateTime expiresAt;
  late int statusCode;
  String? contentType;
}

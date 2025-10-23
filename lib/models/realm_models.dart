import 'package:realm/realm.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

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
      'timestamp': timestamp.millisecondsSinceEpoch,
    });
  }

  factory AudioRecordingData.fromJson(String jsonString) {
    try {
      final data = jsonDecode(jsonString);
      return AudioRecordingData(
        path: data['path'] ?? '',
        duration: Duration(milliseconds: data['duration'] ?? 0),
        timestamp: data['timestamp'] != null && data['timestamp'] != 0
            ? DateTime.fromMillisecondsSinceEpoch(data['timestamp'])
            : DateTime.now(),
      );
    } catch (e) {
      debugPrint('Error parsing AudioRecordingData JSON: $e');
      // Return a default/fallback audio recording
      return AudioRecordingData(
        path: '',
        duration: Duration.zero,
        timestamp: DateTime.now(),
      );
    }
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

  // Enhanced mood tracking fields (backward compatible)
  int? intensity; // 1-10 scale (null = not set for existing entries)
  String? context; // "Why do you feel this way?"
  String? triggers; // "work,social,health" (comma-separated)
  String? activities; // "exercise,meditation,socializing"
  String? location; // "home,work,outdoors"
  String? checkInType; // "morning,afternoon,evening,manual"
  int? sequenceNumber; // 1st, 2nd, 3rd entry of the day
}

@RealmModel()
class _JournalEntryRealm {
  @PrimaryKey()
  late ObjectId id;

  late String title;
  late String content;
  @Indexed() // Index for date-based queries and sorting
  late DateTime createdAt;

  // Store image paths as a single string with delimiter
  String? imagePathsString;

  // Store audio recordings as JSON string
  String? audioRecordingsString;

  // Journal-specific mood context (separate from daily mood tracking)
  String? entryMood; // Mood while writing this specific entry
  int? entryMoodIntensity; // Intensity (1-10) while writing
  String? entryMoodContext; // Why you felt this way while writing

  // Helper getters/setters
  List<String> get imagePaths {
    if (imagePathsString == null || imagePathsString!.isEmpty) return [];
    try {
      final raw = imagePathsString!;
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .map((e) => e?.toString() ?? '')
            .where((e) => e.isNotEmpty)
            .toList();
      }
      return [];
    } catch (_) {
      // Fallback to empty on parse errors
      return [];
    }
  }

  set imagePaths(List<String> paths) {
    // Store as JSON array for future-proofing
    imagePathsString = jsonEncode(paths);
  }

  List<AudioRecordingData> get audioRecordings {
    if (audioRecordingsString == null || audioRecordingsString!.isEmpty) {
      return [];
    }
    try {
      final decoded = jsonDecode(audioRecordingsString!);
      if (decoded is List) {
        return decoded
            .map(
              (e) => e is String
                  ? AudioRecordingData.fromJson(e)
                  : AudioRecordingData.fromJson(jsonEncode(e)),
            )
            .whereType<AudioRecordingData>()
            .where((audio) => audio.path.isNotEmpty)
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error parsing audio recordings: $e');
      return [];
    }
  }

  set audioRecordings(List<AudioRecordingData> recordings) {
    audioRecordingsString = jsonEncode(
      recordings.map((r) => jsonDecode(r.toJson())).toList(),
    );
  }
}

@RealmModel()
class _MemoryEntryRealm {
  @PrimaryKey()
  late ObjectId id;

  @Indexed()
  late DateTime createdAt;

  String? caption;
  String? imagePathsString;

  List<String> get imagePaths {
    if (imagePathsString == null || imagePathsString!.isEmpty) {
      return [];
    }
    try {
      final decoded = jsonDecode(imagePathsString!);
      if (decoded is List) {
        return decoded
            .map((e) => e?.toString() ?? '')
            .where((e) => e.isNotEmpty)
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  set imagePaths(List<String> paths) {
    imagePathsString = jsonEncode(paths);
  }
}

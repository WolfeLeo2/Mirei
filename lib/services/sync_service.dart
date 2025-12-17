import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:realm/realm.dart';

import '../models/realm_models.dart';
import '../utils/realm_database_helper.dart';
import 'supabase_service.dart';

class SyncService {
  static SyncService? _instance;
  static SyncService get instance => _instance ??= SyncService._();

  SyncService._();

  final SupabaseService _supabase = SupabaseService.instance;
  final RealmDatabaseHelper _dbHelper = RealmDatabaseHelper();

  bool _isSyncing = false;
  DateTime? _lastSyncTime;

  /// Check if device has internet connection
  Future<bool> hasInternetConnection() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  /// Sync all data (called on app start or manual sync)
  Future<void> syncAll() async {
    if (_isSyncing) {
      if (kDebugMode) {
        debugPrint('Sync: Already syncing, skipping');
      }
      return;
    }

    if (!await hasInternetConnection()) {
      if (kDebugMode) {
        debugPrint('Sync: No internet connection, skipping');
      }
      return;
    }

    if (!_supabase.isAuthenticated) {
      if (kDebugMode) {
        debugPrint('Sync: User not authenticated, skipping');
      }
      return;
    }

    _isSyncing = true;
    try {
      if (kDebugMode) {
        debugPrint('Sync: Starting full sync');
      }

      // Sync in order: Profile -> Moods -> Journals -> Memories
      await syncUserProfile();
      await syncMoodEntries();
      await syncJournalEntries();
      await syncMemoryEntries();

      _lastSyncTime = DateTime.now();
      if (kDebugMode) {
        debugPrint('Sync: Completed successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Sync: Error: $e');
      }
    } finally {
      _isSyncing = false;
    }
  }

  /// Sync user profile
  Future<void> syncUserProfile() async {
    try {
      final userId = _supabase.currentUserId;
      if (userId == null) return;

      // Fetch from Supabase
      final data = await _supabase.client
          .from('user_profiles')
          .select()
          .eq('uid', userId)
          .maybeSingle();

      if (data != null) {
        // Update local Realm
        final realm = await _dbHelper.realm;
        realm.write(() {
          realm.add(
            UserProfileRealm(
              data['uid'] as String,
              data['email'] as String,
              data['provider'] as String? ?? 'email',
              data['is_email_verified'] as bool? ?? false,
              DateTime.parse(data['updated_at'] as String),
              DateTime.parse(data['created_at'] as String),
              displayName: data['display_name'] as String?,
              photoURL: data['photo_url'] as String?,
              customAvatarUrl: data['custom_avatar_url'] as String?,
            ),
            update: true,
          );
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Sync: Error syncing user profile: $e');
      }
    }
  }

  /// Sync mood entries (bidirectional)
  Future<void> syncMoodEntries() async {
    try {
      final userId = _supabase.currentUserId;
      if (userId == null) return;

      final realm = await _dbHelper.realm;

      // STEP 1: Upload local entries that need syncing
      final unsyncedLocal = realm.query<MoodEntryRealm>(
        'syncedAt == nil OR lastModified > syncedAt',
      );

      for (final entry in unsyncedLocal) {
        try {
          // Check if entry already exists remotely (has remoteId)
          if (entry.remoteId != null) {
            // Update existing remote entry
            await _supabase.client
                .from('mood_entries')
                .update({
                  'mood': entry.mood,
                  'created_at': entry.createdAt.toIso8601String(),
                  'note': entry.note,
                  'intensity': entry.intensity,
                  'context': entry.context,
                  'triggers': entry.triggers,
                  'activities': entry.activities,
                  'location': entry.location,
                  'check_in_type': entry.checkInType,
                  'sequence_number': entry.sequenceNumber,
                  'last_modified': entry.lastModified.toIso8601String(),
                })
                .eq('id', entry.remoteId!);

            if (kDebugMode) {
              debugPrint('Sync: Updated mood entry ${entry.remoteId}');
            }
          } else {
            // Insert new remote entry
            final response = await _supabase.client
                .from('mood_entries')
                .insert({
                  'user_id': userId,
                  'mood': entry.mood,
                  'created_at': entry.createdAt.toIso8601String(),
                  'note': entry.note,
                  'intensity': entry.intensity,
                  'context': entry.context,
                  'triggers': entry.triggers,
                  'activities': entry.activities,
                  'location': entry.location,
                  'check_in_type': entry.checkInType,
                  'sequence_number': entry.sequenceNumber,
                  'last_modified': entry.lastModified.toIso8601String(),
                })
                .select('id')
                .single();

            // Update local entry with remote ID
            realm.write(() {
              entry.remoteId = response['id'] as String;
              entry.syncedAt = DateTime.now();
            });

            if (kDebugMode) {
              debugPrint('Sync: Uploaded new mood entry ${response['id']}');
            }
          }

          // Mark as synced
          realm.write(() {
            entry.syncedAt = DateTime.now();
          });
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Sync: Error uploading mood entry: $e');
          }
        }
      }

      // STEP 2: Download remote entries and merge with local
      final remoteEntries = await _supabase.client
          .from('mood_entries')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      for (final remoteEntry in remoteEntries) {
        final remoteId = remoteEntry['id'] as String;
        final remoteMood = remoteEntry['mood'] as String;
        final remoteCreatedAt = DateTime.parse(
          remoteEntry['created_at'] as String,
        );
        final remoteModified = remoteEntry['last_modified'] != null
            ? DateTime.parse(remoteEntry['last_modified'] as String)
            : remoteCreatedAt;

        // Check if we already have this entry locally
        final localEntry = realm.query<MoodEntryRealm>('remoteId == \$0', [
          remoteId,
        ]).firstOrNull;

        if (localEntry == null) {
          // New remote entry - download it
          realm.write(() {
            realm.add(
              MoodEntryRealm(
                  ObjectId(),
                  remoteMood,
                  remoteCreatedAt,
                  remoteModified, // lastModified parameter
                  note: remoteEntry['note'] as String?,
                  intensity: remoteEntry['intensity'] as int?,
                  context: remoteEntry['context'] as String?,
                  triggers: remoteEntry['triggers'] as String?,
                  activities: remoteEntry['activities'] as String?,
                  location: remoteEntry['location'] as String?,
                  checkInType: remoteEntry['check_in_type'] as String?,
                  sequenceNumber: remoteEntry['sequence_number'] as int?,
                )
                ..remoteId = remoteId
                ..syncedAt = DateTime.now(),
            );
          });

          if (kDebugMode) {
            debugPrint('Sync: Downloaded new mood entry $remoteId');
          }
        } else {
          // Entry exists locally - check for conflicts
          if (remoteModified.isAfter(localEntry.lastModified)) {
            // Remote is newer - update local (last-write-wins)
            realm.write(() {
              localEntry.mood = remoteMood;
              localEntry.createdAt = remoteCreatedAt;
              localEntry.note = remoteEntry['note'] as String?;
              localEntry.intensity = remoteEntry['intensity'] as int?;
              localEntry.context = remoteEntry['context'] as String?;
              localEntry.triggers = remoteEntry['triggers'] as String?;
              localEntry.activities = remoteEntry['activities'] as String?;
              localEntry.location = remoteEntry['location'] as String?;
              localEntry.checkInType = remoteEntry['check_in_type'] as String?;
              localEntry.sequenceNumber =
                  remoteEntry['sequence_number'] as int?;
              localEntry.lastModified = remoteModified;
              localEntry.syncedAt = DateTime.now();
            });

            if (kDebugMode) {
              debugPrint(
                'Sync: Updated local mood entry from remote $remoteId',
              );
            }
          }
        }
      }

      if (kDebugMode) {
        debugPrint('Sync: Mood entries synced successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Sync: Error syncing mood entries: $e');
      }
    }
  }

  /// Sync journal entries (bidirectional)
  Future<void> syncJournalEntries() async {
    try {
      final userId = _supabase.currentUserId;
      if (userId == null) return;

      final realm = await _dbHelper.realm;

      // STEP 1: Upload local entries that need syncing
      final unsyncedLocal = realm.query<JournalEntryRealm>(
        'syncedAt == nil OR lastModified > syncedAt',
      );

      for (final entry in unsyncedLocal) {
        try {
          // Upload images to storage
          final uploadedImagePaths = <String>[];
          for (final imagePath in entry.imagePaths) {
            final file = File(imagePath);
            if (await file.exists()) {
              final remotePath = await _supabase.uploadFile(
                bucket: 'journal-images',
                path: '$userId/${entry.id.hexString}',
                file: file,
              );
              uploadedImagePaths.add(remotePath);
            }
          }

          // Upload audio recordings
          final uploadedAudioPaths = <Map<String, dynamic>>[];
          for (final audio in entry.audioRecordings) {
            final file = File(audio.path);
            if (await file.exists()) {
              final remotePath = await _supabase.uploadFile(
                bucket: 'journal-audio',
                path: '$userId/${entry.id.hexString}',
                file: file,
              );
              uploadedAudioPaths.add({
                'path': remotePath,
                'duration': audio.duration.inMilliseconds,
                'timestamp': audio.timestamp.millisecondsSinceEpoch,
              });
            }
          }

          if (entry.remoteId != null) {
            // Update existing remote entry
            await _supabase.client
                .from('journal_entries')
                .update({
                  'title': entry.title,
                  'content': entry.content,
                  'created_at': entry.createdAt.toIso8601String(),
                  'image_paths': jsonEncode(uploadedImagePaths),
                  'audio_recordings': jsonEncode(uploadedAudioPaths),
                  'entry_mood': entry.entryMood,
                  'entry_mood_intensity': entry.entryMoodIntensity,
                  'entry_mood_context': entry.entryMoodContext,
                  'last_modified': entry.lastModified.toIso8601String(),
                })
                .eq('id', entry.remoteId!);

            if (kDebugMode) {
              debugPrint('Sync: Updated journal entry ${entry.remoteId}');
            }
          } else {
            // Insert new remote entry
            final response = await _supabase.client
                .from('journal_entries')
                .insert({
                  'user_id': userId,
                  'title': entry.title,
                  'content': entry.content,
                  'created_at': entry.createdAt.toIso8601String(),
                  'image_paths': jsonEncode(uploadedImagePaths),
                  'audio_recordings': jsonEncode(uploadedAudioPaths),
                  'entry_mood': entry.entryMood,
                  'entry_mood_intensity': entry.entryMoodIntensity,
                  'entry_mood_context': entry.entryMoodContext,
                  'last_modified': entry.lastModified.toIso8601String(),
                })
                .select('id')
                .single();

            realm.write(() {
              entry.remoteId = response['id'] as String;
              entry.syncedAt = DateTime.now();
            });

            if (kDebugMode) {
              debugPrint('Sync: Uploaded new journal entry ${response['id']}');
            }
          }

          // Mark as synced
          realm.write(() {
            entry.syncedAt = DateTime.now();
          });
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Sync: Error uploading journal entry: $e');
          }
        }
      }

      // STEP 2: Download remote entries and merge with local
      final remoteEntries = await _supabase.client
          .from('journal_entries')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      for (final remoteEntry in remoteEntries) {
        final remoteId = remoteEntry['id'] as String;
        final remoteModified = remoteEntry['last_modified'] != null
            ? DateTime.parse(remoteEntry['last_modified'] as String)
            : DateTime.parse(remoteEntry['created_at'] as String);

        // Check if we already have this entry locally
        final localEntry = realm.query<JournalEntryRealm>('remoteId == \$0', [
          remoteId,
        ]).firstOrNull;

        if (localEntry == null) {
          // New remote entry - download it
          // Download media files locally
          final localImagePaths = await _downloadMediaFiles(
            remoteEntry['image_paths'] as String?,
            'journal-images',
          );

          final localAudioData = await _downloadAudioFiles(
            remoteEntry['audio_recordings'] as String?,
            'journal-audio',
          );

          realm.write(() {
            final newEntry = JournalEntryRealm(
              ObjectId(),
              remoteEntry['title'] as String,
              remoteEntry['content'] as String,
              DateTime.parse(remoteEntry['created_at'] as String),
              remoteModified, // lastModified parameter
              entryMood: remoteEntry['entry_mood'] as String?,
              entryMoodIntensity: remoteEntry['entry_mood_intensity'] as int?,
              entryMoodContext: remoteEntry['entry_mood_context'] as String?,
            );
            newEntry.imagePaths = localImagePaths;
            newEntry.audioRecordings = localAudioData;
            newEntry.remoteId = remoteId;
            newEntry.syncedAt = DateTime.now();

            realm.add(newEntry);
          });

          if (kDebugMode) {
            debugPrint('Sync: Downloaded new journal entry $remoteId');
          }
        } else {
          // Entry exists locally - check for conflicts
          if (remoteModified.isAfter(localEntry.lastModified)) {
            // Remote is newer - update local
            final localImagePaths = await _downloadMediaFiles(
              remoteEntry['image_paths'] as String?,
              'journal-images',
            );

            final localAudioData = await _downloadAudioFiles(
              remoteEntry['audio_recordings'] as String?,
              'journal-audio',
            );

            realm.write(() {
              localEntry.title = remoteEntry['title'] as String;
              localEntry.content = remoteEntry['content'] as String;
              localEntry.createdAt = DateTime.parse(
                remoteEntry['created_at'] as String,
              );
              localEntry.imagePaths = localImagePaths;
              localEntry.audioRecordings = localAudioData;
              localEntry.entryMood = remoteEntry['entry_mood'] as String?;
              localEntry.entryMoodIntensity =
                  remoteEntry['entry_mood_intensity'] as int?;
              localEntry.entryMoodContext =
                  remoteEntry['entry_mood_context'] as String?;
              localEntry.lastModified = remoteModified;
              localEntry.syncedAt = DateTime.now();
            });

            if (kDebugMode) {
              debugPrint(
                'Sync: Updated local journal entry from remote $remoteId',
              );
            }
          }
        }
      }

      if (kDebugMode) {
        debugPrint('Sync: Journal entries synced successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Sync: Error syncing journal entries: $e');
      }
    }
  }

  /// Sync memory entries (bidirectional)
  Future<void> syncMemoryEntries() async {
    try {
      final userId = _supabase.currentUserId;
      if (userId == null) return;

      final realm = await _dbHelper.realm;

      // STEP 1: Upload local entries that need syncing
      final unsyncedLocal = realm.query<MemoryEntryRealm>(
        'syncedAt == nil OR lastModified > syncedAt',
      );

      for (final entry in unsyncedLocal) {
        try {
          // Upload media files to storage
          final uploadedMediaPaths = <String>[];
          for (final mediaPath in entry.imagePaths) {
            final file = File(mediaPath);
            if (await file.exists()) {
              final remotePath = await _supabase.uploadFile(
                bucket: 'memory-media',
                path: '$userId/${entry.id.hexString}',
                file: file,
              );
              uploadedMediaPaths.add(remotePath);
            }
          }

          if (entry.remoteId != null) {
            // Update existing remote entry
            await _supabase.client
                .from('memory_entries')
                .update({
                  'created_at': entry.createdAt.toIso8601String(),
                  'caption': entry.caption,
                  'media_paths': jsonEncode(uploadedMediaPaths),
                  'last_modified': entry.lastModified.toIso8601String(),
                })
                .eq('id', entry.remoteId!);

            if (kDebugMode) {
              debugPrint('Sync: Updated memory entry ${entry.remoteId}');
            }
          } else {
            // Insert new remote entry
            final response = await _supabase.client
                .from('memory_entries')
                .insert({
                  'user_id': userId,
                  'created_at': entry.createdAt.toIso8601String(),
                  'caption': entry.caption,
                  'media_paths': jsonEncode(uploadedMediaPaths),
                  'last_modified': entry.lastModified.toIso8601String(),
                })
                .select('id')
                .single();

            realm.write(() {
              entry.remoteId = response['id'] as String;
              entry.syncedAt = DateTime.now();
            });

            if (kDebugMode) {
              debugPrint('Sync: Uploaded new memory entry ${response['id']}');
            }
          }

          // Mark as synced
          realm.write(() {
            entry.syncedAt = DateTime.now();
          });
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Sync: Error uploading memory entry: $e');
          }
        }
      }

      // STEP 2: Download remote entries and merge with local
      final remoteEntries = await _supabase.client
          .from('memory_entries')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      for (final remoteEntry in remoteEntries) {
        final remoteId = remoteEntry['id'] as String;
        final remoteModified = remoteEntry['last_modified'] != null
            ? DateTime.parse(remoteEntry['last_modified'] as String)
            : DateTime.parse(remoteEntry['created_at'] as String);

        // Check if we already have this entry locally
        final localEntry = realm.query<MemoryEntryRealm>('remoteId == \$0', [
          remoteId,
        ]).firstOrNull;

        if (localEntry == null) {
          // New remote entry - download it
          final localMediaPaths = await _downloadMediaFiles(
            remoteEntry['media_paths'] as String?,
            'memory-media',
          );

          realm.write(() {
            final newEntry = MemoryEntryRealm(
              ObjectId(),
              DateTime.parse(remoteEntry['created_at'] as String),
              remoteModified, // lastModified parameter
              caption: remoteEntry['caption'] as String?,
            );
            newEntry.imagePaths = localMediaPaths;
            newEntry.remoteId = remoteId;
            newEntry.syncedAt = DateTime.now();

            realm.add(newEntry);
          });

          if (kDebugMode) {
            debugPrint('Sync: Downloaded new memory entry $remoteId');
          }
        } else {
          // Entry exists locally - check for conflicts
          if (remoteModified.isAfter(localEntry.lastModified)) {
            // Remote is newer - update local
            final localMediaPaths = await _downloadMediaFiles(
              remoteEntry['media_paths'] as String?,
              'memory-media',
            );

            realm.write(() {
              localEntry.createdAt = DateTime.parse(
                remoteEntry['created_at'] as String,
              );
              localEntry.caption = remoteEntry['caption'] as String?;
              localEntry.imagePaths = localMediaPaths;
              localEntry.lastModified = remoteModified;
              localEntry.syncedAt = DateTime.now();
            });

            if (kDebugMode) {
              debugPrint(
                'Sync: Updated local memory entry from remote $remoteId',
              );
            }
          }
        }
      }

      if (kDebugMode) {
        debugPrint('Sync: Memory entries synced successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Sync: Error syncing memory entries: $e');
      }
    }
  }

  /// Upload journal entry to Supabase
  Future<String?> uploadJournalEntry(JournalEntryRealm entry) async {
    try {
      final userId = _supabase.currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      // Upload images to storage
      final uploadedImagePaths = <String>[];
      for (final imagePath in entry.imagePaths) {
        final file = File(imagePath);
        if (await file.exists()) {
          final remotePath = await _supabase.uploadFile(
            bucket: 'journal-images',
            path: 'entries',
            file: file,
          );
          uploadedImagePaths.add(remotePath);
        }
      }

      // Upload audio recordings to storage
      final uploadedAudioPaths = <Map<String, dynamic>>[];
      for (final audio in entry.audioRecordings) {
        final file = File(audio.path);
        if (await file.exists()) {
          final remotePath = await _supabase.uploadFile(
            bucket: 'journal-audio',
            path: 'recordings',
            file: file,
          );
          uploadedAudioPaths.add({
            'path': remotePath,
            'duration': audio.duration.inMilliseconds,
            'timestamp': audio.timestamp.millisecondsSinceEpoch,
          });
        }
      }

      // Insert journal entry
      final response = await _supabase.client
          .from('journal_entries')
          .insert({
            'user_id': userId,
            'title': entry.title,
            'content': entry.content,
            'created_at': entry.createdAt.toIso8601String(),
            'image_paths': jsonEncode(uploadedImagePaths),
            'audio_recordings': jsonEncode(uploadedAudioPaths),
            'entry_mood': entry.entryMood,
            'entry_mood_intensity': entry.entryMoodIntensity,
            'entry_mood_context': entry.entryMoodContext,
          })
          .select('id')
          .single();

      return response['id'] as String;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Sync: Error uploading journal entry: $e');
      }
      return null;
    }
  }

  /// Upload memory entry to Supabase
  Future<String?> uploadMemoryEntry(MemoryEntryRealm entry) async {
    try {
      final userId = _supabase.currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      // Upload media files to storage
      final uploadedMediaPaths = <String>[];
      for (final mediaPath in entry.imagePaths) {
        final file = File(mediaPath);
        if (await file.exists()) {
          final remotePath = await _supabase.uploadFile(
            bucket: 'memory-media',
            path: 'media',
            file: file,
          );
          uploadedMediaPaths.add(remotePath);
        }
      }

      // Insert memory entry
      final response = await _supabase.client
          .from('memory_entries')
          .insert({
            'user_id': userId,
            'created_at': entry.createdAt.toIso8601String(),
            'caption': entry.caption,
            'media_paths': jsonEncode(uploadedMediaPaths),
          })
          .select('id')
          .single();

      return response['id'] as String;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Sync: Error uploading memory entry: $e');
      }
      return null;
    }
  }

  /// Upload mood entry to Supabase
  Future<String?> uploadMoodEntry(MoodEntryRealm entry) async {
    try {
      final userId = _supabase.currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase.client
          .from('mood_entries')
          .insert({
            'user_id': userId,
            'mood': entry.mood,
            'created_at': entry.createdAt.toIso8601String(),
            'note': entry.note,
            'intensity': entry.intensity,
            'context': entry.context,
            'triggers': entry.triggers,
            'activities': entry.activities,
            'location': entry.location,
            'check_in_type': entry.checkInType,
            'sequence_number': entry.sequenceNumber,
          })
          .select('id')
          .single();

      return response['id'] as String;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Sync: Error uploading mood entry: $e');
      }
      return null;
    }
  }

  // HELPER METHODS FOR MEDIA DOWNLOAD

  /// Download media files from Supabase Storage to local device
  Future<List<String>> _downloadMediaFiles(
    String? jsonPaths,
    String bucket,
  ) async {
    if (jsonPaths == null || jsonPaths.isEmpty) return [];

    try {
      final paths = (jsonDecode(jsonPaths) as List).cast<String>();
      final localPaths = <String>[];

      for (final remotePath in paths) {
        try {
          // Download file from Supabase
          final bytes = await _supabase.client.storage
              .from(bucket)
              .download(remotePath);

          // Save to local temp directory
          final directory = await getApplicationDocumentsDirectory();
          final fileName = remotePath.split('/').last;
          final localFile = File('${directory.path}/$bucket/$fileName');

          // Create directory if it doesn't exist
          await localFile.parent.create(recursive: true);

          // Write bytes to file
          await localFile.writeAsBytes(bytes);
          localPaths.add(localFile.path);

          if (kDebugMode) {
            debugPrint('Sync: Downloaded media file $fileName');
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Sync: Error downloading media file $remotePath: $e');
          }
        }
      }

      return localPaths;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Sync: Error parsing media paths: $e');
      }
      return [];
    }
  }

  /// Download audio files from Supabase Storage and reconstruct AudioRecordingData
  Future<List<AudioRecordingData>> _downloadAudioFiles(
    String? jsonAudio,
    String bucket,
  ) async {
    if (jsonAudio == null || jsonAudio.isEmpty) return [];

    try {
      final audioList = (jsonDecode(jsonAudio) as List)
          .cast<Map<String, dynamic>>();
      final localAudioData = <AudioRecordingData>[];

      for (final audioInfo in audioList) {
        try {
          final remotePath = audioInfo['path'] as String;

          // Download file from Supabase
          final bytes = await _supabase.client.storage
              .from(bucket)
              .download(remotePath);

          // Save to local temp directory
          final directory = await getApplicationDocumentsDirectory();
          final fileName = remotePath.split('/').last;
          final localFile = File('${directory.path}/$bucket/$fileName');

          // Create directory if it doesn't exist
          await localFile.parent.create(recursive: true);

          // Write bytes to file
          await localFile.writeAsBytes(bytes);

          // Reconstruct AudioRecordingData
          localAudioData.add(
            AudioRecordingData(
              path: localFile.path,
              duration: Duration(milliseconds: audioInfo['duration'] as int),
              timestamp: DateTime.fromMillisecondsSinceEpoch(
                audioInfo['timestamp'] as int,
              ),
            ),
          );

          if (kDebugMode) {
            debugPrint('Sync: Downloaded audio file $fileName');
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Sync: Error downloading audio file: $e');
          }
        }
      }

      return localAudioData;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Sync: Error parsing audio paths: $e');
      }
      return [];
    }
  }

  /// Get last sync time
  DateTime? get lastSyncTime => _lastSyncTime;

  /// Check if currently syncing
  bool get isSyncing => _isSyncing;
}

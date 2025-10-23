import 'dart:async';
import 'package:realm/realm.dart';

import '../models/realm_models.dart';
import '../utils/realm_database_helper.dart';
import 'media_store.dart';

class MemoryService {
  MemoryService._();
  static final MemoryService instance = MemoryService._();

  final RealmDatabaseHelper _dbHelper = RealmDatabaseHelper();

  Future<List<MemoryEntryRealm>> getAllMemories() async {
    return _dbHelper.getAllMemoryEntries();
  }

  Future<ObjectId> createMemory({
    required List<String> imagePaths,
    String? caption,
  }) async {
    if (imagePaths.isEmpty) {
      throw ArgumentError('At least one image is required to create a memory');
    }

    final memoryId = ObjectId();
    final copiedPaths = await MediaStore.instance.copyImagesForMemory(
      memoryId,
      imagePaths,
    );

    final entry = MemoryEntryRealm(
      memoryId,
      DateTime.now().toUtc(),
      caption: caption,
    )..imagePaths = copiedPaths;

    await _dbHelper.insertMemoryEntry(entry);
    return memoryId;
  }

  Future<void> updateMemory(
    ObjectId id, {
    List<String>? imagePaths,
    String? caption,
  }) async {
    await _dbHelper.updateMemoryEntry(
      id,
      imagePaths: imagePaths,
      caption: caption,
    );
  }

  Future<void> deleteMemory(ObjectId id) async {
    await _dbHelper.deleteMemoryEntry(id);
  }

  Future<List<String>> resolveImagePaths(List<String> storedPaths) async {
    final futures = storedPaths.map(MediaStore.instance.resolvePath);
    return Future.wait(futures);
  }
}

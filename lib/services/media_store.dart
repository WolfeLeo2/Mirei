import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:realm/realm.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:uuid/uuid.dart' as uuid_pkg;

class MediaStore {
  MediaStore._internal();
  static final MediaStore instance = MediaStore._internal();

  final uuid_pkg.Uuid _uuid = const uuid_pkg.Uuid();
  Directory? _appDocDirCache;

  Future<Directory> _getAppDocsDir() async {
    if (_appDocDirCache != null) return _appDocDirCache!;
    _appDocDirCache = await getApplicationDocumentsDirectory();
    return _appDocDirCache!;
  }

  bool _isAbsolutePath(String path) {
    return p.isAbsolute(path);
  }

  /// Copies provided image files into app storage under journal-specific folder
  /// - Generates UUID-based filenames
  /// - Compresses to JPEG at 80% quality
  /// Returns relative paths like 'journal_images/<journalId>/<uuid>.jpg'
  Future<List<String>> copyImagesForJournal(
    ObjectId journalId,
    List<String> sourcePaths,
  ) async {
    if (sourcePaths.isEmpty) return <String>[];

    final docs = await _getAppDocsDir();
    final journalDir = Directory(
      p.join(docs.path, 'journal_images', journalId.hexString),
    );
    if (!journalDir.existsSync()) {
      journalDir.createSync(recursive: true);
    }

    final List<String> relativePaths = [];

    for (final srcPath in sourcePaths) {
      try {
        final srcFile = File(srcPath);
        if (!srcFile.existsSync()) {
          continue;
        }

        final newName = _uuid.v4();
        final destPath = p.join(journalDir.path, '$newName.jpg');

        final compressed = await FlutterImageCompress.compressAndGetFile(
          srcFile.absolute.path,
          destPath,
          quality: 80,
          format: CompressFormat.jpeg,
          keepExif: true,
        );

        final savedPath = compressed?.path ?? destPath;
        if (!File(savedPath).existsSync() && srcFile.existsSync()) {
          await srcFile.copy(destPath);
        }

        final rel = p.join(
          'journal_images',
          journalId.hexString,
          '$newName.jpg',
        );
        relativePaths.add(rel);
      } catch (_) {
        // Skip problematic files silently
      }
    }

    return relativePaths;
  }

  /// Copies provided audio files into app storage under journal-specific folder
  /// - Generates UUID-based filenames
  /// - Preserves original extension when possible
  /// Returns relative paths like 'journal_audio/<journalId>/<uuid>.aac'
  Future<List<String>> copyAudioFilesForJournal(
    ObjectId journalId,
    List<String> sourcePaths,
  ) async {
    if (sourcePaths.isEmpty) return <String>[];

    final docs = await _getAppDocsDir();
    final journalDir = Directory(
      p.join(docs.path, 'journal_audio', journalId.hexString),
    );
    if (!journalDir.existsSync()) {
      journalDir.createSync(recursive: true);
    }

    final List<String> relativePaths = [];

    for (final srcPath in sourcePaths) {
      try {
        final srcFile = File(srcPath);
        if (!srcFile.existsSync()) {
          continue;
        }
        final ext = p.extension(srcPath).isNotEmpty
            ? p.extension(srcPath)
            : '.aac';
        final newName = _uuid.v4();
        final destPath = p.join(journalDir.path, '$newName$ext');
        await srcFile.copy(destPath);
        final rel = p.join(
          'journal_audio',
          journalId.hexString,
          '$newName$ext',
        );
        relativePaths.add(rel);
      } catch (_) {
        // Skip problematic files silently
      }
    }

    return relativePaths;
  }

  /// Resolves a stored media path (relative or absolute) to an absolute file path
  Future<String> resolvePath(String storedPath) async {
    if (storedPath.isEmpty) return storedPath;
    if (_isAbsolutePath(storedPath)) return storedPath;

    final docs = await _getAppDocsDir();
    return p.join(docs.path, storedPath);
  }

  /// Deletes specific relative media files for a journal
  Future<void> deleteRelativeFiles(List<String> relativePaths) async {
    if (relativePaths.isEmpty) return;
    final docs = await _getAppDocsDir();
    for (final rel in relativePaths) {
      try {
        final abs = p.join(docs.path, rel);
        final f = File(abs);
        if (await f.exists()) {
          await f.delete();
        }
      } catch (_) {}
    }
  }

  /// Deletes all media associated with a journal (images + audio)
  Future<void> deleteJournalMedia(ObjectId journalId) async {
    final docs = await _getAppDocsDir();
    final imagesDir = Directory(
      p.join(docs.path, 'journal_images', journalId.hexString),
    );
    final audioDir = Directory(
      p.join(docs.path, 'journal_audio', journalId.hexString),
    );
    for (final dir in [imagesDir, audioDir]) {
      if (await dir.exists()) {
        try {
          await dir.delete(recursive: true);
        } catch (_) {
          // Ignore delete errors
        }
      }
    }
  }
}

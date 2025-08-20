import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Utility class for loading and caching images for folder previews
class ImageLoader {
  static final Map<String, ui.Image> _imageCache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const int _maxCacheSize = 50;
  static const Duration _cacheExpiry = Duration(minutes: 30);

  /// Load an image from file path and cache it
  static Future<ui.Image?> loadImageFromPath(String imagePath) async {
    // Check cache first and validate expiry
    if (_imageCache.containsKey(imagePath)) {
      final timestamp = _cacheTimestamps[imagePath];
      if (timestamp != null &&
          DateTime.now().difference(timestamp) < _cacheExpiry) {
        return _imageCache[imagePath];
      } else {
        // Remove expired entry
        _removeFromCache(imagePath);
      }
    }

    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        return null;
      }

      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: 300, // Optimize for folder preview size
        targetHeight: 300,
      );

      final frame = await codec.getNextFrame();
      final image = frame.image;

      // Manage cache size
      _manageCacheSize();

      // Cache the image with timestamp
      _imageCache[imagePath] = image;
      _cacheTimestamps[imagePath] = DateTime.now();

      return image;
    } catch (e) {
      debugPrint('Error loading image from $imagePath: $e');
      return null;
    }
  }

  /// Manage cache size by removing oldest entries
  static void _manageCacheSize() {
    if (_imageCache.length >= _maxCacheSize) {
      // Find oldest entry
      String? oldestKey;
      DateTime? oldestTime;

      for (final entry in _cacheTimestamps.entries) {
        if (oldestTime == null || entry.value.isBefore(oldestTime)) {
          oldestTime = entry.value;
          oldestKey = entry.key;
        }
      }

      if (oldestKey != null) {
        _removeFromCache(oldestKey);
      }
    }
  }

  /// Remove specific entry from cache
  static void _removeFromCache(String key) {
    _imageCache[key]?.dispose();
    _imageCache.remove(key);
    _cacheTimestamps.remove(key);
  }

  /// Preload images for better performance
  static Future<void> preloadImages(List<String> imagePaths) async {
    final futures = imagePaths.take(10).map((path) => loadImageFromPath(path));
    await Future.wait(futures);
  }

  /// Clear expired entries from cache
  static void clearExpiredCache() {
    final now = DateTime.now();
    final expiredKeys = <String>[];

    for (final entry in _cacheTimestamps.entries) {
      if (now.difference(entry.value) > _cacheExpiry) {
        expiredKeys.add(entry.key);
      }
    }

    for (final key in expiredKeys) {
      _removeFromCache(key);
    }
  }

  /// Clear all cache to free memory
  static void clearCache() {
    for (final image in _imageCache.values) {
      image.dispose();
    }
    _imageCache.clear();
    _cacheTimestamps.clear();
  }

  /// Get cache statistics
  static Map<String, int> get cacheStats => {
    'size': _imageCache.length,
    'maxSize': _maxCacheSize,
  };
}

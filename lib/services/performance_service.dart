import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Enhanced Performance Service for comprehensive app optimization
class PerformanceService {
  static final PerformanceService _instance = PerformanceService._internal();
  factory PerformanceService() => _instance;
  PerformanceService._internal();

  // Performance monitoring
  bool _isMonitoring = false;
  Timer? _monitoringTimer;
  final List<Map<String, dynamic>> _performanceMetrics = [];
  
  // Memory management
  static const int maxCacheSize = 100 * 1024 * 1024; // 100MB
  static final Map<String, dynamic> _cache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  
  // Frame rate monitoring
  int _frameCount = 0;
  double _currentFps = 0.0;
  Timer? _fpsTimer;

  /// Initialize the performance service
  Future<void> initialize() async {
    debugPrint('PerformanceService: Initializing performance monitoring');
    
    // Start frame rate monitoring
    _startFrameRateMonitoring();
    
    // Set up memory management
    _setupMemoryManagement();
    
    debugPrint('PerformanceService: Initialization complete');
  }

  /// Start performance monitoring
  void startMonitoring() {
    if (_isMonitoring) return;
    
    _isMonitoring = true;
    _monitoringTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _collectPerformanceMetrics();
    });
    
    debugPrint('PerformanceService: Performance monitoring started');
  }

  /// Stop performance monitoring
  void stopMonitoring() {
    _isMonitoring = false;
    _monitoringTimer?.cancel();
    _fpsTimer?.cancel();
    debugPrint('PerformanceService: Performance monitoring stopped');
  }

  /// Start frame rate monitoring
  void _startFrameRateMonitoring() {
    _fpsTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _currentFps = _frameCount.toDouble();
      _frameCount = 0;
    });
    
    // Hook into frame callbacks
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _frameCount++;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _frameCount++;
      });
    });
  }

  /// Set up memory management
  void _setupMemoryManagement() {
    // Schedule periodic cache cleanup
    Timer.periodic(const Duration(minutes: 5), (_) {
      _cleanupCache();
    });
  }

  /// Collect performance metrics
  void _collectPerformanceMetrics() {
    final metrics = {
      'timestamp': DateTime.now().toIso8601String(),
      'frame_rate': _currentFps,
      'cache_size': _getCacheSize(),
      'memory_usage': _getMemoryUsage(),
    };
    
    _performanceMetrics.add(metrics);
    
    // Keep only last 100 metrics
    if (_performanceMetrics.length > 100) {
      _performanceMetrics.removeAt(0);
    }
    
    // Log performance warnings
    if (_currentFps < 50) {
      debugPrint('PerformanceService: Low frame rate detected: ${_currentFps.toStringAsFixed(1)} FPS');
    }
  }

  /// Get current performance metrics
  Map<String, dynamic> getCurrentMetrics() {
    return {
      'frame_rate': _currentFps,
      'cache_size_mb': (_getCacheSize() / (1024 * 1024)).toStringAsFixed(2),
      'memory_mb': (_getMemoryUsage() / (1024 * 1024)).toStringAsFixed(2),
      'is_monitoring': _isMonitoring,
    };
  }

  /// Log performance event
  void logEvent(String event, Map<String, dynamic> data) {
    debugPrint('PerformanceService: $event - $data');
  }

  /// Cache management
  static void cacheData(String key, dynamic data, {Duration? expiry}) {
    _cache[key] = data;
    _cacheTimestamps[key] = DateTime.now();
    
    // Clean up if cache is too large
    if (_getCacheSize() > maxCacheSize) {
      _cleanupCache();
    }
  }

  static dynamic getCachedData(String key) {
    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) return null;
    
    // Check if expired (default 30 minutes)
    if (DateTime.now().difference(timestamp) > const Duration(minutes: 30)) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
      return null;
    }
    
    return _cache[key];
  }

  static void _cleanupCache() {
    final now = DateTime.now();
    final keysToRemove = <String>[];
    
    _cacheTimestamps.forEach((key, timestamp) {
      if (now.difference(timestamp) > const Duration(minutes: 30)) {
        keysToRemove.add(key);
      }
    });
    
    for (final key in keysToRemove) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
    }
    
    debugPrint('PerformanceService: Cache cleanup completed. Removed ${keysToRemove.length} expired items.');
  }

  static int _getCacheSize() {
    int size = 0;
    _cache.values.forEach((value) {
      if (value is String) {
        size += value.length * 2; // Rough estimate for UTF-16
      } else if (value is List<int>) {
        size += value.length;
      } else {
        size += 1024; // Default estimate
      }
    });
    return size;
  }

  int _getMemoryUsage() {
    // This is a simplified estimate
    // In a real implementation, you'd use platform-specific memory APIs
    return _getCacheSize() + (1024 * 1024 * 10); // Base 10MB estimate
  }

  /// Dispose of resources
  void dispose() {
    stopMonitoring();
    _cache.clear();
    _cacheTimestamps.clear();
    debugPrint('PerformanceService: Disposed');
  }
}

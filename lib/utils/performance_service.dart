import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

class PerformanceService {
  static final PerformanceService _instance = PerformanceService._internal();
  factory PerformanceService() => _instance;
  PerformanceService._internal();

  // Memory optimization
  static final Map<String, Timer> _debounceTimers = {};
  static final Map<String, dynamic> _cachedResults = {};
  
  // Performance monitoring
  static final List<PerformanceMetric> _metrics = [];
  
  /// Debounce function calls to prevent rapid successive calls
  static void debounce(String id, Duration delay, VoidCallback callback) {
    _debounceTimers[id]?.cancel();
    _debounceTimers[id] = Timer(delay, callback);
  }
  
  /// Cache expensive operations
  static T cached<T>(String key, T Function() computation, {Duration? expiry}) {
    if (_cachedResults.containsKey(key)) {
      final cached = _cachedResults[key];
      if (cached is CachedValue<T>) {
        if (expiry == null || DateTime.now().difference(cached.timestamp) < expiry) {
          return cached.value;
        }
      }
    }
    
    final result = computation();
    _cachedResults[key] = CachedValue(result, DateTime.now());
    return result;
  }
  
  /// Safe setState wrapper for widgets
  static void safeSetState(StatefulWidget widget, VoidCallback setState) {
    if (widget is State && (widget as State).mounted) {
      setState();
    }
  }
  
  /// Memory cleanup for large collections
  static void cleanupMemory() {
    // Clear expired cache entries
    final now = DateTime.now();
    _cachedResults.removeWhere((key, value) {
      if (value is CachedValue) {
        return now.difference(value.timestamp) > const Duration(minutes: 10);
      }
      return false;
    });
    
    // Cancel unused timers
    _debounceTimers.values.forEach((timer) => timer.cancel());
    _debounceTimers.clear();
    
    // Force garbage collection in debug mode
    if (kDebugMode && Platform.isAndroid) {
      // Trigger GC suggestion for Android
      SystemChannels.platform.invokeMethod('SystemNavigator.pop');
    }
  }
  
  /// Track performance metrics
  static void recordMetric(String name, Duration duration, {Map<String, dynamic>? metadata}) {
    _metrics.add(PerformanceMetric(
      name: name,
      duration: duration,
      timestamp: DateTime.now(),
      metadata: metadata,
    ));
    
    // Keep only last 100 metrics
    if (_metrics.length > 100) {
      _metrics.removeAt(0);
    }
  }
  
  /// Get performance report
  static PerformanceReport getReport() {
    return PerformanceReport(_metrics);
  }
}

class CachedValue<T> {
  final T value;
  final DateTime timestamp;
  
  CachedValue(this.value, this.timestamp);
}

class PerformanceMetric {
  final String name;
  final Duration duration;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;
  
  PerformanceMetric({
    required this.name,
    required this.duration,
    required this.timestamp,
    this.metadata,
  });
}

class PerformanceReport {
  final List<PerformanceMetric> metrics;
  
  PerformanceReport(this.metrics);
  
  Duration get averageResponseTime {
    if (metrics.isEmpty) return Duration.zero;
    final total = metrics.fold<int>(0, (sum, metric) => sum + metric.duration.inMilliseconds);
    return Duration(milliseconds: total ~/ metrics.length);
  }
  
  Map<String, Duration> get slowestOperations {
    final grouped = <String, List<Duration>>{};
    
    for (final metric in metrics) {
      grouped[metric.name] ??= [];
      grouped[metric.name]!.add(metric.duration);
    }
    
    return grouped.map((name, durations) {
      durations.sort((a, b) => b.compareTo(a));
      return MapEntry(name, durations.first);
    });
  }
}

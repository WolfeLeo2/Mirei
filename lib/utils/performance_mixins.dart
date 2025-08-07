import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Mixin to optimize widget rebuilds and prevent unnecessary UI work
mixin PerformanceOptimizedStateMixin<T extends StatefulWidget> on State<T> {
  bool _isDisposed = false;
  final List<StreamSubscription> _subscriptions = [];
  Timer? _debounceTimer;

  @override
  void dispose() {
    _isDisposed = true;
    _debounceTimer?.cancel();
    
    // Cancel all subscriptions to prevent memory leaks
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
    
    super.dispose();
  }

  /// Safe setState that checks if widget is still mounted
  void safeSetState(VoidCallback fn) {
    if (!_isDisposed && mounted) {
      setState(fn);
    }
  }

  /// Debounced setState for high-frequency updates
  void debouncedSetState(VoidCallback fn, {Duration delay = const Duration(milliseconds: 100)}) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(delay, () {
      if (!_isDisposed && mounted) {
        setState(fn);
      }
    });
  }

  /// Add subscription with automatic cleanup
  void addSubscription(StreamSubscription subscription) {
    _subscriptions.add(subscription);
  }

  /// Schedule work for next frame to avoid blocking current frame
  void scheduleForNextFrame(VoidCallback callback) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed && mounted) {
        callback();
      }
    });
  }

  /// Break expensive operations into chunks
  Future<void> processInChunks<K>(
    List<K> items,
    Function(K) processor, {
    int chunkSize = 50,
    Duration delay = const Duration(milliseconds: 10),
  }) async {
    for (int i = 0; i < items.length; i += chunkSize) {
      if (_isDisposed || !mounted) break;
      
      final chunk = items.skip(i).take(chunkSize);
      for (final item in chunk) {
        processor(item);
      }
      
      // Yield control back to the UI thread
      await Future.delayed(delay);
    }
  }
}

/// Widget that automatically handles RepaintBoundary for performance
class OptimizedContainer extends StatelessWidget {
  final Widget child;
  final bool addRepaintBoundary;
  final bool addAutomaticKeepAlive;
  
  const OptimizedContainer({
    super.key,
    required this.child,
    this.addRepaintBoundary = true,
    this.addAutomaticKeepAlive = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget result = child;
    
    if (addRepaintBoundary) {
      result = RepaintBoundary(child: result);
    }
    
    return result;
  }
}

/// Performance-optimized ListView builder
class OptimizedListView extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final EdgeInsets? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const OptimizedListView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: itemCount,
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: physics,
      // Add caching for better scroll performance
      cacheExtent: 500.0,
      itemBuilder: (context, index) {
        // Wrap each item in RepaintBoundary
        return RepaintBoundary(
          child: itemBuilder(context, index),
        );
      },
    );
  }
}

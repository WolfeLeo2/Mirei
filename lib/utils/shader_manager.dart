import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Manages shader loading and uniform parameter updates
class ShaderManager {
  ui.FragmentShader? _blurShader;
  ui.FragmentShader? _morphShader;

  bool _initialized = false;

  /// Initialize shaders from assets
  Future<void> initializeShaders() async {
    if (_initialized) return;

    try {
      // Load blur shader
      final blurProgram = await ui.FragmentProgram.fromAsset(
        'shaders/custom_blur.frag',
      );
      _blurShader = blurProgram.fragmentShader();

      // Load morph shader
      final morphProgram = await ui.FragmentProgram.fromAsset(
        'shaders/morph_transition.frag',
      );
      _morphShader = morphProgram.fragmentShader();

      _initialized = true;
    } catch (e) {
      debugPrint('Error initializing shaders: $e');
      // Continue without shaders - fallback to regular effects
    }
  }

  /// Update blur shader uniforms
  void updateBlurUniforms({
    required double time,
    required Size resolution,
    required double blurRadius,
    required Offset focusPoint,
  }) {
    if (_blurShader == null) return;

    try {
      _blurShader!.setFloat(0, time);
      _blurShader!.setFloat(1, resolution.width);
      _blurShader!.setFloat(2, resolution.height);
      _blurShader!.setFloat(3, blurRadius);
      _blurShader!.setFloat(4, focusPoint.dx);
      _blurShader!.setFloat(5, focusPoint.dy);
    } catch (e) {
      debugPrint('Error updating blur shader uniforms: $e');
    }
  }

  /// Update morph shader uniforms
  void updateMorphUniforms({
    required double progress,
    required Offset folderCenter,
    required Size resolution,
  }) {
    if (_morphShader == null) return;

    try {
      _morphShader!.setFloat(0, progress);
      _morphShader!.setFloat(1, folderCenter.dx);
      _morphShader!.setFloat(2, folderCenter.dy);
      _morphShader!.setFloat(3, resolution.width);
      _morphShader!.setFloat(4, resolution.height);
    } catch (e) {
      debugPrint('Error updating morph shader uniforms: $e');
    }
  }

  /// Get blur shader instance
  ui.FragmentShader? get blurShader => _blurShader;

  /// Get morph shader instance
  ui.FragmentShader? get morphShader => _morphShader;

  /// Check if shaders are available
  bool get hasShaders =>
      _initialized && _blurShader != null && _morphShader != null;

  /// Dispose of shader resources
  void dispose() {
    _blurShader?.dispose();
    _morphShader?.dispose();
    _blurShader = null;
    _morphShader = null;
    _initialized = false;
  }
}

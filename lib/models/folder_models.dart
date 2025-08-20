import 'package:flutter/material.dart';

/// Represents a scattered position for journal entries during expansion
class ScatteredPosition {
  final Offset position;
  final double rotation;
  final double scale;
  final Duration delay;

  const ScatteredPosition({
    required this.position,
    this.rotation = 0.0,
    this.scale = 1.0,
    this.delay = Duration.zero,
  });

  ScatteredPosition copyWith({
    Offset? position,
    double? rotation,
    double? scale,
    Duration? delay,
  }) {
    return ScatteredPosition(
      position: position ?? this.position,
      rotation: rotation ?? this.rotation,
      scale: scale ?? this.scale,
      delay: delay ?? this.delay,
    );
  }
}

/// Manages the expansion state of a folder
class FolderExpansionState {
  final String folderId;
  final bool isExpanded;
  final List<ScatteredPosition> entryPositions;
  final AnimationController controller;

  const FolderExpansionState({
    required this.folderId,
    required this.isExpanded,
    required this.entryPositions,
    required this.controller,
  });

  FolderExpansionState copyWith({
    String? folderId,
    bool? isExpanded,
    List<ScatteredPosition>? entryPositions,
    AnimationController? controller,
  }) {
    return FolderExpansionState(
      folderId: folderId ?? this.folderId,
      isExpanded: isExpanded ?? this.isExpanded,
      entryPositions: entryPositions ?? this.entryPositions,
      controller: controller ?? this.controller,
    );
  }
}

/// Configuration for folder layout behavior
class FolderLayoutConfig {
  final int gridColumns;
  final double gridSpacing;
  final double folderAspectRatio;
  final double singleFolderScale;
  final EdgeInsets padding;

  const FolderLayoutConfig({
    this.gridColumns = 3,
    this.gridSpacing = 16.0,
    this.folderAspectRatio = 3 / 4,
    this.singleFolderScale = 1.5,
    this.padding = const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0), // Remove top padding
  });

  FolderLayoutConfig copyWith({
    int? gridColumns,
    double? gridSpacing,
    double? folderAspectRatio,
    double? singleFolderScale,
    EdgeInsets? padding,
  }) {
    return FolderLayoutConfig(
      gridColumns: gridColumns ?? this.gridColumns,
      gridSpacing: gridSpacing ?? this.gridSpacing,
      folderAspectRatio: folderAspectRatio ?? this.folderAspectRatio,
      singleFolderScale: singleFolderScale ?? this.singleFolderScale,
      padding: padding ?? this.padding,
    );
  }
}

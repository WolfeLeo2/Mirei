# Design Document

## Overview

This design transforms the journal list screen from a vertical expandable folder structure to a modern, interactive grid-based interface. The new design features month/year folders displayed as cards in a 3-column grid, where each folder shows a preview of the most recent journal entry's image to appear "full". When tapped, folders expand with a dramatic "gushing out" animation where journal entries scatter around the original folder position, while the background blurs for visual focus.

## Architecture

### Component Structure

```
JournalListScreen
├── AppBar (existing)
├── AdaptiveFolderLayout
│   ├── SingleFolderView (when only one folder)
│   │   └── LargeMonthFolderCard
│   └── FolderGridView (when multiple folders)
│       └── MonthFolderCard (multiple)
│           ├── FolderPreviewImage
│           ├── MonthYearLabel
│           └── EntryCountBadge
├── ExpandedEntriesOverlay
│   ├── CustomBlurShader
│   ├── MorphingTransitionShader
│   ├── ScatteredEntryCards (multiple)
│   └── CloseButton
└── FloatingActionButton (existing)
```

### State Management

The screen will manage the following state:

- `Map<String, List<JournalEntryRealm>> journalsByMonth` - Grouped journal entries
- `String? expandedFolderId` - Currently expanded folder (null if none)
- `bool isSingleFolderLayout` - Whether to show single centered folder or grid
- `Map<String, AnimationController> expansionControllers` - Animation controllers for each folder
- `AnimationController blurController` - Controls background blur effect
- `AnimationController morphController` - Controls morphing shader transitions
- `Map<String, List<Offset>> entryPositions` - Calculated positions for scattered entries
- `FragmentShader? blurShader` - Custom blur shader instance
- `FragmentShader? morphShader` - Morphing transition shader instance

## Components and Interfaces

### AdaptiveFolderLayout

A widget that switches between single folder and grid layouts based on folder count.

**Properties:**

- `Map<String, List<JournalEntryRealm>> journalsByMonth` - All grouped entries
- `Function(String) onFolderTap` - Folder tap handler

**Key Methods:**

- `_determinateLayout()` - Decides between single or grid layout
- `_buildSingleFolderView()` - Creates centered large folder
- `_buildGridView()` - Creates 3-column grid

### MonthFolderCard

A stateful widget representing each month folder (both grid and single versions).

**Properties:**

- `String monthKey` - Month/year identifier (e.g., "August 2025")
- `List<JournalEntryRealm> entries` - Journal entries for this month
- `bool isExpanded` - Whether this folder is currently expanded
- `bool isLargeSize` - Whether to render in large single-folder mode
- `VoidCallback onTap` - Callback when folder is tapped
- `String? previewImagePath` - Path to the most recent entry's first image

**Key Methods:**

- `_buildFolderCard()` - Renders the closed folder state
- `_buildPreviewImage()` - Shows the most recent entry's image or placeholder
- `_buildMonthLabel()` - Displays month/year text
- `_buildEntryCountBadge()` - Shows number of entries

### ExpandedEntriesOverlay

A full-screen overlay that handles the expanded folder state with custom shaders.

**Properties:**

- `List<JournalEntryRealm> entries` - Entries to display
- `Offset folderPosition` - Original folder position for animation origin
- `VoidCallback onClose` - Callback to close the expanded view
- `AnimationController animationController` - Controls entry animations
- `FragmentShader blurShader` - Custom blur shader for background
- `FragmentShader morphShader` - Morphing transition shader

**Key Methods:**

- `_calculateScatteredPositions()` - Computes scattered positions for entries
- `_buildScatteredEntry()` - Renders individual journal entry cards
- `_buildCustomBlurBackground()` - Creates shader-based blur effect
- `_buildMorphingTransition()` - Handles folder-to-entries morphing

### FolderGridView

The main grid container for month folders.

**Properties:**

- `Map<String, List<JournalEntryRealm>> journalsByMonth` - All grouped entries
- `String? expandedFolderId` - Currently expanded folder
- `Function(String) onFolderTap` - Folder tap handler

**Key Methods:**

- `_buildGrid()` - Creates the responsive grid layout
- `_getSortedMonthKeys()` - Returns chronologically sorted month keys
- `_getPreviewImage()` - Extracts preview image from most recent entry

## Data Models

### Enhanced JournalEntryRealm Usage

The existing `JournalEntryRealm` model will be used with focus on:

- `imagePaths` - For folder preview images
- `createdAt` - For chronological sorting
- `title` and `content` - For entry card display
- `audioRecordings` - For media indicators

### New Data Structures

```dart
class ScatteredPosition {
  final Offset position;
  final double rotation;
  final double scale;
  final Duration delay;

  ScatteredPosition({
    required this.position,
    this.rotation = 0.0,
    this.scale = 1.0,
    this.delay = Duration.zero,
  });
}

class FolderExpansionState {
  final String folderId;
  final bool isExpanded;
  final List<ScatteredPosition> entryPositions;
  final AnimationController controller;

  FolderExpansionState({
    required this.folderId,
    required this.isExpanded,
    required this.entryPositions,
    required this.controller,
  });
}
```

## Shader System

### Custom Blur Shader

**File**: `shaders/custom_blur.frag`

**Purpose**: Creates enhanced blur effects around expanded entries with customizable intensity and radius.

**Uniforms**:

- `float time` - Animation time for dynamic effects
- `vec2 resolution` - Screen resolution
- `float blurRadius` - Blur intensity (0.0 to 20.0)
- `vec2 focusPoint` - Center point for radial blur
- `sampler2D texture` - Input texture to blur

**Features**:

- Radial blur emanating from folder position
- Dynamic blur intensity based on animation progress
- Optimized for mobile performance

### Morphing Transition Shader

**File**: `shaders/morph_transition.frag`

**Purpose**: Handles smooth morphing between folder state and scattered entries.

**Uniforms**:

- `float progress` - Transition progress (0.0 to 1.0)
- `vec2 folderCenter` - Original folder position
- `vec2 resolution` - Screen resolution
- `sampler2D folderTexture` - Folder appearance
- `sampler2D entriesTexture` - Scattered entries appearance

**Features**:

- Smooth morphing between two states
- Particle-like effects during transition
- Maintains visual continuity

### Shader Integration

```dart
class ShaderManager {
  FragmentShader? _blurShader;
  FragmentShader? _morphShader;

  Future<void> initializeShaders() async {
    final blurProgram = await FragmentProgram.fromAsset('shaders/custom_blur.frag');
    final morphProgram = await FragmentProgram.fromAsset('shaders/morph_transition.frag');

    _blurShader = blurProgram.fragmentShader();
    _morphShader = morphProgram.fragmentShader();
  }

  void updateBlurUniforms(double time, Size resolution, double blurRadius, Offset focusPoint) {
    _blurShader?.setFloat(0, time);
    _blurShader?.setFloat(1, resolution.width);
    _blurShader?.setFloat(2, resolution.height);
    _blurShader?.setFloat(3, blurRadius);
    _blurShader?.setFloat(4, focusPoint.dx);
    _blurShader?.setFloat(5, focusPoint.dy);
  }
}
```

## Animation System

### Folder Expansion Animation

**Phase 1: Preparation (0-100ms)**

- Initialize custom blur shader with radial blur from folder center
- Begin morphing shader transition (progress: 0.0 → 0.2)
- Scale folder card slightly (1.0 → 1.05)

**Phase 2: Morphing Transition (100-400ms)**

- Morphing shader progress: 0.2 → 0.8
- Folder appearance gradually transforms into scattered entries
- Blur radius increases progressively

**Phase 3: Entry Emergence (400-800ms)**

- Entries animate from folder center to scattered positions
- Staggered animation with 50ms delays between entries
- Each entry uses `SlideTransition` and `RotationTransition`
- Easing: `Curves.elasticOut` for bouncy effect
- Morphing shader completes (progress: 0.8 → 1.0)

**Phase 4: Settle (800-1000ms)**

- Entries settle into final positions
- Blur shader stabilizes at maximum intensity
- Folder card returns to normal scale

### Collapse Animation

**Reverse of expansion with shader transitions:**

- Morphing shader reverses (progress: 1.0 → 0.0)
- Entries animate back to folder center with staggered timing
- Blur shader intensity decreases progressively
- Folder morphs back from scattered entries to original appearance

### Animation Controllers

```dart
class AnimationControllers {
  late AnimationController blurController;
  late Map<String, AnimationController> folderControllers;
  late Map<String, List<AnimationController>> entryControllers;

  void initializeControllers(TickerProvider vsync) {
    blurController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: vsync,
    );
    // Initialize folder and entry controllers...
  }
}
```

## Layout System

### Grid Layout

- **Desktop/Tablet**: 3 columns with 16px gaps
- **Mobile**: 2 columns with 12px gaps (if screen width < 600px)
- **Folder Card Aspect Ratio**: 3:4 (width:height)
- **Padding**: 16px around grid edges

### Single Folder Layout

- **Position**: Centered horizontally and vertically on screen
- **Size**: 1.5x larger than grid folder cards
- **Aspect Ratio**: Same 3:4 ratio maintained
- **Spacing**: Minimum 32px from screen edges

### Scattered Entry Layout

**Algorithm for positioning scattered entries:**

```dart
List<Offset> calculateScatteredPositions(
  Offset folderCenter,
  int entryCount,
  Size screenSize,
) {
  final positions = <Offset>[];
  final radius = min(screenSize.width, screenSize.height) * 0.3;

  for (int i = 0; i < entryCount; i++) {
    final angle = (i / entryCount) * 2 * pi + Random().nextDouble() * 0.5;
    final distance = radius * (0.5 + Random().nextDouble() * 0.5);

    final x = folderCenter.dx + cos(angle) * distance;
    final y = folderCenter.dy + sin(angle) * distance;

    positions.add(Offset(
      x.clamp(50, screenSize.width - 150),
      y.clamp(100, screenSize.height - 200),
    ));
  }

  return positions;
}
```

## Visual Design

### Color Scheme

- **Background**: `Color(0xFFd7dfe5)` (existing)
- **Folder Cards**: `Colors.white` with subtle shadow
- **Text Primary**: `Color(0xFF115e5a)` (existing)
- **Text Secondary**: `Colors.grey[600]`
- **Blur Overlay**: `Colors.black.withValues(alpha: 0.3)`

### Typography

- **Month/Year Labels**: `GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600)`
- **Entry Count**: `GoogleFonts.inter(fontSize: 14, color: Colors.grey[600])`
- **Entry Titles**: `GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500)`

### Shadows and Effects

- **Folder Cards**: `BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))`
- **Entry Cards**: `BoxShadow(color: Colors.black10, blurRadius: 6, offset: Offset(0, 2))`
- **Blur Effect**: `BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10))`

## Error Handling

### Image Loading

- **Missing Images**: Show placeholder with folder icon
- **Loading Errors**: Graceful fallback to text preview
- **Network Issues**: Cache preview images locally

### Animation Errors

- **Controller Disposal**: Proper cleanup in `dispose()`
- **Animation Interruption**: Handle rapid taps gracefully
- **Memory Management**: Limit concurrent animations

### Data Consistency

- **Empty Folders**: Hide folders with no entries
- **Date Parsing**: Handle malformed dates gracefully
- **Concurrent Modifications**: Use proper state management

## Testing Strategy

### Unit Tests

- **Data Grouping**: Test journal grouping by month/year
- **Position Calculation**: Test scattered position algorithms
- **Date Sorting**: Test chronological sorting logic

### Widget Tests

- **Folder Rendering**: Test folder card display
- **Grid Layout**: Test responsive grid behavior
- **Animation States**: Test expansion/collapse states

### Integration Tests

- **Full Workflow**: Test complete expand/collapse cycle
- **Navigation**: Test entry viewing from expanded state
- **Performance**: Test with large numbers of entries

### Performance Tests

- **Animation Performance**: Measure FPS during animations
- **Memory Usage**: Monitor memory during state changes
- **Scroll Performance**: Test grid scrolling with many folders

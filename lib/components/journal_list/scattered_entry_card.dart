import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:animations/animations.dart';
import '../../models/realm_models.dart';
import '../../core/constants/app_colors.dart';
import '../../screens/journal_view.dart';
import '../../utils/realm_database_helper.dart';
import 'package:realm/realm.dart';

/// Individual journal entry card for scattered display with performance optimizations
class ScatteredEntryCard extends StatelessWidget {
  final JournalEntryRealm entry;
  final MoodEntryRealm? mood;
  final VoidCallback? onEntryDeleted; // Callback for when entry is deleted
  final bool showDeleteButton; // Whether to show the delete button

  const ScatteredEntryCard({
    super.key,
    required this.entry,
    this.mood,
    this.onEntryDeleted,
    this.showDeleteButton = true, // Show delete button by default
  });

  /// Safely access a Realm object property with error handling
  T? _safeAccess<T>(T Function() accessor, [T? defaultValue]) {
    try {
      return accessor();
    } catch (e) {
      if (e is RealmException && e.message.contains('invalidated')) {
        // Object has been deleted, return default value
        return defaultValue;
      }
      rethrow;
    }
  }

  /// Show delete confirmation dialog
  Future<void> _showDeleteConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Journal Entry',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2D3748),
          ),
        ),
        content: Text(
          'Are you sure you want to delete this journal entry? This action cannot be undone.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFF718096),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF718096),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteEntry(context);
    }
  }

  /// Delete the journal entry
  Future<void> _deleteEntry(BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      // Get the entry ID before potential invalidation
      final entryId = _safeAccess(() => entry.id);
      if (entryId == null) {
        // Entry is already deleted
        return;
      }

      final dbHelper = RealmDatabaseHelper();
      await dbHelper.deleteJournalEntry(entryId);

      // Show success message
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            'Journal entry deleted successfully',
            style: GoogleFonts.inter(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF115e5a),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      // Notify parent to refresh
      if (onEntryDeleted != null) {
        onEntryDeleted!();
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            'Error deleting journal entry: $e',
            style: GoogleFonts.inter(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if entry is still valid
    final isValid = _safeAccess(() => entry.createdAt) != null;

    if (!isValid) {
      // Return an error placeholder if entry has been invalidated
      return Container(
        width: 150,
        height: 200,
        decoration: const BoxDecoration(
          color: Colors.grey,
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        child: const Center(
          child: Icon(Icons.error_outline, color: Colors.white, size: 32),
        ),
      );
    }

    return RepaintBoundary(
      // Optimize repaints
      child: Stack(
        children: [
          // Main card with OpenContainer
          OpenContainer<bool>(
            transitionDuration: const Duration(
              milliseconds: 500,
            ), // Slightly faster
            openBuilder: (BuildContext context, VoidCallback _) {
              return JournalViewScreen(entry: entry);
            },
            onClosed: (bool? result) {
              // If entry was deleted, notify parent to refresh
              if (result == true && onEntryDeleted != null) {
                onEntryDeleted!();
              }
            },
            openShape: BeveledRectangleBorder(),
            closedElevation: 8,
            closedShape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
            closedBuilder: (BuildContext context, VoidCallback openContainer) {
              return _OptimizedCardContent(
                entry: entry,
                mood: mood,
                safeAccess: _safeAccess,
              );
            },
          ),

          // Delete button overlay
          if (showDeleteButton)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _showDeleteConfirmation(context),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Separate widget for card content to enable better caching and reduce rebuilds
class _OptimizedCardContent extends StatelessWidget {
  final JournalEntryRealm entry;
  final MoodEntryRealm? mood;
  final T? Function<T>(T Function() accessor, [T? defaultValue]) safeAccess;

  const _OptimizedCardContent({
    required this.entry,
    this.mood,
    required this.safeAccess,
  });

  @override
  Widget build(BuildContext context) {
    // Safely access entry properties
    final createdAt = safeAccess(() => entry.createdAt);
    final title = safeAccess(() => entry.title, '') ?? '';
    final content = safeAccess(() => entry.content, '') ?? '';
    final imagePaths =
        safeAccess(() => entry.imagePaths, <String>[]) ?? <String>[];
    final audioRecordings =
        safeAccess(() => entry.audioRecordings, <AudioRecordingData>[]) ??
        <AudioRecordingData>[];

    // If entry is invalid, show error state
    if (createdAt == null) {
      return Container(
        width: 150,
        height: 200,
        decoration: const BoxDecoration(
          color: Colors.grey,
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        child: const Center(
          child: Icon(Icons.error_outline, color: Colors.white, size: 32),
        ),
      );
    }

    return Container(
      width: 150,
      height: 200,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Color(
              0x1A000000,
            ), // Use const color instead of Colors.black.withValues
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date - cached formatting
            _DateWidget(date: createdAt),
            const SizedBox(height: 8),

            // Title (if exists)
            if (title.isNotEmpty) ...[
              _TitleWidget(title: title),
              const SizedBox(height: 6),
            ],

            // Content preview
            Expanded(
              child: _ContentPreview(
                content: content,
                hasTitle: title.isNotEmpty,
              ),
            ),
            const SizedBox(height: 4),
            // Media indicators and mood
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Media indicators
                _MediaIndicators(
                  imagePaths: imagePaths,
                  audioRecordings: audioRecordings,
                ),
                // Mood indicator
                _MoodIndicator(mood: mood),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Cached date widget to avoid repeated formatting
class _DateWidget extends StatelessWidget {
  final DateTime date;

  const _DateWidget({required this.date});

  @override
  Widget build(BuildContext context) {
    return Text(
      _formatDate(date),
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF115e5a), // Use const color
      ),
    );
  }

  // Static method for better performance
  static String _formatDate(DateTime date) {
    return DateFormat('MMM d').format(date);
  }
}

/// Cached title widget
class _TitleWidget extends StatelessWidget {
  final String title;

  const _TitleWidget({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }
}

/// Cached content preview widget
class _ContentPreview extends StatelessWidget {
  final String content;
  final bool hasTitle;

  const _ContentPreview({required this.content, required this.hasTitle});

  @override
  Widget build(BuildContext context) {
    return Text(
      content,
      maxLines: hasTitle ? 4 : 6,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.inter(
        fontSize: 12,
        color: const Color(0xFF616161), // Use const color
        height: 1.3,
      ),
    );
  }
}

/// Optimized media indicators widget
class _MediaIndicators extends StatelessWidget {
  final List<String> imagePaths;
  final List<AudioRecordingData> audioRecordings;

  const _MediaIndicators({
    required this.imagePaths,
    required this.audioRecordings,
  });

  @override
  Widget build(BuildContext context) {
    final hasImages = imagePaths.isNotEmpty;
    final hasAudio = audioRecordings.isNotEmpty;

    if (!hasImages && !hasAudio) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        if (hasImages) _ImageIndicator(count: imagePaths.length),
        if (hasImages && hasAudio) const SizedBox(width: 4),
        if (hasAudio) _AudioIndicator(count: audioRecordings.length),
      ],
    );
  }
}

/// Image indicator badge
class _ImageIndicator extends StatelessWidget {
  final int count;

  const _ImageIndicator({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0x1A2196F3), // Use const color
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.image,
            size: 10,
            color: Color(0xFF1976D2), // Use const color
          ),
          const SizedBox(width: 2),
          Text(
            '$count',
            style: GoogleFonts.inter(
              fontSize: 10,
              color: const Color(0xFF1976D2),
            ),
          ),
        ],
      ),
    );
  }
}

/// Audio indicator badge
class _AudioIndicator extends StatelessWidget {
  final int count;

  const _AudioIndicator({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0x1AFF9800), // Use const color
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.mic,
            size: 10,
            color: Color(0xFFF57C00), // Use const color
          ),
          const SizedBox(width: 2),
          Text(
            '$count',
            style: GoogleFonts.inter(
              fontSize: 10,
              color: const Color(0xFFF57C00),
            ),
          ),
        ],
      ),
    );
  }
}

/// Cached mood indicator widget
class _MoodIndicator extends StatelessWidget {
  final MoodEntryRealm? mood;

  const _MoodIndicator({this.mood});

  @override
  Widget build(BuildContext context) {
    final emotion = mood?.mood ?? 'Neutral';
    final color = AppColors.getEmotionColor(emotion);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        emotion,
        style: GoogleFonts.inter(
          color: color,
          fontWeight: FontWeight.w500,
          fontSize: 8,
        ),
      ),
    );
  }
}

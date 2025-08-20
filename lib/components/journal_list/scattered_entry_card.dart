import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:animations/animations.dart';
import '../../models/realm_models.dart';
import '../../utils/emotion_colors.dart';
import '../../screens/journal_view.dart';

/// Individual journal entry card for scattered display with performance optimizations
class ScatteredEntryCard extends StatelessWidget {
  final JournalEntryRealm entry;
  final MoodEntryRealm? mood;

  const ScatteredEntryCard({
    super.key,
    required this.entry,
    this.mood,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary( // Optimize repaints
      child: OpenContainer<bool>(
        transitionDuration: const Duration(milliseconds: 500), // Slightly faster
        openBuilder: (BuildContext context, VoidCallback _) {
          return JournalViewScreen(entry: entry);
        },
        openShape: BeveledRectangleBorder(
          
        ),
        closedElevation: 8,
        closedShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        closedBuilder: (BuildContext context, VoidCallback openContainer) {
          return _OptimizedCardContent(
            entry: entry,
            mood: mood,
          );
        },
      ),
    );
  }
}

/// Separate widget for card content to enable better caching and reduce rebuilds
class _OptimizedCardContent extends StatelessWidget {
  final JournalEntryRealm entry;
  final MoodEntryRealm? mood;

  const _OptimizedCardContent({
    required this.entry,
    this.mood,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      height: 200,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000), // Use const color instead of Colors.black.withValues
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
            _DateWidget(date: entry.createdAt),
            const SizedBox(height: 8),

            // Title (if exists)
            if (entry.title.isNotEmpty) ...[
              _TitleWidget(title: entry.title),
              const SizedBox(height: 6),
            ],

            // Content preview
            Expanded(
              child: _ContentPreview(
                content: entry.content,
                hasTitle: entry.title.isNotEmpty,
              ),
            ),

            const SizedBox(height: 8),

            // Media indicators and mood
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Media indicators
                _MediaIndicators(entry: entry),
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
  
  const _ContentPreview({
    required this.content,
    required this.hasTitle,
  });

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
  final JournalEntryRealm entry;
  
  const _MediaIndicators({required this.entry});

  @override
  Widget build(BuildContext context) {
    final hasImages = entry.imagePaths.isNotEmpty;
    final hasAudio = entry.audioRecordings.isNotEmpty;
    
    if (!hasImages && !hasAudio) {
      return const SizedBox.shrink();
    }
    
    return Row(
      children: [
        if (hasImages) _ImageIndicator(count: entry.imagePaths.length),
        if (hasImages && hasAudio) const SizedBox(width: 4),
        if (hasAudio) _AudioIndicator(count: entry.audioRecordings.length),
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
    final color = getEmotionColor(emotion);

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

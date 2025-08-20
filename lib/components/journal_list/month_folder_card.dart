import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/realm_models.dart';
import 'folder_image_widget.dart';

/// Stateful widget representing each month folder with performance optimizations
class MonthFolderCard extends StatefulWidget {
  final String monthKey;
  final List<JournalEntryRealm> entries;
  final bool isExpanded;
  final bool isLargeSize;
  final VoidCallback onTap;
  final GlobalKey? folderKey;

  const MonthFolderCard({
    super.key,
    required this.monthKey,
    required this.entries,
    required this.isExpanded,
    required this.isLargeSize,
    required this.onTap,
    this.folderKey,
  });

  @override
  State<MonthFolderCard> createState() => _MonthFolderCardState();
}

class _MonthFolderCardState extends State<MonthFolderCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 120), // Faster animation
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.03).animate( // Reduced scale
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary( // Optimize repaints
      child: GestureDetector(
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) {
        _scaleController.reverse();
        widget.onTap();
      },
      onTapCancel: () => _scaleController.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
              child: _FolderCardContent(
                folderKey: widget.folderKey,
                monthKey: widget.monthKey,
                entries: widget.entries,
                isLargeSize: widget.isLargeSize,
              ),
          );
        },
        ),
      ),
    );
  }
}

/// Separate content widget to optimize rebuilds
class _FolderCardContent extends StatelessWidget {
  final GlobalKey? folderKey;
  final String monthKey;
  final List<JournalEntryRealm> entries;
  final bool isLargeSize;

  const _FolderCardContent({
    this.folderKey,
    required this.monthKey,
    required this.entries,
    required this.isLargeSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: folderKey,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000), // Use const color
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: FolderImageWidget(
        monthKey: monthKey,
        entries: entries,
        isLargeSize: isLargeSize,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          padding: EdgeInsets.all(isLargeSize ? 20 : 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MonthLabel(
                monthKey: monthKey,
                isLargeSize: isLargeSize,
              ),
              const SizedBox(height: 4),
              _EntryCountBadge(
                entryCount: entries.length,
                isLargeSize: isLargeSize,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Cached month label widget
class _MonthLabel extends StatelessWidget {
  final String monthKey;
  final bool isLargeSize;

  const _MonthLabel({
    required this.monthKey,
    required this.isLargeSize,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      monthKey,
      style: GoogleFonts.inter(
        fontSize: isLargeSize ? 24 : 18,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF115e5a),
      ),
    );
  }
}

/// Cached entry count badge widget
class _EntryCountBadge extends StatelessWidget {
  final int entryCount;
  final bool isLargeSize;

  const _EntryCountBadge({
    required this.entryCount,
    required this.isLargeSize,
  });

  @override
  Widget build(BuildContext context) {
    final entryText = entryCount == 1 ? 'entry' : 'entries';

    return Text(
      '$entryCount $entryText',
      style: GoogleFonts.inter(
        fontSize: isLargeSize ? 16 : 14,
        color: const Color(0xFF757575), // Use const color
      ),
    );
  }
}

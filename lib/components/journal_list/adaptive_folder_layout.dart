import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/realm_models.dart';
import '../../models/folder_models.dart';
import 'folder_grid_view.dart';
import 'folder_carousel_view.dart';
import 'single_folder_view.dart';

/// Layout modes for folder display
enum FolderViewMode {
  grid,
  carousel,
}

/// Adaptive layout that switches between single folder and multi-folder views
class AdaptiveFolderLayout extends StatefulWidget {
  final Map<String, List<JournalEntryRealm>> journalsByMonth;
  final String? expandedFolderId;
  final Function(String, Offset) onFolderTap;
  final FolderLayoutConfig? config;
  final FolderViewMode viewMode;
  final ValueChanged<FolderViewMode>? onViewModeChanged;

  const AdaptiveFolderLayout({
    super.key,
    required this.journalsByMonth,
    this.expandedFolderId,
    required this.onFolderTap,
    this.config,
    this.viewMode = FolderViewMode.grid,
    this.onViewModeChanged,
  });

  @override
  State<AdaptiveFolderLayout> createState() => _AdaptiveFolderLayoutState();
}

class _AdaptiveFolderLayoutState extends State<AdaptiveFolderLayout>
    with TickerProviderStateMixin {
  late FolderLayoutConfig _config;
  AnimationController? _layoutTransitionController;
  Animation<double>? _layoutTransitionAnimation;

  @override
  void initState() {
    super.initState();
    _config = widget.config ?? const FolderLayoutConfig();
    _initializeLayoutTransition();
  }

  @override
  void didUpdateWidget(AdaptiveFolderLayout oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if layout type changed
    final oldIsSingle = oldWidget.journalsByMonth.keys.length == 1;
    final newIsSingle = widget.journalsByMonth.keys.length == 1;

    if (oldIsSingle != newIsSingle) {
      _animateLayoutTransition();
    }
  }

  @override
  void dispose() {
    _layoutTransitionController?.dispose();
    super.dispose();
  }

  void _initializeLayoutTransition() {
    _layoutTransitionController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _layoutTransitionAnimation = CurvedAnimation(
      parent: _layoutTransitionController!,
      curve: Curves.easeInOutCubic,
    );
  }

  void _animateLayoutTransition() {
    _layoutTransitionController?.forward().then((_) {
      _layoutTransitionController?.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation:
          _layoutTransitionAnimation ?? const AlwaysStoppedAnimation(0.0),
      builder: (context, child) {
        return _determineLayout(context);
      },
    );
  }

  Widget _determineLayout(BuildContext context) {
    final folderCount = widget.journalsByMonth.keys.length;
    final screenSize = MediaQuery.of(context).size;

    // Handle empty state
    if (folderCount == 0) {
      return _buildEmptyState();
    }

    // Determine layout based on folder count and screen size
    if (folderCount == 1) {
      return _buildSingleFolderView(screenSize);
    } else {
      return _buildGridView(screenSize);
    }
  }

  Widget _buildSingleFolderView(Size screenSize) {
    final monthKey = widget.journalsByMonth.keys.first;
    final entries = widget.journalsByMonth[monthKey]!;

    return SingleFolderView(
      monthKey: monthKey,
      entries: entries,
      isExpanded: widget.expandedFolderId == monthKey,
      config: _config,
      onTap: (monthKey, position) => widget.onFolderTap(monthKey, position),
    );
  }

  Widget _buildGridView(Size screenSize) {
    switch (widget.viewMode) {
      case FolderViewMode.grid:
        return FolderGridView(
          journalsByMonth: widget.journalsByMonth,
          expandedFolderId: widget.expandedFolderId,
          config: _config,
          onFolderTap: widget.onFolderTap,
        );
      case FolderViewMode.carousel:
        return FolderCarouselView(
          journalsByMonth: widget.journalsByMonth,
          expandedFolderId: widget.expandedFolderId,
          config: _config,
          onFolderTap: widget.onFolderTap,
        );
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Use the tabby journal image instead of folder icon
              Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Image.asset(
                'assets/images/tabby_journal.png',
                width: 160,
                height: 160,
                fit: BoxFit.contain,
              ),
            )
                .animate()
                .fadeIn(duration: 600.ms, delay: 200.ms)
                .scale(begin: const Offset(0.8, 0.8), duration: 400.ms, delay: 200.ms, curve: Curves.easeOutBack),
            Text(
              'No journal entries yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF115e5a),
              ),
            )
                .animate()
                .fadeIn(duration: 400.ms, delay: 600.ms)
                .slideY(begin: 0.3, duration: 400.ms, delay: 600.ms, curve: Curves.easeOut),
            const SizedBox(height: 12),
            Text(
              'Start writing your thoughts\n and memories',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            )
                .animate()
                .fadeIn(duration: 400.ms, delay: 800.ms)
                .slideY(begin: 0.3, duration: 400.ms, delay: 800.ms, curve: Curves.easeOut),
          ],
        ),
      ),
    );
  }
}

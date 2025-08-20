import 'package:flutter/material.dart';
import '../../models/realm_models.dart';
import '../../models/folder_models.dart';
import 'month_folder_card.dart';

/// Component for displaying a single centered large folder
class SingleFolderView extends StatefulWidget {
  final String monthKey;
  final List<JournalEntryRealm> entries;
  final bool isExpanded;
  final Function(String, Offset) onTap;
  final FolderLayoutConfig config;

  const SingleFolderView({
    super.key,
    required this.monthKey,
    required this.entries,
    required this.isExpanded,
    required this.onTap,
    required this.config,
  });

  @override
  State<SingleFolderView> createState() => _SingleFolderViewState();
}

class _SingleFolderViewState extends State<SingleFolderView> {
  final GlobalKey _folderKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return _buildCenteredFolder(context);
  }

  Widget _buildCenteredFolder(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    // Calculate folder size using config scale with better edge case handling
    final availableWidth = screenSize.width - widget.config.padding.horizontal;
    final baseWidth = availableWidth / widget.config.gridColumns;
    final scaledWidth = baseWidth * widget.config.singleFolderScale;

    // Ensure the folder fits well on screen with proper constraints
    final maxWidth = screenSize.width * 0.8;
    final maxHeight = screenSize.height * 0.6;
    final minWidth = 200.0;

    // Calculate final dimensions maintaining aspect ratio
    double finalWidth = scaledWidth.clamp(minWidth, maxWidth);
    double finalHeight = finalWidth / widget.config.folderAspectRatio;
    
    // If height exceeds max, adjust width to maintain aspect ratio
    if (finalHeight > maxHeight) {
      finalHeight = maxHeight;
      finalWidth = finalHeight * widget.config.folderAspectRatio;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: SizedBox(
          width: finalWidth,
          height: finalHeight,
          child: MonthFolderCard(
            monthKey: widget.monthKey,
            entries: widget.entries,
            isExpanded: widget.isExpanded,
            isLargeSize: true, // Enable large size mode
            folderKey: _folderKey,
            onTap: () => _handleFolderTap(),
          ),
        ),
      ),
    );
  }

  void _handleFolderTap() {
    if (_folderKey.currentContext != null) {
      final RenderBox renderBox = _folderKey.currentContext!.findRenderObject() as RenderBox;
      final position = renderBox.localToGlobal(Offset.zero);
      final size = renderBox.size;
      
      final centerPosition = Offset(
        position.dx + size.width / 2,
        position.dy + size.height / 2,
      );
      
      widget.onTap(widget.monthKey, centerPosition);
    } else {
      // Fallback to screen center if render box not available
      final screenSize = MediaQuery.of(context).size;
      widget.onTap(widget.monthKey, Offset(screenSize.width / 2, screenSize.height / 2));
    }
  }
}

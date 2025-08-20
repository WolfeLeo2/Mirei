import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/realm_models.dart';
import '../../models/folder_models.dart';
import 'month_folder_card.dart';

/// Main grid container for month folders
class FolderGridView extends StatefulWidget {
  final Map<String, List<JournalEntryRealm>> journalsByMonth;
  final String? expandedFolderId;
  final Function(String, Offset) onFolderTap; // Updated to include position
  final FolderLayoutConfig config;

  const FolderGridView({
    super.key,
    required this.journalsByMonth,
    this.expandedFolderId,
    required this.onFolderTap,
    required this.config,
  });

  @override
  State<FolderGridView> createState() => _FolderGridViewState();
}

class _FolderGridViewState extends State<FolderGridView> {
  final Map<String, GlobalKey> _folderKeys = {};

  @override
  Widget build(BuildContext context) {
    // Clear and recreate unique keys for grid view to prevent conflicts
    _folderKeys.clear();
    for (final monthKey in widget.journalsByMonth.keys) {
      _folderKeys[monthKey] = GlobalKey(debugLabel: 'grid_$monthKey');
    }

    return _buildGrid(context);
  }

  Widget _buildGrid(BuildContext context) {
    final sortedMonthKeys = _getSortedMonthKeys();
    final crossAxisCount = _getCrossAxisCount(context);

    return Padding(
      padding: widget.config.padding,
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: widget.config.gridSpacing,
          mainAxisSpacing: widget.config.gridSpacing,
          childAspectRatio: widget.config.folderAspectRatio,
        ),
        itemCount: sortedMonthKeys.length,
        itemBuilder: (context, index) {
          final monthKey = sortedMonthKeys[index];
          final entries = widget.journalsByMonth[monthKey]!;

          return MonthFolderCard(
            monthKey: monthKey,
            entries: entries,
            isExpanded: widget.expandedFolderId == monthKey,
            isLargeSize: false, // Grid folders are regular size
            folderKey: _folderKeys[monthKey],
            onTap: () => _handleFolderTap(monthKey),
          );
        },
      ),
    );
  }

  /// Returns chronologically sorted month keys (newest first)
  List<String> _getSortedMonthKeys() {
    final keys = widget.journalsByMonth.keys.toList();
    keys.sort((a, b) {
      final dateA = DateFormat('MMMM yyyy').parse(a);
      final dateB = DateFormat('MMMM yyyy').parse(b);
      return dateB.compareTo(dateA); // Newest first
    });
    return keys;
  }

  /// Determines grid column count - always 2×2 grid for multiple folders
  int _getCrossAxisCount(BuildContext context) {
    // Always use 2×2 grid for multiple folders
    return 2;
  }

  void _handleFolderTap(String monthKey) {
    final folderKey = _folderKeys[monthKey];
    if (folderKey?.currentContext != null) {
      final RenderBox renderBox = folderKey!.currentContext!.findRenderObject() as RenderBox;
      final position = renderBox.localToGlobal(Offset.zero);
      final size = renderBox.size;
      
      // Calculate center of the folder
      final centerPosition = Offset(
        position.dx + size.width / 2,
        position.dy + size.height / 2,
      );
      
      widget.onFolderTap(monthKey, centerPosition);
    } else {
      // Fallback to approximate position if render box not available
      final screenSize = MediaQuery.of(context).size;
      widget.onFolderTap(monthKey, Offset(screenSize.width / 2, screenSize.height * 0.4));
    }
  }

}

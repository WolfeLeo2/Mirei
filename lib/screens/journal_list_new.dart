import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/realm_models.dart';
import '../utils/realm_database_helper.dart';
import '../utils/journal_grouping_service.dart';
import '../components/journal_list/adaptive_folder_layout.dart';
import '../components/journal_list/expanded_entries_overlay.dart';
import 'journal_writing.dart';

class JournalListScreenNew extends StatefulWidget {
  const JournalListScreenNew({super.key});

  @override
  State<JournalListScreenNew> createState() => _JournalListScreenNewState();
}

class _JournalListScreenNewState extends State<JournalListScreenNew>
    with TickerProviderStateMixin {
  List<JournalEntryRealm> journals = [];
  Map<String, List<JournalEntryRealm>> journalsByMonth = {};
  bool isLoading = true;
  String? expandedFolderId;
  
  // View mode variables
  FolderViewMode _viewMode = FolderViewMode.grid;

  @override
  void initState() {
    super.initState();
    _loadJournals();
  }

  Future<void> _loadJournals() async {
    try {
      // Load real data from database
      final dbHelper = RealmDatabaseHelper();
      final loadedJournals = await dbHelper.getAllJournalEntries();

      // Group journals by month using our new service
      final groupedJournals = JournalGroupingService.groupJournalsByMonth(
        loadedJournals,
      );

      setState(() {
        journals = loadedJournals;
        journalsByMonth = groupedJournals;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading journals: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _navigateToJournalWriting() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const JournalWritingScreen()),
    );

    if (result == true) {
      await _loadJournals();
    }
  }

  Future<void> _refreshJournals() async {
    setState(() {
      isLoading = true;
    });
    await _loadJournals();
  }

  /// Toggle between grid and carousel view modes
  void _toggleViewMode() {
    setState(() {
      _viewMode = _viewMode == FolderViewMode.grid 
          ? FolderViewMode.carousel 
          : FolderViewMode.grid;
    });
  }

  void _onFolderTap(String monthKey, Offset tapPosition) {
    final entries = journalsByMonth[monthKey] ?? [];
    if (entries.isEmpty) return;

    // Show overlay with entries using actual folder position
    _showExpandedEntriesOverlay(monthKey, entries);
  }

  void _showExpandedEntriesOverlay(
    String monthKey,
    List<JournalEntryRealm> entries,
  ) {
    // Calculate folder position based on layout
    final screenSize = MediaQuery.of(context).size;
    Offset folderPosition;

    if (journalsByMonth.keys.length == 1) {
      // Single folder is centered
      folderPosition = Offset(screenSize.width / 2, screenSize.height / 2);
    } else {
      // Grid layout - approximate position based on grid
      // This is a simplified calculation - in a real implementation,
      // we'd get the actual folder widget position
      folderPosition = Offset(screenSize.width / 2, screenSize.height * 0.4);
    }

    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      barrierDismissible: false,
      builder: (context) => ExpandedEntriesOverlay(
        entries: entries,
        folderPosition: folderPosition,
        monthKey: monthKey,
        onClose: () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFd7dfe5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFd7dfe5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Color(0xFF115e5a),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'My Journal',
          style: TextStyle(
            color: const Color(0xFF115e5a),
            fontSize: 20,
            fontWeight: FontWeight.w600,
            fontFamily: GoogleFonts.inter().fontFamily,
          ),
        ),
        centerTitle: true,
        actions: [
          // View mode toggle (only show when there are multiple folders)
          if (journalsByMonth.keys.length > 1)
            IconButton(
              icon: Icon(
                _viewMode == FolderViewMode.grid ? Icons.view_carousel : Icons.grid_view,
                color: const Color(0xFF115e5a),
              ),
              onPressed: _toggleViewMode,
              tooltip: _viewMode == FolderViewMode.grid ? 'Switch to Carousel' : 'Switch to Grid',
            ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF115e5a)),
            )
          : RefreshIndicator(
              onRefresh: _refreshJournals,
              color: const Color(0xFF115e5a),
              child: AdaptiveFolderLayout(
                journalsByMonth: journalsByMonth,
                expandedFolderId: expandedFolderId,
                onFolderTap: _onFolderTap,
                viewMode: _viewMode,
                onViewModeChanged: (mode) => setState(() => _viewMode = mode),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToJournalWriting,
        backgroundColor: const Color(0xFF115e5a),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

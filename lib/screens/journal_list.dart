import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/realm_models.dart';
import '../utils/realm_database_helper.dart';
import '../utils/journal_grouping_service.dart';
import '../components/folder_card.dart';
import 'journal_writing.dart';
import 'journal_entries_screen.dart';
import '../core/theme/typography.dart';

class JournalListScreen extends StatefulWidget {
  const JournalListScreen({super.key});

  @override
  State<JournalListScreen> createState() => _JournalListScreenState();
}

class _JournalListScreenState extends State<JournalListScreen>
    with TickerProviderStateMixin {
  List<JournalEntryRealm> journals = [];
  Map<String, List<JournalEntryRealm>> journalsByMonth = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadJournals();
  }

  /// Filter out any invalidated entries from the list
  List<JournalEntryRealm> _filterValidEntries(List<JournalEntryRealm> entries) {
    return entries.where((entry) {
      try {
        // Try to access a property to check if entry is valid
        entry.createdAt;
        return true;
      } catch (e) {
        // Entry is invalidated, filter it out
        return false;
      }
    }).toList();
  }

  Future<void> _loadJournals() async {
    try {
      // Load real data from database
      final dbHelper = RealmDatabaseHelper();
      final loadedJournals = await dbHelper.getAllJournalEntries();

      // Filter out any invalidated entries
      final validJournals = _filterValidEntries(loadedJournals);

      // Group journals by month using our service
      final groupedJournals = JournalGroupingService.groupJournalsByMonth(
        validJournals,
      );

      setState(() {
        journals = validJournals;
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

  void _onFolderTap(String monthKey, List<JournalEntryRealm> entries) {
    if (entries.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            JournalEntriesScreen(monthTitle: monthKey, entries: entries),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final monthKeys = journalsByMonth.keys.toList();
    final bool isEmpty = !isLoading && monthKeys.isEmpty;
    return Scaffold(
      backgroundColor: const Color(0xFFf0efeb),
      appBar: AppBar(
        backgroundColor: const Color(0xFFf0efeb),
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
            fontFamily: AppTypography.primaryFontFamily,
          ),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF115e5a)),
            )
          : isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/tabby_journal.png',
                      width: 200,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No journal entries yet',
                      style: Theme.of(context).textTheme.bodyLarge
                          ?.copyWith(fontSize: 18, fontWeight: FontWeight.w700)
                          .apply(color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Start your first entry by tapping the + button.',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(fontSize: 13)
                          .apply(color: Colors.black54),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _refreshJournals,
              color: const Color(0xFF115e5a),
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.95,
                ),
                itemCount: monthKeys.length,
                itemBuilder: (context, index) {
                  final key = monthKeys[index];
                  final items =
                      journalsByMonth[key] ?? const <JournalEntryRealm>[];
                  return FolderCard(
                    title: key,
                    count: items.length,
                    // green for now
                    onTap: () => _onFolderTap(key, items),
                  );
                },
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

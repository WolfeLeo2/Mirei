import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/realm_models.dart';
import '../utils/realm_database_helper.dart';
import 'journal_writing.dart';
import 'journal_view.dart';
import 'package:icons_plus/icons_plus.dart';
import '../utils/emotion_colors.dart';

class JournalListScreen extends StatefulWidget {
  const JournalListScreen({super.key});

  @override
  _JournalListScreenState createState() => _JournalListScreenState();
}

class _JournalListScreenState extends State<JournalListScreen> with TickerProviderStateMixin {
  List<JournalEntryRealm> journals = [];
  Map<String, MoodEntryRealm?> dailyMoods = {};
  bool isLoading = true;
  Map<String, List<JournalEntryRealm>> journalsByMonth = {};
  Map<String, bool> expandedFolders = {};
  Map<String, AnimationController> animationControllers = {};

  @override
  void initState() {
    super.initState();
    _loadJournals();
  }

  @override
  void dispose() {
    // Dispose all animation controllers
    for (var controller in animationControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadJournals() async {
    try {
      final dbHelper = RealmDatabaseHelper();
      final loadedJournals = await dbHelper.getAllJournalEntries();
      final moodEntries = await dbHelper.getAllMoodEntries();

      final moodMap = <String, MoodEntryRealm>{};
      for (var mood in moodEntries) {
        final dateKey = DateFormat('yyyy-MM-dd').format(mood.createdAt);
        moodMap[dateKey] = mood;
      }

      // Group journals by month/year
      final groupedJournals = <String, List<JournalEntryRealm>>{};
      for (var journal in loadedJournals) {
        final monthKey = DateFormat('MMMM yyyy').format(journal.createdAt);
        if (!groupedJournals.containsKey(monthKey)) {
          groupedJournals[monthKey] = [];
          // Create animation controller for this month
          animationControllers[monthKey] = AnimationController(
            duration: const Duration(milliseconds: 400),
            vsync: this,
          );
          expandedFolders[monthKey] = false;
        }
        groupedJournals[monthKey]!.add(journal);
      }

      // Sort months in descending order (newest first)
      final sortedKeys = groupedJournals.keys.toList()
        ..sort((a, b) {
          final dateA = DateFormat('MMMM yyyy').parse(a);
          final dateB = DateFormat('MMMM yyyy').parse(b);
          return dateB.compareTo(dateA);
        });

      final sortedGroupedJournals = <String, List<JournalEntryRealm>>{};
      for (var key in sortedKeys) {
        sortedGroupedJournals[key] = groupedJournals[key]!;
        // Sort entries within each month by date (newest first)
        sortedGroupedJournals[key]!.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }

      setState(() {
        journals = loadedJournals;
        dailyMoods = moodMap;
        journalsByMonth = sortedGroupedJournals;
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
      _loadJournals();
    }
  }

  void _toggleFolder(String monthKey) {
    final controller = animationControllers[monthKey]!;
    final isExpanded = expandedFolders[monthKey] ?? false;
    
    setState(() {
      expandedFolders[monthKey] = !isExpanded;
    });

    if (!isExpanded) {
      controller.forward();
    } else {
      controller.reverse();
    }
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
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF115e5a),
              ),
            )
          : journals.isEmpty
              ? _buildEmptyState()
              : _buildJournalFolders(),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToJournalWriting,
        backgroundColor: const Color(0xFF115e5a),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.folder_open,
                size: 64,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No journal entries yet',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF115e5a),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Start writing your thoughts and memories',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJournalFolders() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: journalsByMonth.keys.length,
      itemBuilder: (context, index) {
        final monthKey = journalsByMonth.keys.elementAt(index);
        final entries = journalsByMonth[monthKey]!;
        final isExpanded = expandedFolders[monthKey] ?? false;
        final controller = animationControllers[monthKey]!;

        return _buildMonthFolder(monthKey, entries, isExpanded, controller);
      },
    );
  }

  Widget _buildMonthFolder(String monthKey, List<JournalEntryRealm> entries, 
                          bool isExpanded, AnimationController controller) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          // Folder Header
          GestureDetector(
            onTap: () => _toggleFolder(monthKey),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  // Folder Icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF115e5a).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isExpanded ? FontAwesome.folder_open : FontAwesome.folder_closed,
                      color: const Color(0xFF115e5a),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Month/Year Text
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          monthKey,
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF115e5a),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${entries.length} ${entries.length == 1 ? 'entry' : 'entries'}',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Expand/Collapse Arrow
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: const Color(0xFF115e5a),
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Animated Entries Container
          AnimatedBuilder(
            animation: controller,
            builder: (context, child) {
              return ClipRect(
                child: Align(
                  heightFactor: controller.value,
                  child: Container(
                    margin: const EdgeInsets.only(top: 8),
                    child: _buildEntriesList(entries, controller.value),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEntriesList(List<JournalEntryRealm> entries, double animationValue) {
    return Column(
      children: entries.asMap().entries.map((entry) {
        final index = entry.key;
        final journal = entry.value;
        
        // Stagger the animation for each entry
        final delay = index * 0.1;
        final entryAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animationControllers[DateFormat('MMMM yyyy').format(journal.createdAt)]!,
          curve: Interval(delay, 1.0, curve: Curves.easeOutCubic),
        ));

        return AnimatedBuilder(
          animation: entryAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, 20 * (1 - entryAnimation.value)),
              child: Opacity(
                opacity: entryAnimation.value,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: _buildJournalEntryCard(journal),
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }

  Widget _buildJournalEntryCard(JournalEntryRealm journal) {
    final dateKey = DateFormat('yyyy-MM-dd').format(journal.createdAt);
    final mood = dailyMoods[dateKey];
    final emotion = mood?.mood ?? 'Neutral';
    final color = getEmotionColor(emotion);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: () => _viewJournalEntry(journal),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date and Mood Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('EEEE, MMM d').format(journal.createdAt),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                  Row(
                    children: [
                      _buildEmotionChip(emotion, color),
                      const SizedBox(width: 8),
                      PopupMenuButton<String>(
                        onSelected: (String value) {
                          switch (value) {
                            case 'view':
                              _viewJournalEntry(journal);
                              break;
                            case 'delete':
                              _deleteJournalEntry(journal);
                              break;
                          }
                        },
                        itemBuilder: (BuildContext context) => [
                          PopupMenuItem<String>(
                            value: 'view',
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.visibility,
                                  color: Color(0xFF115e5a),
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'View',
                                  style: GoogleFonts.inter(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'delete',
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Delete',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        icon: Icon(
                          Icons.more_vert,
                          color: Colors.grey[400],
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Title (if exists)
              if (journal.title.isNotEmpty) ...[
                Text(
                  journal.title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF115e5a),
                  ),
                ),
                const SizedBox(height: 6),
              ],
              // Content Preview
              Text(
                journal.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
              // Media indicators
              if (journal.imagePaths.isNotEmpty || journal.audioRecordings.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (journal.imagePaths.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.image, size: 14, color: Colors.blue[600]),
                            const SizedBox(width: 4),
                            Text(
                              '${journal.imagePaths.length}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.blue[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (journal.imagePaths.isNotEmpty && journal.audioRecordings.isNotEmpty)
                      const SizedBox(width: 8),
                    if (journal.audioRecordings.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.mic, size: 14, color: Colors.orange[600]),
                            const SizedBox(width: 4),
                            Text(
                              '${journal.audioRecordings.length}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.orange[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmotionChip(String emotion, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        emotion,
        style: GoogleFonts.inter(
          color: color,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }

  Future<void> _deleteJournalEntry(JournalEntryRealm entry) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Delete Journal Entry',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF115e5a),
            ),
          ),
          content: Text(
            'Are you sure you want to delete this journal entry? This action cannot be undone.',
            style: GoogleFonts.inter(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(color: Colors.grey[600]),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                'Delete',
                style: GoogleFonts.inter(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        final dbHelper = RealmDatabaseHelper();
        await dbHelper.deleteJournalEntry(entry.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
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

          _loadJournals();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
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
    }
  }

  void _viewJournalEntry(JournalEntryRealm entry) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => JournalViewScreen(entry: entry)),
    );
  }
}

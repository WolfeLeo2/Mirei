import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/realm_models.dart';
import '../utils/realm_database_helper.dart';
import 'journal_writing.dart';
import 'journal_view.dart';
import '../utils/emotion_colors.dart';
import 'package:animations/animations.dart';

class JournalListScreen extends StatefulWidget {
  const JournalListScreen({super.key});

  @override
  _JournalListScreenState createState() => _JournalListScreenState();
}

class _JournalListScreenState extends State<JournalListScreen> {
  List<JournalEntryRealm> journals = [];
  Map<String, MoodEntryRealm?> dailyMoods = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadJournals();
  }

  Future<void> _loadJournals() async {
    try {
      final dbHelper = RealmDatabaseHelper();
      final loadedJournals = await dbHelper.getAllJournalEntries();
      final moodEntries = await dbHelper.getAllMoodEntries();

      final moodMap = <String, MoodEntryRealm>{};
      for (var mood in moodEntries) {
        final dateKey = DateFormat('yyyy-MM-dd').format(mood.createdAt);
        // Always store the most recent mood for the day
        moodMap[dateKey] = mood;
      }

      setState(() {
        journals = loadedJournals;
        dailyMoods = moodMap;
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
      _loadJournals(); // Reload journals if something was saved
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFfaf6f1),
      appBar: AppBar(
        backgroundColor: const Color(0xFFfaf6f1),
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
              child: CircularProgressIndicator(color: Color(0xFF115e5a)),
            )
          : journals.isEmpty
          ? _buildEmptyState()
          : _buildJournalList(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildFloatingActionButton() {
    if (journals.isEmpty) {
      return const SizedBox.shrink(); // Hide FAB if no entries
    }
    return OpenContainer(
      closedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
      transitionType: ContainerTransitionType.fade,
      openShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
      closedColor: const Color(0xFF115e5a),
      closedBuilder: (context, openContainer) => Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: const Color(0xFF115e5a),
          borderRadius: BorderRadius.circular(16),
        ),
        child: IconButton(
          onPressed: openContainer,
          icon: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
      openBuilder: (context, closeContainer) => const JournalWritingScreen(),
      transitionDuration: const Duration(milliseconds: 500),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset('assets/icons/Stress.svg', height: 200),
            const SizedBox(height: 24),
            Text(
              'Start keeping track of your days',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF115e5a),
                fontFamily: GoogleFonts.inter().fontFamily,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Capture your thoughts, feelings, and memories.\nYour personal space to reflect and grow.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
                fontFamily: GoogleFonts.inter().fontFamily,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            GestureDetector(
              onTap: _navigateToJournalWriting,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF115e5a),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJournalList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: journals.length,
      itemBuilder: (context, index) {
        final journal = journals[index];
        return _buildJournalCard(journal);
      },
    );
  }

  Widget _buildJournalCard(JournalEntryRealm journal) {
    final dateKey = DateFormat('yyyy-MM-dd').format(journal.createdAt);
    final mood = dailyMoods[dateKey];
    final emotion = mood?.mood ?? 'Neutral';
    final color = getEmotionColor(emotion);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: InkWell(
        onTap: () => _viewJournalEntry(journal),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('MMMM d, yyyy').format(journal.createdAt),
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
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
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'View Entry',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w500,
                                  ),
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
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Delete Entry',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        icon: Icon(
                          Icons.more_vert,
                          color: Colors.grey[600],
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (journal.title.isNotEmpty) ...[
                Text(
                  journal.title,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Text(
                journal.content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.black54,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmotionChip(String emotion, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        emotion,
        style: GoogleFonts.inter(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  Future<void> _deleteJournalEntry(JournalEntryRealm entry) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
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

          // Reload the journals
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

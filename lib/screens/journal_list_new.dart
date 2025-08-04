import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'journal_writing.dart';
import '../models/journal_entry.dart';
import '../utils/database_helper.dart';
import 'mood_tracker.dart';

class JournalListScreen extends StatefulWidget {
  const JournalListScreen({super.key});

  @override
  _JournalListScreenState createState() => _JournalListScreenState();
}

class _JournalListScreenState extends State<JournalListScreen> {
  List<JournalEntry> journals = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadJournals();
  }

  Future<void> _loadJournals() async {
    try {
      final dbHelper = DatabaseHelper();
      final loadedJournals = await dbHelper.getAllJournalEntries();
      setState(() {
        journals = loadedJournals;
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

  Future<void> _navigateToMoodTracker() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MoodTrackerScreen()),
    );
    
    // Reload journals if a new entry was saved
    if (result == true) {
      _loadJournals();
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
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF115e5a)))
        : journals.isEmpty 
          ? _buildEmptyState() 
          : _buildJournalList(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildFloatingActionButton() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFF115e5a),
        borderRadius: BorderRadius.circular(16), // Squircle shape
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: _navigateToMoodTracker,
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/icons/message.svg',
              height: 120,
              colorFilter: ColorFilter.mode(
                Colors.grey.withOpacity(0.3),
                BlendMode.srcIn,
              ),
            ),
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
              'Every day is a new chapter. Write your story and capture your memories, one journal entry at a time.',
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
              onTap: _navigateToMoodTracker,
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
      padding: const EdgeInsets.all(20),
      itemCount: journals.length,
      itemBuilder: (context, index) {
        final journal = journals[index];
        return GestureDetector(
          onTap: () => _viewJournalEntry(journal),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('MMM dd, yyyy').format(journal.createdAt),
                      style: TextStyle(
                        color: const Color(0xFF115e5a),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: GoogleFonts.inter().fontFamily,
                      ),
                    ),
                    if (journal.mood != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF115e5a).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          journal.mood!,
                          style: TextStyle(
                            color: const Color(0xFF115e5a),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            fontFamily: GoogleFonts.inter().fontFamily,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  journal.title,
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    fontFamily: GoogleFonts.inter().fontFamily,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  journal.content,
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    fontFamily: GoogleFonts.inter().fontFamily,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                if (journal.imagePaths.isNotEmpty || journal.audioRecordings.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      children: [
                        if (journal.imagePaths.isNotEmpty) ...[
                          Icon(
                            Icons.photo,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${journal.imagePaths.length}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontFamily: GoogleFonts.inter().fontFamily,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        if (journal.audioRecordings.isNotEmpty) ...[
                          Icon(
                            Icons.mic,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${journal.audioRecordings.length}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontFamily: GoogleFonts.inter().fontFamily,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _viewJournalEntry(JournalEntry entry) {
    // TODO: Navigate to journal detail view
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Journal detail view coming soon!'),
        backgroundColor: Color(0xFF115e5a),
      ),
    );
  }
}

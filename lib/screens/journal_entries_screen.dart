import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import '../models/realm_models.dart';
import '../components/entry_card.dart';
import 'journal_view.dart';
import '../core/theme/typography.dart';

class JournalEntriesScreen extends StatelessWidget {
  final String monthTitle;
  final List<JournalEntryRealm> entries;

  const JournalEntriesScreen({
    super.key,
    required this.monthTitle,
    required this.entries,
  });

  /// Filter out invalidated entries
  List<JournalEntryRealm> _getValidEntries() {
    return entries.where((entry) {
      try {
        // Try to access a property to check if entry is valid
        entry.createdAt;
        return true;
      } catch (e) {
        // Entry is invalidated (deleted), filter it out
        return false;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final validEntries = _getValidEntries();
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
          monthTitle,
          style: TextStyle(
            color: const Color(0xFF115e5a),
            fontSize: 20,
            fontWeight: FontWeight.w600,
            fontFamily: AppTypography.primaryFontFamily,
          ),
        ),
        centerTitle: true,
      ),
      body: validEntries.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.folder_open, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'No entries found',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                      fontFamily: AppTypography.primaryFontFamily,
                    ),
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, // 3 columns as requested
                crossAxisSpacing: 12,
                mainAxisSpacing: 16,
                childAspectRatio:
                    0.65, // Adjust for 3 columns + title/date space
              ),
              itemCount: validEntries.length,
              itemBuilder: (context, index) {
                final entry = validEntries[index];
                return OpenContainer(
                  transitionType: ContainerTransitionType.fade,
                  transitionDuration: const Duration(milliseconds: 500),
                  openColor: const Color(0xFFf0efeb),
                  closedColor: Colors.transparent,
                  closedElevation: 0,
                  openElevation: 0,
                  closedShape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  closedBuilder: (context, action) =>
                      EntryCard(entry: entry, onTap: action),
                  openBuilder: (context, action) =>
                      JournalViewScreen(entry: entry),
                );
              },
            ),
    );
  }
}

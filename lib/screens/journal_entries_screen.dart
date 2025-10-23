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

  @override
  Widget build(BuildContext context) {
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
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, // 3 columns as requested
          crossAxisSpacing: 12,
          mainAxisSpacing: 16,
          childAspectRatio: 0.65, // Adjust for 3 columns + title/date space
        ),
        itemCount: entries.length,
        itemBuilder: (context, index) {
          final entry = entries[index];
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
            openBuilder: (context, action) => JournalViewScreen(entry: entry),
          );
        },
      ),
    );
  }
}

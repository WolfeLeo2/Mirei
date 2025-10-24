import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../components/folder_card.dart';
import '../../core/theme/typography.dart';
import '../../models/realm_models.dart';
import '../../utils/journal_grouping_service.dart';
import '../../utils/realm_database_helper.dart';
import '../journal_entries_screen.dart';

class DiaryJournalsTab extends StatefulWidget {
  const DiaryJournalsTab({super.key});

  @override
  State<DiaryJournalsTab> createState() => DiaryJournalsTabState();
}

class DiaryJournalsTabState extends State<DiaryJournalsTab>
    with AutomaticKeepAliveClientMixin {
  final RealmDatabaseHelper _dbHelper = RealmDatabaseHelper();
  Map<String, List<JournalEntryRealm>> _grouped = {};
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _loadJournals();
  }

  Future<void> refresh() async {
    await _loadJournals();
  }

  Future<void> _loadJournals() async {
    setState(() {
      _loading = true;
      _error = false;
    });

    try {
      final journals = await _dbHelper.getAllJournalEntries();
      final valid = journals.where((entry) {
        try {
          entry.createdAt;
          return true;
        } catch (_) {
          return false;
        }
      }).toList();

      final grouped = JournalGroupingService.groupJournalsByMonth(valid);

      if (!mounted) return;
      setState(() {
        _grouped = grouped;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  void _openFolder(String monthKey, List<JournalEntryRealm> entries) {
    if (entries.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            JournalEntriesScreen(monthTitle: monthKey, entries: entries),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final keys = _grouped.keys.toList();
    final isEmpty = !_loading && keys.isEmpty && !_error;

    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF115e5a)),
      );
    }

    if (_error) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 36),
            const SizedBox(height: 12),
            Text(
              'Could not load journals',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(onPressed: _loadJournals, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                'assets/images/empty_journals.svg',
                width: 250,
                height: 250,
              ),
              const SizedBox(height: 16),
              Text(
                'No journal entries yet',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontFamily: AppTypography.primaryFontFamily,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadJournals,
      color: const Color(0xFF115e5a),
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.95,
        ),
        itemCount: keys.length,
        itemBuilder: (context, index) {
          final key = keys[index];
          final entries = _grouped[key] ?? const <JournalEntryRealm>[];
          return FolderCard(
            title: key,
            count: entries.length,
            onTap: () => _openFolder(key, entries),
          );
        },
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

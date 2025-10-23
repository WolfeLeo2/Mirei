import 'package:flutter/material.dart';
import 'package:floating_bottom_navigation_bar/floating_bottom_navigation_bar.dart';

import '../journal_writing.dart';
import 'diary_journals_tab.dart';
import 'diary_memories_tab.dart';
import 'memory_composer_screen.dart';

enum _DiaryTab { journals, memories }

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  final GlobalKey<DiaryJournalsTabState> _journalsKey =
      GlobalKey<DiaryJournalsTabState>();
  final GlobalKey<DiaryMemoriesTabState> _memoriesKey =
      GlobalKey<DiaryMemoriesTabState>();

  _DiaryTab _currentTab = _DiaryTab.journals;

  @override
  Widget build(BuildContext context) {
    final isJournalTab = _currentTab == _DiaryTab.journals;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F6),
      appBar: AppBar(
        title: const Text('Diary'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 80),
          child: IndexedStack(
            index: _currentTab.index,
            children: [
              DiaryJournalsTab(key: _journalsKey),
              DiaryMemoriesTab(key: _memoriesKey),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: _handleCreate,
        backgroundColor: const Color(0xFF115e5a),
        child: Icon(
          isJournalTab
              ? Icons.edit_note_outlined
              : Icons.add_photo_alternate_outlined,
        ),
      ),
      bottomNavigationBar: FloatingNavbar(
        currentIndex: _currentTab.index,
        onTap: (index) {
          setState(() {
            _currentTab = _DiaryTab.values[index];
          });
        },
        items: [
          FloatingNavbarItem(title: 'Journals', icon: Icons.book_outlined),
          FloatingNavbarItem(
            title: 'Memories',
            icon: Icons.photo_library_outlined,
          ),
        ],
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF115e5a),
        unselectedItemColor: const Color(0xFF6A7F81),
        selectedBackgroundColor: const Color(0xFFE6F4F3),
        borderRadius: 16,
        itemBorderRadius: 12,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        elevation: 8,
      ),
    );
  }

  Future<void> _handleCreate() async {
    if (_currentTab == _DiaryTab.journals) {
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const JournalWritingScreen()),
      );
      if (result == true) {
        _journalsKey.currentState?.refresh();
      }
    } else {
      final created = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const MemoryComposerScreen()),
      );
      if (created == true) {
        _memoriesKey.currentState?.refresh();
      }
    }
  }
}

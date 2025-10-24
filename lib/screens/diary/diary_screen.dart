import 'package:flutter/material.dart';
import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';

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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Diary'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: IndexedStack(
        index: _currentTab.index,
        children: [
          DiaryJournalsTab(key: _journalsKey),
          DiaryMemoriesTab(key: _memoriesKey),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _handleCreate,
        backgroundColor: const Color(0xFF115e5a),
        elevation: 4,
        shape: const CircleBorder(),
        child: Icon(
          isJournalTab
              ? Icons.edit_note_outlined
              : Icons.add_photo_alternate_outlined,
          color: Colors.white,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: AnimatedBottomNavigationBar(
        icons: const [Icons.book_outlined, Icons.photo_library_outlined],
        activeIndex: _currentTab.index,
        onTap: (index) {
          setState(() {
            _currentTab = _DiaryTab.values[index];
          });
        },
        gapLocation: GapLocation.center,
        notchSmoothness: NotchSmoothness.verySmoothEdge,
        leftCornerRadius: 16,
        rightCornerRadius: 16,
        backgroundColor: Colors.white,
        activeColor: const Color(0xFF115e5a),
        inactiveColor: const Color(0xFF6A7F81),
        splashColor: const Color(0xFFE6F4F3),
        splashSpeedInMilliseconds: 300,
        elevation: 8,
        height: 65,
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

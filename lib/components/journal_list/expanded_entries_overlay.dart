import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:hyper_effects/hyper_effects.dart';
import '../../models/realm_models.dart';
import '../../utils/realm_database_helper.dart';
import 'scattered_entry_card.dart';

/// Full-screen overlay that handles the expanded folder state with performance optimizations
class ExpandedEntriesOverlay extends StatefulWidget {
  final List<JournalEntryRealm> entries;
  final Offset folderPosition;
  final VoidCallback onClose;
  final String monthKey;

  const ExpandedEntriesOverlay({
    super.key,
    required this.entries,
    required this.folderPosition,
    required this.onClose,
    required this.monthKey,
  });

  @override
  State<ExpandedEntriesOverlay> createState() => _ExpandedEntriesOverlayState();
}

class _ExpandedEntriesOverlayState extends State<ExpandedEntriesOverlay>
    with TickerProviderStateMixin {
  late AnimationController _blurController;
  late Animation<double> _blurAnimation;
  
  Map<String, MoodEntryRealm?> _dailyMoods = {};
  bool _isExpanded = false;
  bool _isMoodDataLoaded = false;
  
  // Performance optimizations
  late final List<JournalEntryRealm> _optimizedEntries;
  static const int _maxVisibleEntries = 100; // Limit for performance

  @override
  void initState() {
    super.initState();
    _optimizeEntries();
    _initializeAnimations();
    _loadMoodDataLazy();
    
    // Start the expansion animation after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _isExpanded = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _blurController.dispose();
    super.dispose();
  }

  /// Optimize entries list for better performance
  void _optimizeEntries() {
    // Limit entries to improve scrolling performance
    _optimizedEntries = widget.entries.take(_maxVisibleEntries).toList();
  }

  void _initializeAnimations() {
    _blurController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _blurAnimation = CurvedAnimation(
      parent: _blurController,
      curve: Curves.easeInOutCubic,
    );
    
    _blurController.forward();
  }

  /// Load mood data lazily in background
  Future<void> _loadMoodDataLazy() async {
    try {
      final dbHelper = RealmDatabaseHelper();
      final moodEntries = await dbHelper.getAllMoodEntries();

      final moodMap = <String, MoodEntryRealm>{};
      for (var mood in moodEntries) {
        final dateKey = DateFormat('yyyy-MM-dd').format(mood.createdAt);
        moodMap[dateKey] = mood;
      }

      if (mounted) {
        setState(() {
          _dailyMoods = moodMap;
          _isMoodDataLoaded = true;
        });
      }
    } catch (e) {
      // Handle error silently and continue without mood data
      if (mounted) {
        setState(() {
          _isMoodDataLoaded = true;
        });
      }
    }
  }

  /// Calculate cross-axis count based on entry count for optimal performance
  int _getCrossAxisCount() {
    final entryCount = _optimizedEntries.length;
    if (entryCount <= 6) return 2; // 2 columns for few entries
    if (entryCount <= 12) return 3; // 3 columns for moderate entries
    return 3; // Always 3 columns for optimal spacing
  }

  Future<void> _closeOverlay() async {
    setState(() {
      _isExpanded = false;
    });
    
    // Wait for animations to complete before closing
    final maxDelay = math.min(_optimizedEntries.length * 40, 2000); // Cap at 2s
    const animationDuration = 300;
    await Future.delayed(Duration(milliseconds: maxDelay + animationDuration));
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Blurred background
          _buildBlurredBackground(),

          // Optimized Grid View with lazy loading
          Positioned.fill(
            top: padding.top + 80, // Account for title area
            left: 0,
            right: 0,
            bottom: 0,
            child: _OptimizedGridView(
              entries: _optimizedEntries,
              dailyMoods: _dailyMoods,
              isExpanded: _isExpanded,
              folderPosition: widget.folderPosition,
              screenSize: screenSize,
              crossAxisCount: _getCrossAxisCount(),
            ),
          ),

          // Close button
          _buildCloseButton(),

          // Month title
          _buildMonthTitle(),
        ],
      ),
    );
  }

  Widget _buildBlurredBackground() {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _blurAnimation,
        builder: (context, child) {
          return GestureDetector(
            onTap: _closeOverlay,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Color.lerp(Colors.transparent, const Color(0x4D000000), _blurAnimation.value),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(
                  sigmaX: 10 * _blurAnimation.value,
                  sigmaY: 10 * _blurAnimation.value,
                ),
                child: Container(color: Colors.transparent),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCloseButton() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      right: 16,
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _blurAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: _blurAnimation.value,
              child: GestureDetector(
                onTap: _closeOverlay,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Color(0xE6FFFFFF), // Use const color
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Color(0xFF115e5a),
                    size: 24,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMonthTitle() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _blurAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: _blurAnimation.value,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: Color(0xE6FFFFFF), // Use const color
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  widget.monthKey,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF115e5a),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Separate optimized grid view widget for better performance
class _OptimizedGridView extends StatelessWidget {
  final List<JournalEntryRealm> entries;
  final Map<String, MoodEntryRealm?> dailyMoods;
  final bool isExpanded;
  final Offset folderPosition;
  final Size screenSize;
  final int crossAxisCount;

  const _OptimizedGridView({
    required this.entries,
    required this.dailyMoods,
    required this.isExpanded,
    required this.folderPosition,
    required this.screenSize,
    required this.crossAxisCount,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 150 / 200, // Fixed aspect ratio for 150×200 cards
        ),
        padding: const EdgeInsets.fromLTRB(16, 5, 16, 100),
        physics: const ClampingScrollPhysics(),
        itemCount: entries.length,
        itemBuilder: (context, index) {
          final journalEntry = entries[index];
          
          return _AnimatedEntryCard(
            entry: journalEntry,
            mood: _getMoodForEntry(journalEntry),
            index: index,
            isExpanded: isExpanded,
            folderPosition: folderPosition,
            screenSize: screenSize,
          );
        },
      ),
    );
  }

  MoodEntryRealm? _getMoodForEntry(JournalEntryRealm entry) {
    final dateKey = DateFormat('yyyy-MM-dd').format(entry.createdAt);
    return dailyMoods[dateKey];
  }
}

/// Separate animated entry card widget to optimize rebuilds
class _AnimatedEntryCard extends StatelessWidget {
  final JournalEntryRealm entry;
  final MoodEntryRealm? mood;
  final int index;
  final bool isExpanded;
  final Offset folderPosition;
  final Size screenSize;

  const _AnimatedEntryCard({
    required this.entry,
    this.mood,
    required this.index,
    required this.isExpanded,
    required this.folderPosition,
    required this.screenSize,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ScatteredEntryCard(
        entry: entry,
        mood: mood,
      )
        .scale(isExpanded ? 1.0 : 0.0)
        .opacity(isExpanded ? 1.0 : 0.0)
        .translateXY(
          isExpanded ? 0 : (folderPosition.dx - screenSize.width / 2) * 0.5,
          isExpanded ? 0 : (folderPosition.dy - screenSize.height / 2) * 0.5,
        )
        .rotate(
          isExpanded ? (math.Random(index + 123).nextDouble() - 0.5) * 0.1 : 0,
        )
        .animate(
          trigger: isExpanded,
          duration: Duration(milliseconds: 300 + index * 15), // Faster stagger
          curve: Curves.easeOutCubic,
          delay: Duration(milliseconds: index * 30), // Faster delay
        ),
    );
  }
}

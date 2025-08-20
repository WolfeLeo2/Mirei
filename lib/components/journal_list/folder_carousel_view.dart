import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/realm_models.dart';
import '../../models/folder_models.dart';
import 'month_folder_card.dart';

/// Simple horizontal carousel slider for month folders
class FolderCarouselView extends StatefulWidget {
  final Map<String, List<JournalEntryRealm>> journalsByMonth;
  final String? expandedFolderId;
  final Function(String, Offset) onFolderTap;
  final FolderLayoutConfig config;

  const FolderCarouselView({
    super.key,
    required this.journalsByMonth,
    this.expandedFolderId,
    required this.onFolderTap,
    required this.config,
  });

  @override
  State<FolderCarouselView> createState() => _FolderCarouselViewState();
}

class _FolderCarouselViewState extends State<FolderCarouselView> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction: 0.8, // Show parts of adjacent cards
      initialPage: 0,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sortedMonthKeys = _getSortedMonthKeys();

    if (sortedMonthKeys.isEmpty) {
      return const SizedBox.shrink();
    }

    final screenWidth = MediaQuery.of(context).size.width;
    
    // Responsive card sizing based on screen width
    final cardWidth = (screenWidth * 0.7).clamp(250.0, 300.0); // Slightly smaller for better centering
    final cardHeight = cardWidth * (4/3); // Maintain aspect ratio

    return Center( // Center the entire carousel
      child: SizedBox(
        height: cardHeight + 60, // Extra space for padding and indicators
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Main carousel
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: sortedMonthKeys.length,
                itemBuilder: (context, index) {
                  final monthKey = sortedMonthKeys[index];
                  final entries = widget.journalsByMonth[monthKey]!;
                  
                  return Center( // Center each card
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 20.0),
                      child: SizedBox(
                        width: cardWidth,
                        height: cardHeight,
                        child: MonthFolderCard(
                          monthKey: monthKey,
                          entries: entries,
                          isExpanded: widget.expandedFolderId == monthKey,
                          isLargeSize: false,
                          folderKey: null, // Removed GlobalKey
                          onTap: () => _handleFolderTap(monthKey),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Page indicators
            if (sortedMonthKeys.length > 1)
              _buildPageIndicators(sortedMonthKeys.length),
          ],
        ),
      ),
    );
  }

  /// Build simple dot indicators
  Widget _buildPageIndicators(int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(count, (index) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4.0),
            height: 8.0,
            width: _currentPage == index ? 24.0 : 8.0,
            decoration: BoxDecoration(
              color: _currentPage == index 
                  ? const Color(0xFF115e5a) 
                  : const Color(0xFF115e5a).withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(4.0),
            ),
          );
        }),
      ),
    );
  }

  /// Returns chronologically sorted month keys (newest first)
  List<String> _getSortedMonthKeys() {
    final keys = widget.journalsByMonth.keys.toList();
    keys.sort((a, b) {
      final dateA = DateFormat('MMMM yyyy').parse(a);
      final dateB = DateFormat('MMMM yyyy').parse(b);
      return dateB.compareTo(dateA); // Newest first
    });
    return keys;
  }

  void _handleFolderTap(String monthKey) {
    // For carousel view, we can use a simple center position since cards are centered
    final screenSize = MediaQuery.of(context).size;
    final centerPosition = Offset(screenSize.width / 2, screenSize.height * 0.4);
    widget.onFolderTap(monthKey, centerPosition);
  }
} 
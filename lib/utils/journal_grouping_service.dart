import 'package:intl/intl.dart';
import '../models/realm_models.dart';

/// Service for grouping and organizing journal entries by month/year
class JournalGroupingService {
  /// Groups journal entries by month and year
  static Map<String, List<JournalEntryRealm>> groupJournalsByMonth(
    List<JournalEntryRealm> journals,
  ) {
    final groupedJournals = <String, List<JournalEntryRealm>>{};

    for (final journal in journals) {
      final monthKey = _getMonthKey(journal.createdAt);

      if (!groupedJournals.containsKey(monthKey)) {
        groupedJournals[monthKey] = [];
      }

      groupedJournals[monthKey]!.add(journal);
    }

    // Sort entries within each month by date (newest first)
    for (final entries in groupedJournals.values) {
      entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return groupedJournals;
  }

  /// Returns chronologically sorted month keys (newest first)
  static List<String> getSortedMonthKeys(
    Map<String, List<JournalEntryRealm>> groupedJournals,
  ) {
    final keys = groupedJournals.keys.toList();

    keys.sort((a, b) {
      try {
        final dateA = DateFormat('MMMM yyyy').parse(a);
        final dateB = DateFormat('MMMM yyyy').parse(b);
        return dateB.compareTo(dateA); // Newest first
      } catch (e) {
        // Fallback to string comparison if date parsing fails
        return b.compareTo(a);
      }
    });

    return keys;
  }

  /// Extracts preview image from most recent entry in a month
  static String? getPreviewImageForMonth(List<JournalEntryRealm> entries) {
    if (entries.isEmpty) return null;

    // Entries should already be sorted by date (newest first)
    for (final entry in entries) {
      if (entry.imagePaths.isNotEmpty) {
        return entry.imagePaths.first;
      }
    }

    return null; // No images found in this month
  }

  /// Gets statistics for a month's entries
  static MonthStatistics getMonthStatistics(List<JournalEntryRealm> entries) {
    if (entries.isEmpty) {
      return MonthStatistics(
        entryCount: 0,
        imageCount: 0,
        audioCount: 0,
        firstEntryDate: null,
        lastEntryDate: null,
      );
    }

    int imageCount = 0;
    int audioCount = 0;

    for (final entry in entries) {
      imageCount += entry.imagePaths.length;
      audioCount += entry.audioRecordings.length;
    }

    // Entries are sorted newest first
    final lastEntryDate = entries.first.createdAt;
    final firstEntryDate = entries.last.createdAt;

    return MonthStatistics(
      entryCount: entries.length,
      imageCount: imageCount,
      audioCount: audioCount,
      firstEntryDate: firstEntryDate,
      lastEntryDate: lastEntryDate,
    );
  }

  /// Filters journals by date range
  static List<JournalEntryRealm> filterJournalsByDateRange(
    List<JournalEntryRealm> journals,
    DateTime startDate,
    DateTime endDate,
  ) {
    return journals.where((journal) {
      return journal.createdAt.isAfter(startDate) &&
          journal.createdAt.isBefore(endDate);
    }).toList();
  }

  /// Searches journals by content
  static List<JournalEntryRealm> searchJournals(
    List<JournalEntryRealm> journals,
    String query,
  ) {
    if (query.isEmpty) return journals;

    final lowercaseQuery = query.toLowerCase();

    return journals.where((journal) {
      return journal.title.toLowerCase().contains(lowercaseQuery) ||
          journal.content.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  /// Generates month key from date
  static String _getMonthKey(DateTime date) {
    return DateFormat('MMMM yyyy').format(date);
  }

  /// Validates that a month key is properly formatted
  static bool isValidMonthKey(String monthKey) {
    try {
      DateFormat('MMMM yyyy').parse(monthKey);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Converts month key back to DateTime (first day of month)
  static DateTime? monthKeyToDate(String monthKey) {
    try {
      return DateFormat('MMMM yyyy').parse(monthKey);
    } catch (e) {
      return null;
    }
  }
}

/// Statistics for a month's journal entries
class MonthStatistics {
  final int entryCount;
  final int imageCount;
  final int audioCount;
  final DateTime? firstEntryDate;
  final DateTime? lastEntryDate;

  const MonthStatistics({
    required this.entryCount,
    required this.imageCount,
    required this.audioCount,
    this.firstEntryDate,
    this.lastEntryDate,
  });

  /// Whether this month has any media content
  bool get hasMedia => imageCount > 0 || audioCount > 0;

  /// Duration span of entries in this month
  Duration? get entrySpan {
    if (firstEntryDate == null || lastEntryDate == null) return null;
    return lastEntryDate!.difference(firstEntryDate!);
  }

  @override
  String toString() {
    return 'MonthStatistics(entries: $entryCount, images: $imageCount, audio: $audioCount)';
  }
}

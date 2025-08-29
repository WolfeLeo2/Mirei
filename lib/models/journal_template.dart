import 'package:intl/intl.dart';

class JournalTemplate {
  final String id;
  final String name;
  final String emoji;
  final String category;
  final String titleTemplate;
  final String contentTemplate;
  final String description;

  const JournalTemplate({
    required this.id,
    required this.name,
    required this.emoji,
    required this.category,
    required this.titleTemplate,
    required this.contentTemplate,
    required this.description,
  });

  /// Generate actual title with current date substitution
  String getFilledTitle() {
    final now = DateTime.now();
    final dateStr = DateFormat('MMMM d, yyyy').format(now);
    return titleTemplate.replaceAll('{date}', dateStr);
  }

  /// Generate actual content (for future dynamic substitutions)
  String getFilledContent() {
    // For now, just return the template as-is
    // Future: Could add more dynamic substitutions like {time}, {weather}, etc.
    return contentTemplate;
  }
}

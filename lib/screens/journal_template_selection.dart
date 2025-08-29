import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/journal_template.dart';
import '../data/journal_templates.dart';
import 'journal_writing.dart';

class JournalTemplateSelectionScreen extends StatelessWidget {
  const JournalTemplateSelectionScreen({super.key});

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
          'Start Writing',
          style: GoogleFonts.inter(
            color: const Color(0xFF115e5a),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Blank entry option (prominent)
            _buildBlankEntryCard(context),

            const SizedBox(height: 24),

            // Templates section header
            Text(
              'Or choose a template:',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 16),

            // Template categories
            Expanded(
              child: ListView(
                children: JournalTemplates.categorizedTemplates.entries.map((
                  entry,
                ) {
                  return _buildTemplateCategory(
                    context,
                    entry.key,
                    entry.value,
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlankEntryCard(BuildContext context) {
    return GestureDetector(
      onTap: () => _navigateToWriting(context, null),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF115e5a), width: 2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF115e5a).withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF115e5a).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.edit_outlined,
                color: Color(0xFF115e5a),
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Blank Entry',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Start with a clean slate',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Color(0xFF115e5a),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateCategory(
    BuildContext context,
    String categoryName,
    List<JournalTemplate> templates,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category header
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            categoryName,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF115e5a),
            ),
          ),
        ),

        // Template cards
        ...templates.map((template) => _buildTemplateCard(context, template)),

        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTemplateCard(BuildContext context, JournalTemplate template) {
    return GestureDetector(
      onTap: () => _navigateToWriting(context, template),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Template emoji/icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF115e5a).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  template.emoji,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Template info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.name,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    template.description,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.black26,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToWriting(
    BuildContext context,
    JournalTemplate? template,
  ) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JournalWritingScreen(initialTemplate: template),
      ),
    );

    if (result == true && context.mounted) {
      // Return to journal list with refresh signal
      Navigator.pop(context, true);
    }
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/realm_models.dart';
import '../utils/realm_database_helper.dart';
import 'package:realm/realm.dart';

class JournalViewScreen extends StatelessWidget {
  final JournalEntryRealm entry;

  const JournalViewScreen({super.key, required this.entry});

  /// Safely access a Realm object property with error handling
  T? _safeAccess<T>(T Function() accessor, [T? defaultValue]) {
    try {
      return accessor();
    } catch (e) {
      if (e is RealmException && e.message.contains('invalidated')) {
        // Object has been deleted, return default value
        return defaultValue;
      }
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Safely access entry properties
    final title = _safeAccess(() => entry.title, '') ?? '';
    final content = _safeAccess(() => entry.content, '') ?? '';
    final createdAt = _safeAccess(() => entry.createdAt);
    final imagePaths =
        _safeAccess(() => entry.imagePaths, <String>[]) ?? <String>[];
    final audioRecordings =
        _safeAccess(() => entry.audioRecordings, <AudioRecordingData>[]) ??
        <AudioRecordingData>[];

    // If the entry has been invalidated, show an error screen
    if (createdAt == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFd7dfe5),
        appBar: AppBar(
          backgroundColor: const Color(0xFFd7dfe5),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF115e5a)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'Journal Entry',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF115e5a),
            ),
          ),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Color(0xFF115e5a),
              ),
              const SizedBox(height: 16),
              Text(
                'Entry Not Found',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2D3748),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This journal entry has been deleted or is no longer available.',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: const Color(0xFF718096),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF115e5a),
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  'Go Back',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');
    final hasImages = imagePaths.isNotEmpty;
    final hasAudio = audioRecordings.isNotEmpty;
    final hasAttachments = hasImages || hasAudio;

    return Scaffold(
      backgroundColor: const Color(0xFFd7dfe5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFd7dfe5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF115e5a)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          title.isNotEmpty ? title : 'Untitled Entry',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF115e5a),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date and time section with action buttons
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF115e5a).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.calendar_today,
                      color: Color(0xFF115e5a),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dateFormat.format(createdAt),
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF2D3748),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          timeFormat.format(createdAt),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: const Color(0xFF718096),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Action buttons
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF115e5a).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.edit_outlined,
                            size: 18,
                            color: Color(0xFF115e5a),
                          ),
                          onPressed: () => _navigateToEdit(context),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: Colors.red,
                          ),
                          onPressed: () => _showDeleteConfirmation(context),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Combined content and attachments section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Attachments section (if any)
                  if (hasAttachments) ...[
                    _buildAttachmentsGrid(imagePaths, audioRecordings),
                    const SizedBox(height: 24),
                  ],

                  // Content section
                  Text(
                    content,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      height: 1.6,
                      color: const Color(0xFF2D3748),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 100), // Bottom padding for safe scrolling
          ],
        ),
      ),
    );
  }

  void _navigateToEdit(BuildContext context) {
    // TODO: Navigate to edit journal entry when edit functionality is available
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit functionality coming soon!'),
        backgroundColor: Color(0xFF115e5a),
      ),
    );
  }

  Widget _buildAttachmentsGrid(
    List<String> imagePaths,
    List<AudioRecordingData> audioRecordings,
  ) {
    return StaggeredGrid.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        // Display images
        ...imagePaths.map((imagePath) {
          return StaggeredGridTile.count(
            crossAxisCellCount: 1,
            mainAxisCellCount: 1,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: File(imagePath).existsSync()
                    ? Image.file(
                        File(imagePath),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(
                            Icons.broken_image,
                            color: Colors.grey,
                            size: 32,
                          ),
                        ),
                      ),
              ),
            ),
          );
        }),

        // Display audio recordings
        ...audioRecordings.map((audioData) {
          // Access audio data properties (AudioRecordingData is not a Realm object)
          final duration = audioData.duration;

          return StaggeredGridTile.count(
            crossAxisCellCount: 1,
            mainAxisCellCount: 1,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF115e5a).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Icon(
                      Icons.audiotrack,
                      color: Color(0xFF115e5a),
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Audio Recording',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF2D3748),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${duration.inSeconds}s',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: const Color(0xFF718096),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Journal Entry',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2D3748),
          ),
        ),
        content: Text(
          'Are you sure you want to delete this journal entry? This action cannot be undone.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFF718096),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF718096),
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final scaffoldMessenger = ScaffoldMessenger.of(context);

              navigator.pop(); // Close dialog

              try {
                // Get the entry ID before potential invalidation
                final entryId = _safeAccess(() => entry.id);
                if (entryId == null) {
                  // Entry is already deleted
                  navigator.pop(); // Return to journal list
                  return;
                }

                final dbHelper = RealmDatabaseHelper();
                await dbHelper.deleteJournalEntry(entryId);

                navigator.pop(
                  true,
                ); // Return to journal list with success result

                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      'Journal entry deleted successfully',
                      style: GoogleFonts.inter(color: Colors.white),
                    ),
                    backgroundColor: const Color(0xFF115e5a),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              } catch (e) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      'Error deleting journal entry: $e',
                      style: GoogleFonts.inter(color: Colors.white),
                    ),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              }
            },
            child: Text(
              'Delete',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

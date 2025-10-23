import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:motor/motor.dart';
import 'package:intl/intl.dart';
import '../models/realm_models.dart';
import '../utils/realm_database_helper.dart';
import '../core/constants/app_colors.dart';
import 'package:realm/realm.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'dart:async';
import '../services/media_store.dart';
import '../services/player_service.dart';
import '../core/theme/typography.dart';
import 'package:path/path.dart' as p;

class JournalViewScreen extends StatefulWidget {
  final JournalEntryRealm entry;

  const JournalViewScreen({super.key, required this.entry});

  @override
  State<JournalViewScreen> createState() => _JournalViewScreenState();
}

class _JournalViewScreenState extends State<JournalViewScreen>
    with TickerProviderStateMixin {
  late SingleMotionController _contentController;
  late Animation<double> _contentAnimation;
  late ScrollController _scrollController;
  late CarouselController _imagePageController;

  MoodEntryRealm? _associatedMood;
  Color _moodColor = AppColors.primary;
  String? _currentlyPlayingPath;
  // Floating buttons are static; no visibility animation required.

  final Map<String, PlayerController> _playerControllers = {};
  final Map<String, String> _resolvedAudioPaths = {};
  final PlayerService _playerService = PlayerService();
  StreamSubscription<String?>? _playerSubscription;
  final RealmDatabaseHelper _dbHelper = RealmDatabaseHelper();
  Realm? _realm;
  JournalEntryRealm? _liveEntry;
  StreamSubscription<RealmObjectChanges<JournalEntryRealm>>? _entrySub;

  JournalEntryRealm get _entryOrWidget => _liveEntry ?? widget.entry;

  @override
  void initState() {
    super.initState();
    _contentController = SingleMotionController(
      motion: CupertinoMotion.smooth(), // Elegant entrance animation
      vsync: this,
    );
    _contentAnimation = CurvedAnimation(
      parent: _contentController,
      curve: Curves.easeOut,
    );
    _scrollController = ScrollController()..addListener(_onScroll);
    _imagePageController = CarouselController(initialItem: 1);

    _contentController.animateTo(1.0);

    _playerService.initialize();
    _playerSubscription = _playerService.currentlyPlayingStream.listen((path) {
      if (!mounted) return;
      setState(() {
        _currentlyPlayingPath = path;
      });
    });

    _setupInitialControllers();
    _initEntryWatcher();
  }

  void _setupInitialControllers() {
    final audioList = _entryOrWidget.audioRecordings;
    for (final audio in audioList) {
      if (audio.path.isEmpty) continue;
      final originalKey = audio.path;

      // Prepare resolved absolute path
      MediaStore.instance.resolvePath(originalKey).then((resolvedPath) {
        if (!mounted) return;
        final key = resolvedPath;
        if (_playerControllers.containsKey(originalKey) ||
            _playerControllers.containsKey(key)) {
          _resolvedAudioPaths[originalKey] = key;
          return;
        }

        final controller = _playerService.getWaveformController(key);
        _resolvedAudioPaths[originalKey] = key;
        setState(() {
          _playerControllers[key] = controller;
          _playerControllers[originalKey] = controller;
        });
      });
    }
  }

  Future<void> _initEntryWatcher() async {
    try {
      _realm ??= await _dbHelper.realm;
      final found = _realm!.find<JournalEntryRealm>(widget.entry.id);
      if (found != null) {
        _liveEntry = found;
        _entrySub?.cancel();
        _entrySub = found.changes.listen((changes) {
          if (!mounted) return;
          _liveEntry = changes.object;
          _setupInitialControllers();
          _loadAssociatedMood();
          setState(() {});
        });
      }
      await _loadAssociatedMood();
    } catch (_) {}
  }

  /// Safely access a Realm object property with error handling
  T? _safeAccess<T>(T Function() accessor, [T? defaultValue]) {
    try {
      return accessor();
    } catch (e) {
      if (e is RealmException && e.message.contains('invalidated')) {
        return defaultValue;
      }
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Safely access entry properties
    final title = _safeAccess(() => _entryOrWidget.title, '') ?? '';
    final content = _safeAccess(() => _entryOrWidget.content, '') ?? '';
    final createdAt = _safeAccess(() => _entryOrWidget.createdAt);
    final imagePaths =
        _safeAccess(() => _entryOrWidget.imagePaths, <String>[]) ?? <String>[];
    final audioRecordings =
        _safeAccess(
          () => _entryOrWidget.audioRecordings,
          <AudioRecordingData>[],
        ) ??
        <AudioRecordingData>[];

    // If the entry has been invalidated, show an error screen
    if (createdAt == null) {
      return _buildErrorScreen();
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          RefreshIndicator(
            onRefresh: _handleRefresh,
            color: AppColors.primary,
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: AnimatedBuilder(
                animation: _contentAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, 30 * (1 - _contentAnimation.value)),
                    child: Opacity(
                      opacity: _contentAnimation.value,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Date Section
                          _buildDateSection(createdAt, title),
                          const SizedBox(height: 16),

                          // Mood Section
                          if (_associatedMood != null) ...[
                            _buildMoodSection(),
                            const SizedBox(height: 24),
                          ],

                          // Images Carousel Section
                          if (imagePaths.isNotEmpty) ...[
                            _buildImageCarousel(imagePaths),
                            const SizedBox(height: 24),
                          ],

                          // Audio Section
                          if (audioRecordings.isNotEmpty) ...[
                            _buildAudioSection(audioRecordings),
                            const SizedBox(height: 24),
                          ],

                          // Content Section
                          _buildContentSection(content),

                          const SizedBox(
                            height: 100,
                          ), // Space for floating buttons
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Floating Action Buttons
          _buildFloatingActionButtons(),
        ],
      ),
    );
  }

  Widget _buildDateSection(DateTime createdAt, String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          Text(
            DateFormat('MMMM d, yyyy').format(createdAt.toLocal()),
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontSize: 16, fontWeight: FontWeight.w500)
                .apply(color: _moodColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            title.isNotEmpty ? title : 'Untitled Entry',
            style: Theme.of(context).textTheme.headlineMedium
                ?.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  height: 1.5,
                )
                .apply(color: AppColors.textPrimary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMoodSection() {
    if (_associatedMood == null) return const SizedBox();

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _moodColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _moodColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _moodColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _associatedMood!.mood,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(fontSize: 14, fontWeight: FontWeight.w600)
                  .apply(color: _moodColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCarousel(List<String> imagePaths) {
    final double height = MediaQuery.sizeOf(context).height;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: height / 3),
      child: CarouselView.weighted(
        controller: _imagePageController,
        itemSnapping: true,
        flexWeights: const <int>[1, 8, 1],
        children: [
          for (final storedPath in imagePaths)
            FutureBuilder<String>(
              future: MediaStore.instance.resolvePath(storedPath),
              builder: (context, snapshot) {
                final resolvedPath = snapshot.data ?? storedPath;
                return Hero(
                  tag: 'image_$storedPath',
                  child: GestureDetector(
                    onTap: () => _showImagePreview(context, resolvedPath),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(
                        File(resolvedPath),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              color: AppColors.backgroundLight,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.divider),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.broken_image_outlined,
                                  color: AppColors.textSecondary,
                                  size: 48,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Image not found (missing or moved)',
                                  style: Theme.of(context).textTheme.bodyLarge
                                      ?.copyWith(fontSize: 16)
                                      .apply(color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'This file path no longer exists on device.',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(fontSize: 12)
                                      .apply(color: AppColors.textSecondary),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAudioSection(List<AudioRecordingData> audioRecordings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [...audioRecordings.map((audio) => _buildAudioPlayer(audio))],
    );
  }

  Widget _buildAudioPlayer(AudioRecordingData audio) {
    final resolvedPath = _resolvedAudioPaths[audio.path] ?? audio.path;
    final isPlaying = _currentlyPlayingPath == resolvedPath;
    final displayPathFuture = MediaStore.instance.resolvePath(audio.path);
    final controller = _playerControllers[audio.path];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Play button
          GestureDetector(
            onTap: () => _playAudio(audio.path),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _moodColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPlaying ? Icons.pause : Icons.play_arrow,
                color: AppColors.surface,
                size: 28,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Waveform and duration
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (controller != null)
                  AudioFileWaveforms(
                    size: const Size(500, 50),
                    playerController: controller,
                    waveformType: WaveformType.fitWidth,
                    playerWaveStyle: PlayerWaveStyle(
                      fixedWaveColor: AppColors.divider,
                      liveWaveColor: _moodColor,
                      spacing: 3,
                      showSeekLine: true,
                      waveCap: StrokeCap.round,
                      waveThickness: 2,
                      scaleFactor: 200,
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatDuration(audio.duration),
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(fontSize: 13)
                          .apply(color: AppColors.textSecondary),
                    ),
                    const SizedBox(width: 12),
                    FutureBuilder<String>(
                      future: displayPathFuture,
                      builder: (context, snapshot) {
                        final show = snapshot.data ?? audio.path;
                        return Expanded(
                          child: Text(
                            p.basename(show),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(fontSize: 12)
                                .apply(color: AppColors.textSecondary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Trailing menu
          const SizedBox(width: 8),
          Icon(Icons.more_horiz, color: AppColors.textSecondary),
        ],
      ),
    );
  }

  Widget _buildContentSection(String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          content,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontSize: 16,
            height: 1.6,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingActionButtons() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSolidActionButton(
              icon: Icons.edit,
              onTap: () => _navigateToEdit(context),
              iconColor: AppColors.primary,
              tooltip: 'Edit',
            ),
            const SizedBox(width: 24),
            _buildSolidActionButton(
              icon: Icons.share_rounded,
              onTap: () => _shareEntry(context),
              iconColor: AppColors.secondary,
              tooltip: 'Share',
            ),
            const SizedBox(width: 24),
            _buildSolidActionButton(
              icon: Icons.delete_outline_rounded,
              onTap: () => _deleteEntry(context),
              iconColor: AppColors.error,
              tooltip: 'Delete',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSolidActionButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color iconColor,
    String? tooltip,
  }) {
    return Material(
      color: Colors.transparent,
      child: Tooltip(
        message: tooltip ?? '',
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Journal Entry',
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(fontSize: 20, fontWeight: FontWeight.w600)
              .apply(color: AppColors.primary),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              'Entry Not Found',
              style: Theme.of(context).textTheme.headlineMedium
                  ?.copyWith(fontSize: 24, fontWeight: FontWeight.w600)
                  .apply(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'This journal entry has been deleted or is no longer available.',
              style: Theme.of(context).textTheme.bodyLarge
                  ?.copyWith(fontSize: 16)
                  .apply(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.surface,
              ),
              child: Text(
                'Go Back',
                style: TextStyle(
                  fontFamily: AppTypography.primaryFontFamily,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleRefresh() async {
    HapticFeedback.lightImpact();
    await _loadAssociatedMood();
  }

  void _showImagePreview(BuildContext context, String imagePath) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Hero(
          tag: 'image_$imagePath',
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 20,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(File(imagePath), fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToEdit(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Edit functionality coming soon!',
          style: TextStyle(
            fontFamily: AppTypography.primaryFontFamily,
            color: AppColors.surface,
          ),
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedSuperellipseBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
    );
  }

  void _shareEntry(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Share functionality coming soon!',
          style: TextStyle(
            fontFamily: AppTypography.primaryFontFamily,
            color: AppColors.surface,
          ),
        ),
        backgroundColor: AppColors.secondary,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedSuperellipseBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
    );
  }

  void _deleteEntry(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Entry',
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(fontSize: 20, fontWeight: FontWeight.w600)
              .apply(color: AppColors.textPrimary),
        ),
        content: Text(
          'Are you sure you want to delete this journal entry? This action cannot be undone.',
          style: Theme.of(context).textTheme.bodyLarge
              ?.copyWith(fontSize: 16)
              .apply(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: Theme.of(context).textTheme.bodyLarge
                  ?.copyWith(fontSize: 16, fontWeight: FontWeight.w600)
                  .apply(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _performDelete();
            },
            child: Text(
              'Delete',
              style: Theme.of(context).textTheme.bodyLarge
                  ?.copyWith(fontSize: 16, fontWeight: FontWeight.w600)
                  .apply(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _performDelete() async {
    try {
      await _dbHelper.deleteJournalEntry(widget.entry.id);
      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate deletion
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Journal entry deleted',
              style: TextStyle(
                fontFamily: AppTypography.primaryFontFamily,
                color: AppColors.surface,
              ),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: const RoundedSuperellipseBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to delete entry: $e',
              style: TextStyle(
                fontFamily: AppTypography.primaryFontFamily,
                color: AppColors.surface,
              ),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: const RoundedSuperellipseBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
        );
      }
    }
  }

  void _onScroll() {}

  Future<void> _loadAssociatedMood() async {
    try {
      final entryMood = _entryOrWidget.entryMood;
      if (entryMood != null) {
        setState(() {
          _associatedMood = MoodEntryRealm(
            ObjectId(),
            entryMood,
            _entryOrWidget.createdAt.toUtc(),
            intensity: null,
          );
          _moodColor = AppColors.harmonizeToPrimary(
            AppColors.getEmotionColor(entryMood),
            Theme.of(context).colorScheme,
          );
        });
        return;
      }
      final createdAt = _entryOrWidget.createdAt;
      final dailyMoods = await _dbHelper.getAllMoodsForDate(createdAt);
      if (dailyMoods.isNotEmpty) {
        setState(() {
          _associatedMood = dailyMoods.first;
          _moodColor = AppColors.harmonizeToPrimary(
            AppColors.getEmotionColor(dailyMoods.first.mood),
            Theme.of(context).colorScheme,
          );
        });
      }
    } catch (_) {
      // silent
    }
  }

  void _playAudio(String audioPath) async {
    // Resolve relative path to absolute if needed
    final resolved =
        _resolvedAudioPaths[audioPath] ??
        await MediaStore.instance.resolvePath(audioPath);
    _resolvedAudioPaths[audioPath] = resolved;

    try {
      await _playerService.playAudio(resolved);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to play audio: $e',
            style: TextStyle(
              fontFamily: AppTypography.primaryFontFamily,
              color: AppColors.surface,
            ),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: const RoundedSuperellipseBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
      );
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _contentController.dispose();
    _scrollController.dispose();
    _imagePageController.dispose();
    _entrySub?.cancel();
    _playerSubscription?.cancel();
    _playerService.stop();
    super.dispose();
  }
}

import 'dart:io';
import 'package:flutter/foundation.dart';
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
import 'journal_writing.dart';

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

    _contentController.animateTo(1.0);

    // Initialize services and data asynchronously
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    try {
      // TODO: Temporarily disabled audio services for testing
      // Initialize PlayerService first
      // await _playerService.initialize();

      // Subscribe to player streams after initialization
      // _playerSubscription = _playerService.currentlyPlayingStream.listen((
      //   path,
      // ) {
      //   if (!mounted) return;
      //   setState(() {
      //     _currentlyPlayingPath = path;
      //   });
      // });

      // Initialize entry watcher
      await _initEntryWatcher();

      // TODO: Temporarily disabled audio setup for testing
      // Setup audio controllers after PlayerService is ready
      // _setupInitialControllers();

      // Load associated mood
      await _loadAssociatedMood();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('JournalViewScreen: Error initializing screen: $e');
      }
    }
  }

  void _setupInitialControllers() {
    try {
      final audioList =
          _safeAccess(
            () => _entryOrWidget.audioRecordings,
            <AudioRecordingData>[],
          ) ??
          <AudioRecordingData>[];

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
    } catch (e) {
      if (kDebugMode) {
        debugPrint('JournalViewScreen: Error setting up audio controllers: $e');
      }
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
    } catch (e) {
      if (kDebugMode) {
        debugPrint('JournalViewScreen: Error initializing entry watcher: $e');
      }
    }
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
      body: SafeArea(
        child: Column(
          children: [
            // Toolbar
            _buildToolbar(context),

            // Main content
            Expanded(
              child: RefreshIndicator(
                onRefresh: _handleRefresh,
                color: AppColors.primary,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
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
                              // Images grid (edge to edge, only when images exist)
                              if (imagePaths.isNotEmpty) ...[
                                _buildImagesGrid(imagePaths),
                                const SizedBox(height: 20),
                              ],

                              // Content area with padding
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Title
                                    _buildTitle(title),
                                    const SizedBox(height: 16),

                                    // Date with icon
                                    _buildDateRow(createdAt),
                                    const SizedBox(height: 24),

                                    // Audio Section
                                    if (audioRecordings.isNotEmpty) ...[
                                      _buildAudioSection(audioRecordings),
                                      const SizedBox(height: 24),
                                    ],

                                    // Content
                                    _buildContent(content),
                                    const SizedBox(height: 32),

                                    // Mood section at bottom
                                    if (_associatedMood != null) ...[
                                      _buildMoodPill(),
                                    ],

                                    const SizedBox(height: 100),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Toolbar with X and Menu buttons (matching journal_writing layout)
  Widget _buildToolbar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // X button (close)
          Material(
            color: Colors.black12,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              },
              customBorder: const CircleBorder(),
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                child: const Icon(Icons.close, color: Colors.black87, size: 24),
              ),
            ),
          ),

          const Spacer(),

          // Menu button
          Material(
            color: Colors.black12,
            shape: const CircleBorder(),
            child: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _handleEdit(context);
                } else if (value == 'delete') {
                  _handleDelete(context);
                }
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: const [
                      Icon(
                        Icons.edit_outlined,
                        color: Colors.black87,
                        size: 20,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Edit',
                        style: TextStyle(fontSize: 16, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: const [
                      Icon(Icons.delete_outline, color: Colors.red, size: 20),
                      SizedBox(width: 12),
                      Text(
                        'Delete',
                        style: TextStyle(fontSize: 16, color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ],
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.more_vert,
                  color: Colors.black87,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleEdit(BuildContext context) async {
    HapticFeedback.lightImpact();
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => JournalWritingScreen(existingEntry: _entryOrWidget),
      ),
    );
    if (result == true && mounted) {
      // Refresh the view after editing
      _handleRefresh();
    }
  }

  void _handleDelete(BuildContext context) {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Delete Entry',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        content: const Text(
          'Are you sure you want to delete this journal entry? This action cannot be undone.',
          style: TextStyle(fontSize: 16, color: Colors.black54),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _performDelete();
            },
            child: const Text(
              'Delete',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _performDelete() async {
    try {
      await _dbHelper.deleteJournalEntry(widget.entry.id);
      if (!mounted) return;

      // Close the view screen first
      Navigator.of(context).pop();

      // Then show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Journal entry deleted'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('JournalViewScreen: Error deleting entry: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete entry: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Images grid (similar to journal_writing layout)
  Widget _buildImagesGrid(List<String> imagePaths) {
    final itemCount = imagePaths.length;
    int groups;
    if (itemCount == 1) {
      groups = 1;
    } else if (itemCount == 2) {
      groups = 2;
    } else {
      groups = (itemCount / 3).ceil();
    }

    return SizedBox(
      height: 250,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(4),
        itemCount: groups,
        itemBuilder: (context, groupIndex) {
          final startIndex = groupIndex * 3;
          final endIndex = (startIndex + 3).clamp(0, itemCount);
          final groupItems = imagePaths.sublist(startIndex, endIndex);

          if (groupItems.length == 1) {
            return _buildSingleImageItem(groupItems[0]);
          } else if (groupItems.length == 2) {
            return _buildTwoImagesLayout(groupItems);
          } else {
            return _buildThreeImagesLayout(groupItems);
          }
        },
      ),
    );
  }

  Widget _buildSingleImageItem(String imagePath) {
    return FutureBuilder<String>(
      future: MediaStore.instance.resolvePath(imagePath),
      builder: (context, snapshot) {
        final resolvedPath = snapshot.data ?? imagePath;
        return Container(
          width: MediaQuery.of(context).size.width - 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          child: GestureDetector(
            onTap: () => _showImagePreview(context, resolvedPath),
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(File(resolvedPath), fit: BoxFit.cover),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTwoImagesLayout(List<String> images) {
    return Container(
      width: MediaQuery.of(context).size.width - 8,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Expanded(child: _buildGridImageItem(images[0])),
          const SizedBox(width: 8),
          Expanded(child: _buildGridImageItem(images[1])),
        ],
      ),
    );
  }

  Widget _buildThreeImagesLayout(List<String> images) {
    return Container(
      width: MediaQuery.of(context).size.width - 8,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Expanded(child: _buildGridImageItem(images[0])),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              children: [
                Expanded(child: _buildGridImageItem(images[1])),
                const SizedBox(height: 8),
                Expanded(child: _buildGridImageItem(images[2])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridImageItem(String imagePath) {
    return FutureBuilder<String>(
      future: MediaStore.instance.resolvePath(imagePath),
      builder: (context, snapshot) {
        final resolvedPath = snapshot.data ?? imagePath;
        return GestureDetector(
          onTap: () => _showImagePreview(context, resolvedPath),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(File(resolvedPath), fit: BoxFit.cover),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Title display
  Widget _buildTitle(String title) {
    return Text(
      title.isNotEmpty ? title : 'Untitled Entry',
      style: const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
        height: 1.3,
      ),
    );
  }

  /// Date row with icon (like journal_writing)
  Widget _buildDateRow(DateTime createdAt) {
    return Row(
      children: [
        const Icon(Icons.calendar_today, size: 16, color: Colors.black54),
        const SizedBox(width: 8),
        Text(
          DateFormat('MMMM d, yyyy').format(createdAt.toLocal()),
          style: const TextStyle(fontSize: 14, color: Colors.black54),
        ),
      ],
    );
  }

  /// Content display
  Widget _buildContent(String content) {
    return Text(
      content.isNotEmpty ? content : 'No content',
      style: const TextStyle(fontSize: 16, color: Colors.black87, height: 1.6),
    );
  }

  /// Mood pill at bottom
  Widget _buildMoodPill() {
    if (_associatedMood == null) return const SizedBox();

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _moodColor,
              ),
            ),
          ],
        ),
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

  void _onScroll() {}

  Future<void> _loadAssociatedMood() async {
    try {
      final entryMood = _safeAccess(() => _entryOrWidget.entryMood);
      final createdAt = _safeAccess(() => _entryOrWidget.createdAt);

      if (createdAt == null) return; // Entry is invalid

      if (entryMood != null) {
        if (!mounted) return;
        setState(() {
          _associatedMood = MoodEntryRealm(
            ObjectId(),
            entryMood,
            createdAt.toUtc(),
            intensity: null,
          );
          _moodColor = AppColors.harmonizeToPrimary(
            AppColors.getEmotionColor(entryMood),
            Theme.of(context).colorScheme,
          );
        });
        return;
      }

      final dailyMoods = await _dbHelper.getAllMoodsForDate(createdAt);
      if (dailyMoods.isNotEmpty && mounted) {
        setState(() {
          _associatedMood = dailyMoods.first;
          _moodColor = AppColors.harmonizeToPrimary(
            AppColors.getEmotionColor(dailyMoods.first.mood),
            Theme.of(context).colorScheme,
          );
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('JournalViewScreen: Error loading mood: $e');
      }
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
    _entrySub?.cancel();
    _playerSubscription?.cancel();
    _playerService.stop();
    super.dispose();
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/realm_models.dart';
import '../utils/realm_database_helper.dart';
import '../core/constants/app_colors.dart';
import 'package:realm/realm.dart';
import 'dart:math' as math;
import 'package:audio_waveforms/audio_waveforms.dart';
import 'dart:async';

class JournalViewScreen extends StatefulWidget {
  final JournalEntryRealm entry;

  const JournalViewScreen({super.key, required this.entry});

  @override
  State<JournalViewScreen> createState() => _JournalViewScreenState();
}

class _JournalViewScreenState extends State<JournalViewScreen>
    with TickerProviderStateMixin {
  late AnimationController _heroController;
  late AnimationController _contentController;
  late AnimationController _floatingBarController;
  late Animation<double> _heroAnimation;
  late Animation<double> _contentAnimation;
  late Animation<Offset> _floatingBarAnimation;
  late ScrollController _scrollController;

  MoodEntryRealm? _associatedMood;
  Color _moodColor = AppColors.primary;
  String? _currentlyPlayingPath;
  bool _isFloatingBarVisible = true;
  double _expandedHeight = 260; // Default height

  final Map<String, PlayerController> _playerControllers = {};
  final RealmDatabaseHelper _dbHelper = RealmDatabaseHelper();
  Realm? _realm;
  JournalEntryRealm? _liveEntry;
  StreamSubscription<RealmObjectChanges<JournalEntryRealm>>? _entrySub;

  JournalEntryRealm get _entryOrWidget => _liveEntry ?? widget.entry;

  @override
  void initState() {
    super.initState();
    _heroController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _floatingBarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _heroAnimation = CurvedAnimation(
      parent: _heroController,
      curve: Curves.easeOutExpo,
    );
    _contentAnimation = CurvedAnimation(
      parent: _contentController,
      curve: Curves.easeOut,
    );
    _floatingBarAnimation =
        Tween<Offset>(
          begin: const Offset(0, 1.2),
          end: const Offset(0, 0),
        ).animate(
          CurvedAnimation(
            parent: _floatingBarController,
            curve: Curves.easeOut,
          ),
        );
    _scrollController = ScrollController()..addListener(_onScroll);

    _heroController.forward();
    _contentController.forward();
    _floatingBarController.forward();

    _setupInitialControllers();
    _initEntryWatcher();
  }

  void _setupInitialControllers() {
    final audioList = _entryOrWidget.audioRecordings;
    for (final audio in audioList) {
      if (audio.path.isEmpty) continue;
      if (!_playerControllers.containsKey(audio.path)) {
        final controller = PlayerController();
        controller.preparePlayer(
          path: audio.path,
          shouldExtractWaveform: true,
          noOfSamples: 100,
          volume: 1.0,
        );
        _playerControllers[audio.path] = controller;
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
          // Re-evaluate mood color and controllers on update
          _setupInitialControllers();
          _loadAssociatedMood();
          setState(() {});
        });
      }
      // Initial mood load if not already
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
      backgroundColor: AppColors.backgroundLight,
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _handleRefresh,
            color: AppColors.primary,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Hero Section with Gradient
                _buildHeroSection(title, createdAt),

                // Content Section
                SliverToBoxAdapter(
                  child: AnimatedBuilder(
                    animation: _contentAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, 50 * (1 - _contentAnimation.value)),
                        child: Opacity(
                          opacity: _contentAnimation.value,
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                // Main Content Card
                                _buildContentCard(content),
                                const SizedBox(height: 20),

                                // Attachments Card (if any)
                                _buildAttachmentsCard(
                                  imagePaths,
                                  audioRecordings,
                                ),

                                const SizedBox(
                                  height: 16,
                                ), // Extra bottom padding for floating bar
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Floating Action Bar
          _buildFloatingActionBar(),
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
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
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
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This journal entry has been deleted or is no longer available.',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
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
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection(String title, DateTime createdAt) {
    return SliverAppBar(
      expandedHeight: _expandedHeight,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: _moodColor,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios, color: AppColors.surface),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        title.isNotEmpty ? title : 'Untitled Entry',
        style: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.surface,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: AnimatedBuilder(
          animation: _heroAnimation,
          builder: (context, child) {
            return Container(
              color: _moodColor,
              child: Stack(
                children: [
                  // Subtle animated overlay
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.1,
                      child: Transform.scale(
                        scale: 1.0 + (0.05 * _heroAnimation.value),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              center: const Alignment(0.3, -0.7),
                              radius: 1.5,
                              colors: [
                                _moodColor.withValues(alpha: 0.3),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Content - adjust positioning based on hero height
                  Positioned(
                    bottom: math.max(60, _expandedHeight * 0.25),
                    left: 20,
                    right: 20,
                    child: Transform.translate(
                      offset: Offset(0, 30 * (1 - _heroAnimation.value)),
                      child: Opacity(
                        opacity: _heroAnimation.value,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Mood badge
                            if (_associatedMood != null) _buildMoodBadge(),

                            SizedBox(height: _expandedHeight < 200 ? 8 : 12),

                            // Title - adjust font size based on available space
                            Text(
                              title.isNotEmpty ? title : 'Untitled Entry',
                              style: GoogleFonts.inter(
                                fontSize: _expandedHeight < 200 ? 24 : 28,
                                fontWeight: FontWeight.w700,
                                color: AppColors.surface,
                                height: 1.2,
                              ),
                              maxLines: _expandedHeight < 200 ? 1 : 2,
                              overflow: TextOverflow.ellipsis,
                            ),

                            SizedBox(height: _expandedHeight < 200 ? 6 : 8),

                            // Date and time
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: _expandedHeight < 200 ? 14 : 16,
                                  color: AppColors.surface.withValues(
                                    alpha: 0.8,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    DateFormat(
                                      _expandedHeight < 200
                                          ? 'MMM d, yyyy • h:mm a'
                                          : 'EEEE, MMMM d, yyyy • h:mm a',
                                    ).format(createdAt.toLocal()),
                                    style: GoogleFonts.inter(
                                      fontSize: _expandedHeight < 200 ? 12 : 14,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.surface.withValues(
                                        alpha: 0.9,
                                      ),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFloatingActionBar() {
    return Positioned(
      bottom: 24,
      right: 16,
      child: SlideTransition(
        position: _floatingBarAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.divider),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCircleActionButton(
                icon: Icons.edit_rounded,
                onTap: () => _navigateToEdit(context),
                filled: true,
                tooltip: 'Edit',
                size: 44,
              ),
              const SizedBox(width: 6),
              _buildCircleActionButton(
                icon: Icons.ios_share_rounded,
                onTap: () => _shareEntry(context),
                filled: false,
                tooltip: 'Share',
                size: 44,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCircleActionButton({
    required IconData icon,
    required VoidCallback onTap,
    bool filled = false,
    bool isDestructive = false,
    String? tooltip,
    double size = 48,
  }) {
    final Color bgColor = filled ? AppColors.textPrimary : AppColors.surface;
    final Color iconColor = filled
        ? AppColors.surface
        : (isDestructive ? AppColors.error : AppColors.textPrimary);

    return Material(
      color: Colors.transparent,
      child: Tooltip(
        message: tooltip ?? '',
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(size / 2),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
              border: filled ? null : Border.all(color: AppColors.divider),
            ),
            child: Icon(icon, color: iconColor, size: size * 0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildMoodBadge() {
    if (_associatedMood == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
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
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.surface,
            ),
          ),
          // Don't show intensity for journal entries - only for general mood entries
        ],
      ),
    );
  }

  Widget _buildContentCard(String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          content,
          style: GoogleFonts.inter(
            fontSize: 16,
            height: 1.6,
            color: AppColors.textPrimary,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildAttachmentsCard(
    List<String> imagePaths,
    List<AudioRecordingData> audioRecordings,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (imagePaths.isNotEmpty) _buildImagesGrid(imagePaths),
        if (imagePaths.isNotEmpty && audioRecordings.isNotEmpty)
          const SizedBox(height: 16),
        if (audioRecordings.isNotEmpty) _buildAudioList(audioRecordings),
      ],
    );
  }

  Widget _buildImagesGrid(List<String> imagePaths) {
    return StaggeredGrid.count(
      crossAxisCount: imagePaths.length == 1 ? 1 : 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: imagePaths.map((path) {
        return GestureDetector(
          onTap: () => _showImagePreview(context, path),
          child: Hero(
            tag: 'image_$path',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(path),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 120,
                    color: AppColors.backgroundLight,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image_outlined,
                          color: AppColors.textSecondary,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Image not found',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAudioList(List<AudioRecordingData> audioRecordings) {
    return Column(
      children: audioRecordings.map((audio) {
        final isPlaying = _currentlyPlayingPath == audio.path;
        final controller = _playerControllers[audio.path];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.grey.shade100,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Play button
              GestureDetector(
                onTap: () => _playAudio(audio.path),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _moodColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isPlaying ? Icons.pause : Icons.play_arrow,
                    color: AppColors.surface,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Waveform and time
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (controller != null)
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final double maxWidth = math
                              .min(constraints.maxWidth, 260.0)
                              .toDouble();
                          return AudioFileWaveforms(
                            size: Size(maxWidth, 30),
                            playerController: controller,
                            waveformType: WaveformType.fitWidth,
                            playerWaveStyle: PlayerWaveStyle(
                              fixedWaveColor: Colors.grey.shade400,
                              liveWaveColor: AppColors.primary,
                              spacing: 2.1,
                              showSeekLine: false,
                              waveCap: StrokeCap.round,
                              waveThickness: 2,
                              scaleFactor: 100,
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDuration(audio.duration),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
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
          style: GoogleFonts.inter(color: AppColors.surface),
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
          style: GoogleFonts.inter(color: AppColors.surface),
        ),
        backgroundColor: AppColors.secondary,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedSuperellipseBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
    );
  }

  void _onScroll() {
    final isScrollingDown =
        _scrollController.position.userScrollDirection ==
        ScrollDirection.reverse;
    final threshold = _expandedHeight < 200 ? 50 : 100;
    final shouldHideBar =
        isScrollingDown && _scrollController.offset > threshold;
    if (shouldHideBar != !_isFloatingBarVisible) {
      setState(() {
        _isFloatingBarVisible = !shouldHideBar;
      });
      if (_isFloatingBarVisible) {
        _floatingBarController.forward();
      } else {
        _floatingBarController.reverse();
      }
    }
  }

  Future<void> _loadAssociatedMood() async {
    try {
      final entryMood = _entryOrWidget.entryMood;
      if (entryMood != null) {
        setState(() {
          _associatedMood = MoodEntryRealm(
            ObjectId(),
            entryMood,
            _entryOrWidget.createdAt,
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
    final controller = _playerControllers[audioPath];
    if (controller == null) return;

    if (_currentlyPlayingPath == audioPath) {
      if (controller.playerState.isPlaying) {
        await controller.pausePlayer();
      } else {
        await controller.startPlayer();
      }
      setState(() {});
      return;
    }

    if (_currentlyPlayingPath != null) {
      final prev = _playerControllers[_currentlyPlayingPath!];
      await prev?.stopPlayer();
    }

    _currentlyPlayingPath = audioPath;
    await controller.startPlayer();
    setState(() {});
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _heroController.dispose();
    _contentController.dispose();
    _floatingBarController.dispose();
    _scrollController.dispose();
    _entrySub?.cancel();
    for (final controller in _playerControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}

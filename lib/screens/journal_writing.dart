import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/mood_constants.dart';
import '../data/mood_assets.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/mood_colors.dart';
import '../components/mood_button.dart';
import '../features/journal/bloc/journal_writing_bloc.dart';
import '../features/journal/bloc/journal_writing_event.dart';
import '../features/journal/bloc/journal_writing_state.dart';
import '../services/player_service.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import '../services/recorder_service.dart';
import '../services/journal_mood_integration.dart';
import '../core/theme/typography.dart';

class JournalWritingScreen extends StatelessWidget {
  const JournalWritingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => JournalWritingBloc(
        playerService: PlayerService(),
        recorderService: RecorderService(),
        moodIntegration: JournalMoodIntegration(),
      )..add(JournalWritingInitialized()),
      child: const _JournalWritingView(),
    );
  }
}

class _JournalWritingView extends StatefulWidget {
  const _JournalWritingView();

  @override
  _JournalWritingViewState createState() => _JournalWritingViewState();
}

class _JournalWritingViewState extends State<_JournalWritingView>
    with TickerProviderStateMixin {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _contentFocusNode = FocusNode();

  late VoidCallback _titleListener;
  late VoidCallback _contentListener;

  // Live waveform removed per request.

  @override
  void initState() {
    super.initState();
    // Live waveform removed; no animation initialization.

    // Listen for text changes and dispatch events to BLoC
    _titleListener = () => context.read<JournalWritingBloc>().add(
      TitleChanged(_titleController.text),
    );
    _contentListener = () => context.read<JournalWritingBloc>().add(
      ContentChanged(_contentController.text),
    );
    _titleController.addListener(_titleListener);
    _contentController.addListener(_contentListener);
  }

  // Removed _initializeWaveAnimations and _updateWaveAmplitudes.

  @override
  void dispose() {
    _titleController.removeListener(_titleListener);
    _contentController.removeListener(_contentListener);
    _titleController.dispose();
    _contentController.dispose();
    _titleFocusNode.dispose();
    _contentFocusNode.dispose();

    // No waveform controllers to dispose.

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<JournalWritingBloc, JournalWritingState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Colors.red,
            ),
          );
        }

        // Navigate back only when explicit success state reached
        if (state.saveStatus == JournalSaveStatus.success) {
          Future.microtask(() {
            if (mounted) Navigator.pop(context, true);
          });
        }

        // Live waveform removed: no animation handling.
      },
      child: BlocBuilder<JournalWritingBloc, JournalWritingState>(
        builder: (context, state) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Scaffold(
              extendBodyBehindAppBar: true,
              resizeToAvoidBottomInset: true,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,

              body: SafeArea(
                child: Column(
                  children: [
                    _buildHeader(context, state),
                    const SizedBox(height: 12),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildEditorCard(context, state),
                            const SizedBox(height: 20),
                            _buildMoodSection(context, state),
                            _buildAttachmentsSection(context, state),
                            const SizedBox(height: 16),
                            // Live recording waveform removed.
                            if (state.selectedImages.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: _buildImagesGrid(context, state),
                              ),
                            if (state.audioRecordings.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: _buildAudioList(context, state),
                              ),
                            ],
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, JournalWritingState state) {
    final String date = DateFormat('MMM d, yyyy').format(DateTime.now());

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildPillButton(
            label: 'Cancel',
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
          ),
          Expanded(
            child: Center(
              child: Text(
                date,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF115e5a),
                  fontFamily: AppTypography.primaryFontFamily,
                ),
              ),
            ),
          ),
          _buildPillButton(
            label: 'Save',
            onTap: state.canSave
                ? () {
                    HapticFeedback.lightImpact();
                    context.read<JournalWritingBloc>().add(
                      JournalSaveRequested(),
                    );
                  }
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildEditorCard(BuildContext context, JournalWritingState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title input (Notion-like)
            TextField(
              controller: _titleController,
              focusNode: _titleFocusNode,
              textInputAction: TextInputAction.next,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                height: 1.25,
                fontFamily: AppTypography.primaryFontFamily,
              ),
              decoration: InputDecoration(
                isCollapsed: true,
                hintText: 'Title',
                hintStyle: TextStyle(
                  color: Colors.black26,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  fontFamily: AppTypography.primaryFontFamily,
                ),
                border: InputBorder.none,
              ),
            ),
            const SizedBox(height: 8),
            // Context/body input
            TextField(
              controller: _contentController,
              focusNode: _contentFocusNode,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              minLines: 10,
              maxLines: null,
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
                fontFamily: AppTypography.primaryFontFamily,
              ),
              decoration: InputDecoration(
                isCollapsed: true,
                hintText: "What do you wish you'd said today?",
                hintStyle: TextStyle(
                  color: Colors.black26,
                  fontSize: 16,
                  fontFamily: AppTypography.primaryFontFamily,
                ),
                border: InputBorder.none,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentsSection(
    BuildContext context,
    JournalWritingState state,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, left: 16, right: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Attachments',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              fontFamily: AppTypography.primaryFontFamily,
            ),
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () => context.read<JournalWritingBloc>().add(
                  ImagePickerRequested(),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF115e5a),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.image, color: Colors.white, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Photo',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => state.isRecording
                    ? context.read<JournalWritingBloc>().add(
                        RecordingStopRequested(),
                      )
                    : context.read<JournalWritingBloc>().add(
                        RecordingStartRequested(),
                      ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: state.isRecording
                        ? Colors.red
                        : const Color(0xFF115e5a),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        state.isRecording ? Icons.stop : Icons.mic,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        state.isRecording ? 'Stop' : 'Voice',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPillButton({required String label, VoidCallback? onTap}) {
    final bool enabled = onTap != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(enabled ? 1 : 0.6),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
            border: Border.all(color: const Color(0xFFE7ECEA)),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: enabled
                  ? const Color(0xFF115e5a)
                  : const Color(0xFF115e5a).withOpacity(0.4),
              fontFamily: AppTypography.primaryFontFamily,
            ),
          ),
        ),
      ),
    );
  }

  // New: only images grid
  Widget _buildImagesGrid(BuildContext context, JournalWritingState state) {
    return MasonryGridView.count(
      crossAxisCount: 3,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: state.selectedImages.length,
      itemBuilder: (context, index) {
        final imageFile = state.selectedImages[index];
        return Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(File(imageFile.path), fit: BoxFit.cover),
            ),
            Positioned(
              top: 6,
              right: 6,
              child: _buildRemoveChip(
                onTap: () {
                  context.read<JournalWritingBloc>().add(ImageRemoved(index));
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // New: audio list, edge-to-edge
  Widget _buildAudioList(BuildContext context, JournalWritingState state) {
    return ListView.separated(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: state.audioRecordings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final audio = state.audioRecordings[i];
        // Stored as milliseconds (int) when added in the BLoC; convert to Duration safely.
        final rawDuration = audio['duration'];
        Duration duration;
        if (rawDuration is Duration) {
          duration = rawDuration;
        } else if (rawDuration is int) {
          duration = Duration(milliseconds: rawDuration);
        } else {
          duration = Duration.zero;
        }
        return _buildAudioChip(
          context,
          state,
          audio['path'] as String,
          duration,
          i,
        );
      },
    );
  }

  Widget _buildRemoveChip({required VoidCallback onTap}) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.close, size: 14),
      ),
    );
  }

  Widget _buildAudioChip(
    BuildContext context,
    JournalWritingState state,
    String path,
    Duration duration,
    int index,
  ) {
    final isPlaying = state.currentlyPlayingAudio == path;
    // Obtain (or create) a PlayerController via the bloc's injected PlayerService (consistent instance).
    final bloc = context.read<JournalWritingBloc>();
    final controller = bloc.getWaveformController(path);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Play button
          GestureDetector(
            onTap: () => context.read<JournalWritingBloc>().add(
              AudioPlaybackToggled(path),
            ),
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFF115e5a),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Waveform placeholder and Duration
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 40,
                  child: AudioFileWaveforms(
                    size: const Size(double.infinity, 40),
                    playerController: controller,
                    waveformType: WaveformType.fitWidth,
                    playerWaveStyle: PlayerWaveStyle(
                      fixedWaveColor: Colors.grey.shade300,
                      liveWaveColor: const Color(0xFF115e5a),
                      spacing: 2.5,
                      waveThickness: 2,
                      scaleFactor: 140,
                      showSeekLine: true,
                      waveCap: StrokeCap.round,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDuration(duration),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                    fontFamily: AppTypography.primaryFontFamily,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Delete button
          GestureDetector(
            onTap: () => context.read<JournalWritingBloc>().add(
              AudioRecordingRemoved(index),
            ),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.close, color: Colors.grey, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  // Removed _buildMiniWaveform (replaced with AudioFileWaveforms widget)

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // _buildWaveVisualization removed.

  // Mood section (edge-to-edge)
  Widget _buildMoodSection(BuildContext context, JournalWritingState state) {
    final moodExt = Theme.of(context).extension<MoodColors>();
    final selectedMoodColorRaw = state.selectedMood != null
        ? (moodExt?.byMood(state.selectedMood!) ??
              AppColors.getEmotionColor(state.selectedMood!))
        : null;
    final selectedMoodColor = selectedMoodColorRaw;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'How are you feeling?',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  fontFamily: AppTypography.primaryFontFamily,
                ),
              ),
              if (state.selectedMood != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: selectedMoodColor!.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: selectedMoodColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        state.selectedMood!,
                        style: TextStyle(
                          color: selectedMoodColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontFamily: AppTypography.primaryFontFamily,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Mood Buttons Horizontal Scroll
        RepaintBoundary(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: List.generate(MoodConstants.moodTypes.length, (index) {
                final mood = MoodConstants.moodTypes[index];
                return MoodButton(
                  Mood: mood,
                  svgPath: kMoodSvg[mood] ?? 'assets/emotion-icons/neutral.svg',
                  isSelected: mood == state.selectedMood,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    context.read<JournalWritingBloc>().add(MoodSelected(mood));
                  },
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}

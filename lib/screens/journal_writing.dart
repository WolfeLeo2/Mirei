import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/mood_constants.dart';
import '../data/mood_assets.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/mood_colors.dart';
import '../components/mood_button.dart';
import '../features/journal/bloc/journal_writing_bloc.dart';
import '../features/journal/bloc/journal_writing_event.dart';
import '../features/journal/bloc/journal_writing_state.dart';

class JournalWritingScreen extends StatelessWidget {
  const JournalWritingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          JournalWritingBloc()..add(JournalWritingInitialized()),
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

  // Real-time sound wave visualization
  late AnimationController _waveAnimationController;
  late List<AnimationController> _waveBarControllers;
  late List<Animation<double>> _waveBarAnimations;
  final int _numberOfWaveBars = 20;
  List<double> _currentAmplitudes = [];
  Timer? _waveUpdateTimer;

  @override
  void initState() {
    super.initState();
    _initializeWaveAnimations();

    // Listen for text changes and dispatch events to BLoC
    _titleController.addListener(() {
      context.read<JournalWritingBloc>().add(
        TitleChanged(_titleController.text),
      );
    });
    _contentController.addListener(() {
      context.read<JournalWritingBloc>().add(
        ContentChanged(_contentController.text),
      );
    });
  }

  void _initializeWaveAnimations() {
    _waveAnimationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _waveBarControllers = List.generate(
      _numberOfWaveBars,
      (index) => AnimationController(
        duration: Duration(milliseconds: 150 + (index * 50)),
        vsync: this,
      ),
    );

    _waveBarAnimations = _waveBarControllers.map((controller) {
      return Tween<double>(
        begin: 0.1,
        end: 1.0,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));
    }).toList();

    _currentAmplitudes = List.filled(_numberOfWaveBars, 0.1);

    _waveAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        final bloc = context.read<JournalWritingBloc>();
        if (bloc.state.isRecording) {
          _updateWaveAmplitudes(bloc.state.waveAmplitudes);
          _waveAnimationController.reset();
          _waveAnimationController.forward();
        }
      }
    });
  }

  void _updateWaveAmplitudes(List<double> waveData) {
    if (waveData.isEmpty) {
      _currentAmplitudes = List.filled(_numberOfWaveBars, 0.1);
      return;
    }

    final random = math.Random();
    _currentAmplitudes = List.generate(_numberOfWaveBars, (i) {
      final baseAmplitude = waveData.isNotEmpty
          ? waveData[i % waveData.length].abs()
          : 0.1;
      final randomVariation = 0.2 + (random.nextDouble() * 0.8);
      return (baseAmplitude * randomVariation).clamp(0.1, 1.0);
    });

    for (int i = 0; i < _waveBarControllers.length; i++) {
      _waveBarControllers[i].animateTo(_currentAmplitudes[i]);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _titleFocusNode.dispose();
    _contentFocusNode.dispose();

    _waveAnimationController.dispose();
    for (var controller in _waveBarControllers) {
      controller.dispose();
    }
    _waveUpdateTimer?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<JournalWritingBloc, JournalWritingState>(
      listener: (context, state) {
        if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error!), backgroundColor: Colors.red),
          );
        }

        // Update text controllers if needed (without triggering listeners)
        if (_titleController.text != state.title) {
          _titleController.removeListener(() {});
          _titleController.text = state.title;
          _titleController.addListener(() {
            context.read<JournalWritingBloc>().add(
              TitleChanged(_titleController.text),
            );
          });
        }
        if (_contentController.text != state.content) {
          _contentController.removeListener(() {});
          _contentController.text = state.content;
          _contentController.addListener(() {
            context.read<JournalWritingBloc>().add(
              ContentChanged(_contentController.text),
            );
          });
        }

        // Handle recording animation
        if (state.isRecording && state.waveAmplitudes.isNotEmpty) {
          _updateWaveAmplitudes(state.waveAmplitudes);
          if (!_waveAnimationController.isAnimating) {
            _waveAnimationController.forward();
          }
        } else if (!state.isRecording) {
          _waveAnimationController.stop();
          _waveAnimationController.reset();
        }

        // Navigate back on successful save
        if (!state.isSaving &&
            !state.hasUnsavedChanges &&
            state.error == null) {
          // Check if we just finished saving (this is a simple check - in production you'd want a more robust state)
          Future.delayed(Duration.zero, () {
            if (mounted) {
              Navigator.pop(context, true);
            }
          });
        }
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
                            if (state.isRecording)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: _buildWaveVisualization()
                                    .animate()
                                    .scale(
                                      begin: const Offset(0.8, 0.8),
                                      duration: 200.ms,
                                      curve: Curves.easeOut,
                                    )
                                    .fadeIn(duration: 200.ms),
                              ),
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
                  fontFamily: GoogleFonts.inter().fontFamily,
                ),
              ),
            ),
          ),
          _buildPillButton(
            label: 'Save',
            onTap: _canSave(state)
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

  bool _canSave(JournalWritingState state) {
    // Entry needs title AND (content OR attachments)
    final hasTitle = state.title.trim().isNotEmpty;
    final hasContentOrAttachments =
        state.content.trim().isNotEmpty ||
        state.selectedImages.isNotEmpty ||
        state.audioRecordings.isNotEmpty;
    return hasTitle &&
        hasContentOrAttachments &&
        !state.isRecording &&
        !state.isSaving;
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
                fontFamily: GoogleFonts.inter().fontFamily,
              ),
              decoration: InputDecoration(
                isCollapsed: true,
                hintText: 'Title',
                hintStyle: TextStyle(
                  color: Colors.black26,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  fontFamily: GoogleFonts.inter().fontFamily,
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
                fontFamily: GoogleFonts.inter().fontFamily,
              ),
              decoration: InputDecoration(
                isCollapsed: true,
                hintText: "What do you wish you'd said today?",
                hintStyle: TextStyle(
                  color: Colors.black26,
                  fontSize: 16,
                  fontFamily: GoogleFonts.inter().fontFamily,
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
              fontFamily: GoogleFonts.inter().fontFamily,
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
              fontFamily: GoogleFonts.inter().fontFamily,
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
        final duration = audio['duration'] as Duration? ?? Duration.zero;
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
                // Placeholder for waveform
                Container(
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: Text(
                      'Waveform',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                        fontFamily: GoogleFonts.inter().fontFamily,
                      ),
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
                    fontFamily: GoogleFonts.inter().fontFamily,
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

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Widget _buildWaveVisualization() {
    return SizedBox(
      height: 48,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_numberOfWaveBars, (index) {
          return AnimatedBuilder(
            animation: _waveBarControllers[index],
            builder: (context, child) {
              final value = _waveBarAnimations[index].value;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Container(
                  width: 4,
                  height: 8 + (value * 24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF115e5a),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }

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
                  fontFamily: GoogleFonts.inter().fontFamily,
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
                          fontFamily: GoogleFonts.inter().fontFamily,
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

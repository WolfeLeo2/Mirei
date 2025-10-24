import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:io';
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
import '../services/recorder_service.dart';
import '../services/journal_mood_integration.dart';

class JournalWritingScreen extends StatelessWidget {
  final dynamic existingEntry; // For edit mode

  const JournalWritingScreen({super.key, this.existingEntry});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => JournalWritingBloc(
        playerService: PlayerService(),
        recorderService: RecorderService(),
        moodIntegration: JournalMoodIntegration(),
      )..add(JournalWritingInitialized()),
      child: _JournalWritingView(existingEntry: existingEntry),
    );
  }
}

class _JournalWritingView extends StatefulWidget {
  final dynamic existingEntry;

  const _JournalWritingView({this.existingEntry});

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

    // Prefill data if editing existing entry
    if (widget.existingEntry != null) {
      try {
        _titleController.text = widget.existingEntry.title ?? '';
        _contentController.text = widget.existingEntry.content ?? '';
      } catch (e) {
        // Ignore if fields don't exist
      }
    }

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

        if (state.saveStatus == JournalSaveStatus.success) {
          Future.microtask(() {
            if (mounted) Navigator.pop(context, true);
          });
        }
      },
      child: BlocBuilder<JournalWritingBloc, JournalWritingState>(
        builder: (context, state) {
          return Scaffold(
            resizeToAvoidBottomInset: true,
            body: SafeArea(
              child: Column(
                children: [
                  // Top toolbar
                  _buildToolbar(context, state),

                  // Main scrollable area
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Images grid (edge to edge, only when images exist)
                          if (state.selectedImages.isNotEmpty) ...[
                            _buildImagesGrid(context, state),
                            const SizedBox(height: 20),
                          ],

                          // Content area with padding
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title field
                                _buildTitleField(context, state),
                                const SizedBox(height: 16),

                                // Date with icon
                                _buildDateRow(context),
                                const SizedBox(height: 24),

                                // Content field
                                _buildContentField(context, state),
                                const SizedBox(height: 32),

                                // Mood section at bottom
                                _buildMoodSection(context, state),
                                const SizedBox(height: 100),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Top toolbar: X and + on left, Save on right
  Widget _buildToolbar(BuildContext context, JournalWritingState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // X button (close) in circular container
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

          const SizedBox(width: 8),

          // + button (add media) in circular container
          Material(
            color: Colors.black12,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: () => _showMediaPicker(context, state),
              customBorder: const CircleBorder(),
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                child: const Icon(Icons.add, color: Colors.black87, size: 24),
              ),
            ),
          ),

          const Spacer(),

          // Save/Update button
          TextButton(
            onPressed: state.canSave
                ? () {
                    HapticFeedback.lightImpact();
                    context.read<JournalWritingBloc>().add(
                      JournalSaveRequested(),
                    );
                  }
                : null,
            style: TextButton.styleFrom(
              backgroundColor: state.canSave
                  ? const Color(0xFF115e5a)
                  : Colors.grey.shade300,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: Text(
              widget.existingEntry != null ? 'Update' : 'Save',
              style: TextStyle(
                color: state.canSave ? Colors.white : Colors.grey.shade500,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Title field with "Add title" placeholder
  Widget _buildTitleField(BuildContext context, JournalWritingState state) {
    return TextField(
      controller: _titleController,
      focusNode: _titleFocusNode,
      style: const TextStyle(
        color: Colors.black87,
        fontSize: 28,
        fontWeight: FontWeight.w600,
        height: 1.2,
      ),
      decoration: const InputDecoration(
        hintText: 'Add title',
        hintStyle: TextStyle(
          color: Colors.black26,
          fontSize: 28,
          fontWeight: FontWeight.w600,
        ),
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
      ),
      maxLines: null,
      textCapitalization: TextCapitalization.sentences,
    );
  }

  /// Date row with calendar icon
  Widget _buildDateRow(BuildContext context) {
    final String date = DateFormat('EEE, d MMM yyyy').format(DateTime.now());

    return Row(
      children: [
        const Icon(
          Icons.calendar_today_outlined,
          size: 16,
          color: Colors.black54,
        ),
        const SizedBox(width: 8),
        Text(
          date,
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  /// Content field with "What's on your mind?" placeholder
  Widget _buildContentField(BuildContext context, JournalWritingState state) {
    return TextField(
      controller: _contentController,
      focusNode: _contentFocusNode,
      style: const TextStyle(
        color: Colors.black87,
        fontSize: 17,
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
      decoration: const InputDecoration(
        hintText: "What's on your mind?",
        hintStyle: TextStyle(
          color: Colors.black26,
          fontSize: 17,
          fontWeight: FontWeight.w400,
        ),
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
      ),
      maxLines: null,
      minLines: 5,
      textCapitalization: TextCapitalization.sentences,
    );
  }

  /// Show media picker bottom sheet (Camera / Gallery)
  void _showMediaPicker(BuildContext context, JournalWritingState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Camera option
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.black87),
                title: const Text(
                  'Camera',
                  style: TextStyle(color: Colors.black87, fontSize: 17),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromCamera();
                },
              ),

              // Gallery option
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.black87),
                title: const Text(
                  'Gallery',
                  style: TextStyle(color: Colors.black87, fontSize: 17),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromGallery();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Pick image from camera
  void _pickFromCamera() {
    context.read<JournalWritingBloc>().add(CameraRequested());
  }

  /// Pick images from gallery
  void _pickFromGallery() {
    context.read<JournalWritingBloc>().add(ImagePickerRequested());
  }

  // New: only images grid
  /// Google Journal-inspired image grid - EDGE TO EDGE
  /// Layout: 1 large image on left, 2 smaller on right (groups of 3)
  /// Horizontally scrollable when multiple groups exist
  Widget _buildImagesGrid(BuildContext context, JournalWritingState state) {
    final images = state.selectedImages;
    if (images.isEmpty) return const SizedBox.shrink();

    // Calculate number of complete groups and remaining images
    final groups = (images.length / 3).ceil();
    final screenWidth = MediaQuery.of(context).size.width;

    return SizedBox(
      height: 250, // Fixed height for consistent layout
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.all(4), // Edge to edge
        itemCount: groups,
        itemBuilder: (context, groupIndex) {
          final startIndex = groupIndex * 3;
          final endIndex = (startIndex + 3).clamp(0, images.length);
          final groupImages = images.sublist(startIndex, endIndex);

          return SizedBox(
            width: screenWidth, // Full screen width per group
            child: Padding(
              padding: EdgeInsets.only(
                right: groupIndex < groups - 1 ? 8 : 0,
                left: groupIndex == 0 ? 0 : 8,
              ),
              child: _buildImageGroup(context, groupImages, startIndex),
            ),
          );
        },
      ),
    );
  }

  /// Builds a single group of images (1 large + up to 2 small)
  Widget _buildImageGroup(
    BuildContext context,
    List<dynamic> groupImages,
    int startIndex,
  ) {
    final hasMultiple = groupImages.length > 1;

    return Row(
      children: [
        // Large image on the left
        Expanded(
          flex: hasMultiple ? 3 : 1,
          child: _buildImageItem(
            context,
            groupImages[0],
            startIndex,
            isLarge: true,
          ),
        ),
        // Smaller images on the right (if any)
        if (hasMultiple) ...[
          const SizedBox(width: 4),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                // Second image (top right)
                Expanded(
                  child: _buildImageItem(
                    context,
                    groupImages[1],
                    startIndex + 1,
                    isLarge: false,
                  ),
                ),
                // Third image (bottom right) if exists
                if (groupImages.length > 2) ...[
                  const SizedBox(height: 4),
                  Expanded(
                    child: _buildImageItem(
                      context,
                      groupImages[2],
                      startIndex + 2,
                      isLarge: false,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// Builds individual image with long-press context menu
  Widget _buildImageItem(
    BuildContext context,
    dynamic imageFile,
    int index, {
    required bool isLarge,
  }) {
    return GestureDetector(
      onLongPressStart: (details) {
        HapticFeedback.mediumImpact();
        _showImageContextMenu(context, details.globalPosition, index);
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(File(imageFile.path), fit: BoxFit.cover),
          ),
        ],
      ),
    );
  }

  /// Show context menu for image deletion
  void _showImageContextMenu(BuildContext context, Offset position, int index) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;

    showMenu(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(position.dx, position.dy, 0, 0),
        Rect.fromLTWH(0, 0, overlay.size.width, overlay.size.height),
      ),

      items: [
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: const [
              Icon(Icons.delete, color: Colors.red, size: 20),
              SizedBox(width: 12),
              Text('Delete', style: TextStyle(color: Colors.red, fontSize: 16)),
            ],
          ),
        ),
      ],
      elevation: 8,
    ).then((value) {
      if (value == 'delete') {
        HapticFeedback.lightImpact();
        context.read<JournalWritingBloc>().add(ImageRemoved(index));
      }
    });
  }

  // Mood section
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'How are you feeling?',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 17,
                fontWeight: FontWeight.w600,
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
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
        // Mood Buttons Horizontal Scroll
        RepaintBoundary(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: List.generate(MoodConstants.moodTypes.length, (index) {
                final mood = MoodConstants.moodTypes[index];
                return MoodButton(
                  Mood: mood,
                  svgPath: kMoodSvg[mood]!,
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

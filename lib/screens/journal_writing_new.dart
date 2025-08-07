import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audio_waveforms/audio_waveforms.dart';

class JournalWritingScreen extends StatefulWidget {
  const JournalWritingScreen({super.key});

  @override
  _JournalWritingScreenState createState() => _JournalWritingScreenState();
}

class _JournalWritingScreenState extends State<JournalWritingScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _contentFocusNode = FocusNode();

  final ImagePicker _picker = ImagePicker();
  FlutterSoundRecorder? _recorder;
  RecorderController? _recorderController;
  bool _isRecording = false;
  final List<XFile> _selectedImages = [];
  final List<Map<String, dynamic>> _audioRecordings = [];
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? _recordingSnackBar;

  @override
  void initState() {
    super.initState();
    _initializeRecorder();
    _checkPermissions();
  }

  Future<void> _initializeRecorder() async {
    try {
      _recorder = FlutterSoundRecorder();
      _recorderController = RecorderController();
      await _recorder!.openRecorder();
    } catch (e) {
      print('Error initializing recorder: $e');
    }
  }

  Future<void> _checkPermissions() async {
    // Check microphone permission
    final micStatus = await Permission.microphone.status;
    print('Microphone permission status: $micStatus');

    // Check photo permission
    final photoStatus = await Permission.photos.status;
    print('Photo permission status: $photoStatus');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _titleFocusNode.dispose();
    _contentFocusNode.dispose();
    _recorder?.closeRecorder();
    _recorder = null;
    _recorderController?.dispose();
    _recordingSnackBar?.close();
    super.dispose();
  }

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
          'New Entry',
          style: TextStyle(
            color: const Color(0xFF115e5a),
            fontSize: 20,
            fontWeight: FontWeight.w600,
            fontFamily: GoogleFonts.inter().fontFamily,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _saveJournalEntry,
            child: Text(
              'Save',
              style: TextStyle(
                color: const Color(0xFF115e5a),
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: GoogleFonts.inter().fontFamily,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date display
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF115e5a).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: const Color(0xFF115e5a),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now()),
                      style: TextStyle(
                        color: const Color(0xFF115e5a),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        fontFamily: GoogleFonts.inter().fontFamily,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Title input
              Text(
                'Title',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  fontFamily: GoogleFonts.inter().fontFamily,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _titleController,
                focusNode: _titleFocusNode,
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: GoogleFonts.inter().fontFamily,
                ),
                decoration: InputDecoration(
                  hintText: 'Give your entry a title...',
                  hintStyle: TextStyle(
                    color: Colors.black38,
                    fontFamily: GoogleFonts.inter().fontFamily,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Content input
              Text(
                'Your thoughts',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  fontFamily: GoogleFonts.inter().fontFamily,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _contentController,
                  focusNode: _contentFocusNode,
                  maxLines: 15,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    fontFamily: GoogleFonts.inter().fontFamily,
                  ),
                  decoration: InputDecoration(
                    hintText:
                        'What\'s on your mind? Write about your day, your feelings, your goals, or anything that comes to mind...',
                    hintStyle: TextStyle(
                      color: Colors.black38,
                      fontFamily: GoogleFonts.inter().fontFamily,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(20),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Media attachments section
              Row(
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
                      // Add image button
                      GestureDetector(
                        onTap: _pickImages,
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
                            children: [
                              const Icon(
                                Icons.image,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Photo',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: GoogleFonts.inter().fontFamily,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Add audio button
                      GestureDetector(
                        onTap: _isRecording ? _stopRecording : _startRecording,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _isRecording
                                ? Colors.red
                                : const Color(0xFF115e5a),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isRecording ? Icons.stop : Icons.mic,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _isRecording ? 'Stop' : 'Voice',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: GoogleFonts.inter().fontFamily,
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
              const SizedBox(height: 16),

              // Media grid
              if (_selectedImages.isNotEmpty || _audioRecordings.isNotEmpty)
                _buildMediaGrid(),

              const SizedBox(
                height: 100,
              ), // Extra space for comfortable scrolling
            ],
          ),
        ),
      ),
    );
  }

  void _saveJournalEntry() {
    if (_titleController.text.trim().isEmpty ||
        _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please fill in both title and content',
            style: TextStyle(fontFamily: GoogleFonts.inter().fontFamily),
          ),
          backgroundColor: const Color(0xFF115e5a),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    // Here you would normally save to a database or local storage
    // For now, we'll just show a success message and navigate back
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Journal entry saved successfully!',
          style: TextStyle(fontFamily: GoogleFonts.inter().fontFamily),
        ),
        backgroundColor: const Color(0xFF115e5a),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    // Navigate back to journal list
    Navigator.pop(context);
  }

  Future<void> _startRecording() async {
    try {
      // Check current microphone permission status
      PermissionStatus status = await Permission.microphone.status;

      if (status.isDenied) {
        status = await Permission.microphone.request();
      }

      if (status.isPermanentlyDenied) {
        _showPermissionDialog();
        return;
      }

      if (!status.isGranted) {
        _showPermissionDeniedSnackBar();
        return;
      }

      // Check if recorder is available
      if (_recorder == null) {
        await _initializeRecorder();
      }

      // Start recording with a proper file path
      final directory = await getTemporaryDirectory();
      final audioDir = Directory('${directory.path}/journal_audio');
      if (!audioDir.existsSync()) {
        audioDir.createSync(recursive: true);
      }
      final path =
          '${audioDir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.aac';

      await _recorder!.startRecorder(toFile: path, codec: Codec.aacADTS);

      // Start waveform recording
      await _recorderController!.record(path: path);

      setState(() {
        _isRecording = true;
      });

      // Show persistent recording indicator
      _showPersistentRecordingSnackBar();
    } catch (e) {
      print('Error starting recording: $e');
      _showErrorSnackBar('Error starting recording: $e');
    }
  }

  void _showPersistentRecordingSnackBar() {
    if (!mounted) return;

    _recordingSnackBar = ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Recording voice note...'),
            const Spacer(),
            TextButton(
              onPressed: _stopRecording,
              child: const Text(
                'STOP',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF115e5a),
        duration: const Duration(days: 1), // Persist until manually closed
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _stopRecording() async {
    try {
      if (_recorder == null || !_isRecording) return;

      // Close the persistent SnackBar
      _recordingSnackBar?.close();

      // Stop both recorders
      final path = await _recorder!.stopRecorder();
      final waveformPath = await _recorderController!.stop();

      if (path != null && File(path).existsSync()) {
        // Calculate duration
        final duration = await _getAudioDuration(path);

        setState(() {
          _audioRecordings.add({
            'path': path,
            'duration': duration,
            'timestamp': DateTime.now(),
            'waveformData': _recorderController!.waveData,
          });
          _isRecording = false;
        });

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Voice note recorded successfully!'),
              backgroundColor: const Color(0xFF115e5a),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } else {
        setState(() {
          _isRecording = false;
        });
        _showErrorSnackBar('Failed to save recording');
      }
    } catch (e) {
      setState(() {
        _isRecording = false;
      });
      print('Error stopping recording: $e');
      _showErrorSnackBar('Error stopping recording: $e');
    }
  }

  Future<Duration> _getAudioDuration(String path) async {
    try {
      // This is a simple approximation - in a real app you might want to use
      // a more accurate method to get the actual audio file duration
      final file = File(path);
      final size = await file.length();
      // Rough estimation: AAC at 128kbps ≈ 16KB per second
      final seconds = (size / 16000).round();
      return Duration(seconds: seconds);
    } catch (e) {
      return const Duration(seconds: 0);
    }
  }

  Future<void> _pickImages() async {
    try {
      // Check photo library permission first
      PermissionStatus status = await Permission.photos.status;

      if (status.isDenied) {
        status = await Permission.photos.request();
      }

      if (status.isPermanentlyDenied) {
        _showPhotoPermissionDialog();
        return;
      }

      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${images.length} image(s) added successfully!'),
              backgroundColor: const Color(0xFF115e5a),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    } catch (e) {
      print('Error picking images: $e');
      _showErrorSnackBar('Error selecting images: $e');
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _removeAudio(int index) {
    try {
      final audioData = _audioRecordings[index];
      final file = File(audioData['path']);
      if (file.existsSync()) {
        file.deleteSync();
      }
    } catch (e) {
      print('Error deleting audio file: $e');
    }

    setState(() {
      _audioRecordings.removeAt(index);
    });
  }

  Widget _buildMediaGrid() {
    return StaggeredGrid.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        // Display images
        ..._selectedImages.asMap().entries.map((entry) {
          final index = entry.key;
          final image = entry.value;

          return StaggeredGridTile.count(
            crossAxisCellCount: 1,
            mainAxisCellCount: 1,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(image.path),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => _removeImage(index),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),

        // Display audio recordings
        ..._audioRecordings.asMap().entries.map((entry) {
          final index = entry.key;
          final audioData = entry.value;

          return StaggeredGridTile.count(
            crossAxisCellCount: 1,
            mainAxisCellCount: 1,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with mic icon and delete button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF115e5a).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.mic,
                          color: Color(0xFF115e5a),
                          size: 16,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _removeAudio(index),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.red,
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Waveform visualization
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF115e5a).withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child:
                            audioData['waveformData'] != null &&
                                (audioData['waveformData'] as List).isNotEmpty
                            ? _buildWaveform(audioData['waveformData'])
                            : const Icon(
                                Icons.graphic_eq,
                                color: Color(0xFF115e5a),
                                size: 24,
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Duration
                  Center(
                    child: Text(
                      _formatDuration(audioData['duration']),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                        fontFamily: GoogleFonts.inter().fontFamily,
                      ),
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

  Widget _buildWaveform(List<double> waveformData) {
    if (waveformData.isEmpty) {
      return const Icon(Icons.graphic_eq, color: Color(0xFF115e5a), size: 24);
    }

    return CustomPaint(
      size: const Size(double.infinity, 40),
      painter: WaveformPainter(
        waveformData: waveformData,
        color: const Color(0xFF115e5a),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    if (duration.inHours > 0) {
      return "${duration.inHours}:${twoDigits(duration.inMinutes.remainder(60))}:${twoDigits(duration.inSeconds.remainder(60))}";
    }
    return "${duration.inMinutes}:${twoDigits(duration.inSeconds.remainder(60))}";
  }

  void _showPermissionDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Microphone Permission Required',
            style: TextStyle(
              fontFamily: GoogleFonts.inter().fontFamily,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'To record voice notes, please grant microphone permission in your device settings.',
            style: TextStyle(fontFamily: GoogleFonts.inter().fontFamily),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontFamily: GoogleFonts.inter().fontFamily,
                  color: Colors.grey,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: Text(
                'Open Settings',
                style: TextStyle(
                  fontFamily: GoogleFonts.inter().fontFamily,
                  color: const Color(0xFF115e5a),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showPermissionDeniedSnackBar() {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Microphone permission is required for voice notes',
        ),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Settings',
          textColor: Colors.white,
          onPressed: () => openAppSettings(),
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showPhotoPermissionDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Photo Access Required',
            style: TextStyle(
              fontFamily: GoogleFonts.inter().fontFamily,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'To add photos to your journal, please grant photo library permission in your device settings.',
            style: TextStyle(fontFamily: GoogleFonts.inter().fontFamily),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontFamily: GoogleFonts.inter().fontFamily,
                  color: Colors.grey,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: Text(
                'Open Settings',
                style: TextStyle(
                  fontFamily: GoogleFonts.inter().fontFamily,
                  color: const Color(0xFF115e5a),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// Custom painter for waveform visualization
class WaveformPainter extends CustomPainter {
  final List<double> waveformData;
  final Color color;

  WaveformPainter({required this.waveformData, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (waveformData.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final width = size.width;
    final height = size.height;
    final centerY = height / 2;

    // Calculate the width of each bar
    final barWidth = width / waveformData.length;

    for (int i = 0; i < waveformData.length; i++) {
      final x = i * barWidth + barWidth / 2;
      final amplitude = waveformData[i].clamp(0.0, 1.0);
      final barHeight = amplitude * height * 0.8; // Use 80% of available height

      // Draw the waveform bar
      canvas.drawLine(
        Offset(x, centerY - barHeight / 2),
        Offset(x, centerY + barHeight / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate != this;
  }
}

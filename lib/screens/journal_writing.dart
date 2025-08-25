import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:just_audio/just_audio.dart';
import 'package:realm/realm.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/realm_models.dart';
import '../utils/realm_database_helper.dart';
import 'journal_list.dart';

class JournalWritingScreen extends StatefulWidget {
  const JournalWritingScreen({super.key});

  @override
  _JournalWritingScreenState createState() => _JournalWritingScreenState();
}

class _JournalWritingScreenState extends State<JournalWritingScreen>
    with TickerProviderStateMixin {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _contentFocusNode = FocusNode();

  final ImagePicker _picker = ImagePicker();
  FlutterSoundRecorder? _recorder;
  RecorderController? _recorderController;
  AudioPlayer? _audioPlayer;
  bool _isRecording = false;
  String? _currentlyPlayingPath;
  final List<XFile> _selectedImages = [];
  final List<Map<String, dynamic>> _audioRecordings = [];
  final List<PlayerController> _waveformControllers =
      []; // For managing waveform players

  // Real-time sound wave visualization
  late AnimationController _waveAnimationController;
  late List<AnimationController> _waveBarControllers;
  late List<Animation<double>> _waveBarAnimations;
  final int _numberOfWaveBars = 20;
  List<double> _currentAmplitudes = [];
  bool _showWaveVisualization = false;
  Timer? _waveUpdateTimer;

  // Recording timer
  DateTime? _recordingStartTime;
  Duration _recordingDuration = Duration.zero;
  Timer? _recordingTimer;

  @override
  void initState() {
    super.initState();
    _initializeRecorder();
    _checkPermissions();
    _initializeWaveAnimations();
  }

  void _initializeWaveAnimations() {
    _waveAnimationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _waveBarControllers = List.generate(
      _numberOfWaveBars,
      (index) => AnimationController(
        duration: Duration(
          milliseconds: 150 + (index * 50),
        ), // Staggered timing
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

    // Start continuous wave animation when recording
    _waveAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.completed && _isRecording) {
        _updateWaveAmplitudes();
        _waveAnimationController.reset();
        _waveAnimationController.forward();
      }
    });
  }

  void _updateWaveAmplitudes() {
    if (_recorderController == null || !_isRecording) return;

    final waveData = _recorderController!.waveData;
    if (waveData.isEmpty) {
      _currentAmplitudes = List.filled(_numberOfWaveBars, 0.1);
      return;
    }

    // Sample recent waveform data
    final recentData = waveData.length > 50
        ? waveData.sublist(waveData.length - 50)
        : waveData;

    // Generate random-ish amplitudes based on actual data for visual appeal
    final random = math.Random();
    _currentAmplitudes = List.generate(_numberOfWaveBars, (i) {
      final baseAmplitude = recentData.isNotEmpty
          ? recentData[i % recentData.length].abs()
          : 0.1;
      final randomVariation = 0.2 + (random.nextDouble() * 0.8);
      return (baseAmplitude * randomVariation).clamp(0.1, 1.0);
    });

    // Update individual bar animations
    for (int i = 0; i < _waveBarControllers.length; i++) {
      _waveBarControllers[i].animateTo(_currentAmplitudes[i]);
    }
  }

  Future<void> _initializeRecorder() async {
    try {
      _recorder = FlutterSoundRecorder();
      _recorderController = RecorderController();
      _audioPlayer = AudioPlayer();
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

    // Check camera permission
    final cameraStatus = await Permission.camera.status;
    print('Camera permission status: $cameraStatus');
  }

  @override
  void dispose() {
    _recorderController?.dispose();
    _audioPlayer?.dispose();
    _recorder?.closeRecorder();
    _titleController.dispose();
    _contentController.dispose();
    _titleFocusNode.dispose();
    _contentFocusNode.dispose();
    for (var controller in _waveformControllers) {
      controller.dispose();
    }

    // Dispose wave animation controllers
    _waveAnimationController.dispose();
    for (var controller in _waveBarControllers) {
      controller.dispose();
    }

    // Cancel any running timers
    _waveUpdateTimer?.cancel();
    _recordingTimer?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Scaffold(
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
                    color: const Color(0xFF115e5a).withValues(alpha: 0.1),
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
                          onTap: _isRecording
                              ? _stopRecording
                              : _startRecording,
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

                // Real-time wave visualization during recording
                if (_showWaveVisualization)
                  _buildWaveVisualization()
                      .animate()
                      .scale(
                        begin: const Offset(0.8, 0.8),
                        duration: 200.ms,
                        curve: Curves.easeOut,
                      )
                      .fadeIn(duration: 200.ms),

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
      ),
    );
  }

  Future<void> _saveJournalEntry() async {
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

    try {
      // Prepare audio recordings for saving
      final List<AudioRecordingData> audioRecordings = _audioRecordings.map((
        audioData,
      ) {
        return AudioRecordingData(
          path: audioData['path'],
          duration: audioData['duration'],
          timestamp: audioData['timestamp'],
        );
      }).toList();

      // Create journal entry
      final journalEntry = JournalEntryRealm(
        ObjectId(),
        _titleController.text.trim(),
        _contentController.text.trim(),
        DateTime.now(),
        // Removed mood field - moods are stored separately in MoodEntryRealm
        imagePathsString: _selectedImages
            .map((image) => image.path)
            .join('|||'),
        audioRecordingsString: audioRecordings
            .map((audio) => audio.toJson())
            .join('|'),
      );

      // Save to database
      final dbHelper = RealmDatabaseHelper();
      await dbHelper.insertJournalEntry(journalEntry);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Journal entry saved successfully!',
              style: TextStyle(fontFamily: GoogleFonts.inter().fontFamily),
            ),
            backgroundColor: const Color(0xFF115e5a),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );

        // Navigate back to journal list
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const JournalListScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error saving journal entry: $e',
              style: TextStyle(fontFamily: GoogleFonts.inter().fontFamily),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
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

      // Start recording with proper file path management
      final directory = await getTemporaryDirectory();
      final audioDir = Directory('${directory.path}/journal_audio');
      if (!audioDir.existsSync()) {
        audioDir.createSync(recursive: true);
      }
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final audioPath = '${audioDir.path}/audio_$timestamp.aac';

      // Start flutter_sound recorder for audio file
      await _recorder!.startRecorder(toFile: audioPath, codec: Codec.aacADTS);

      // Start waveform recording (uses internal recording)
      await _recorderController!.record();

      setState(() {
        _isRecording = true;
        _showWaveVisualization = true;
        _recordingStartTime = DateTime.now();
        _recordingDuration = Duration.zero;
      });

      // Start wave animation
      _waveAnimationController.forward();

      // Start periodic wave updates
      _waveUpdateTimer = Timer.periodic(const Duration(milliseconds: 100), (
        timer,
      ) {
        if (_isRecording && mounted) {
          _updateWaveAmplitudes();
        }
      });

      // Start recording timer
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_isRecording && _recordingStartTime != null && mounted) {
          setState(() {
            _recordingDuration = DateTime.now().difference(
              _recordingStartTime!,
            );
          });
        }
      });

      // Removed persistent recording snackbar - it's no longer needed
    } catch (e) {
      print('Error starting recording: $e');
      _showErrorSnackBar('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      if (_recorder == null || !_isRecording) return;

      // Stop both recorders
      final audioPath = await _recorder!.stopRecorder();
      await _recorderController!.stop();

      if (audioPath != null && File(audioPath).existsSync()) {
        // Get accurate duration using just_audio
        final duration = await _getAccurateAudioDuration(audioPath);

        // Sample waveform data for performance (optimized for full-width container)
        final waveformData = _sampleWaveformData(
          _recorderController!.waveData,
          100,
        );

        final playerController = PlayerController();
        await playerController.preparePlayer(
          path: audioPath,
          shouldExtractWaveform: true,
          noOfSamples: 100,
          volume: 1.0,
        );

        setState(() {
          _audioRecordings.add({
            'path': audioPath,
            'duration': duration,
            'timestamp': DateTime.now(),
            'waveformData': waveformData,
          });
          _waveformControllers.add(playerController);
          _isRecording = false;
          _showWaveVisualization = false;
        });

        // Stop wave animation
        _waveAnimationController.stop();
        _waveAnimationController.reset();
        for (var controller in _waveBarControllers) {
          controller.reset();
        }

        // Cancel wave update timer
        _waveUpdateTimer?.cancel();
        _waveUpdateTimer = null;

        // Stop recording timer
        _recordingTimer?.cancel();
        _recordingTimer = null;
        _recordingStartTime = null;
        _recordingDuration = Duration.zero;

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
          _showWaveVisualization = false;
        });

        // Stop wave animation on error
        _waveAnimationController.stop();
        _waveAnimationController.reset();

        // Cancel wave update timer
        _waveUpdateTimer?.cancel();
        _waveUpdateTimer = null;

        // Stop recording timer
        _recordingTimer?.cancel();
        _recordingTimer = null;

        _showErrorSnackBar('Failed to save recording');
      }
    } catch (e) {
      setState(() {
        _isRecording = false;
        _showWaveVisualization = false;
      });

      // Stop wave animation on error
      _waveAnimationController.stop();
      _waveAnimationController.reset();

      // Cancel wave update timer
      _waveUpdateTimer?.cancel();
      _waveUpdateTimer = null;

      // Stop recording timer
      _recordingTimer?.cancel();
      _recordingTimer = null;

      print('Error stopping recording: $e');
      _showErrorSnackBar('Error stopping recording: $e');
    }
  }

  // Improved duration calculation using just_audio
  Future<Duration> _getAccurateAudioDuration(String path) async {
    try {
      final tempPlayer = AudioPlayer();
      await tempPlayer.setFilePath(path);
      final duration = tempPlayer.duration ?? const Duration(seconds: 0);
      await tempPlayer.dispose();
      return duration;
    } catch (e) {
      print('Error getting audio duration: $e');
      // Fallback to file size estimation
      return _getEstimatedDuration(path);
    }
  }

  // Fallback duration estimation
  Future<Duration> _getEstimatedDuration(String path) async {
    try {
      final file = File(path);
      final size = await file.length();
      // AAC at ~128kbps ≈ 16KB per second
      final seconds = (size / 16000).round();
      return Duration(seconds: seconds);
    } catch (e) {
      return const Duration(seconds: 0);
    }
  }

  // Sample waveform data for performance optimization
  List<double> _sampleWaveformData(List<double> data, int maxPoints) {
    if (data.isEmpty) return [];
    if (data.length <= maxPoints) return data;

    final step = data.length / maxPoints;
    return List.generate(maxPoints, (i) {
      final index = (i * step).round().clamp(0, data.length - 1);
      return data[index];
    });
  }

  Future<void> _playAudio(String audioPath) async {
    try {
      if (_currentlyPlayingPath == audioPath) {
        // Stop if already playing this audio
        await _audioPlayer!.stop();
        setState(() {
          _currentlyPlayingPath = null;
        });
      } else {
        // Stop any currently playing audio and start new one
        await _audioPlayer!.stop();
        await _audioPlayer!.setFilePath(audioPath);
        await _audioPlayer!.play();

        setState(() {
          _currentlyPlayingPath = audioPath;
        });

        // Listen for completion
        _audioPlayer!.playerStateStream.listen((state) {
          if (state.processingState == ProcessingState.completed) {
            setState(() {
              _currentlyPlayingPath = null;
            });
          }
        });
      }
    } catch (e) {
      print('Error playing audio: $e');
      _showErrorSnackBar('Error playing audio: $e');
    }
  }

  Future<void> _pickImages() async {
    try {
      // Show options dialog for camera or gallery
      final choice = await showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(
              'Add Image',
              style: TextStyle(fontFamily: GoogleFonts.inter().fontFamily),
            ),
            content: Text(
              'Choose an option:',
              style: TextStyle(fontFamily: GoogleFonts.inter().fontFamily),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop('camera'),
                child: Text(
                  'Camera',
                  style: TextStyle(fontFamily: GoogleFonts.inter().fontFamily),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop('gallery'),
                child: Text(
                  'Gallery',
                  style: TextStyle(fontFamily: GoogleFonts.inter().fontFamily),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Cancel',
                  style: TextStyle(fontFamily: GoogleFonts.inter().fontFamily),
                ),
              ),
            ],
          );
        },
      );

      if (choice == null) return;

      List<XFile> images = [];

      if (choice == 'camera') {
        // Check camera permission first
        PermissionStatus cameraStatus = await Permission.camera.status;
        if (cameraStatus.isDenied) {
          cameraStatus = await Permission.camera.request();
        }
        if (cameraStatus.isPermanentlyDenied) {
          _showCameraPermissionDialog();
          return;
        }

        // Take photo with camera
        final XFile? photo = await _picker.pickImage(
          source: ImageSource.camera,
        );
        if (photo != null) {
          images = [photo];
        }
      } else {
        // Check photo library permission first
        PermissionStatus status = await Permission.photos.status;
        if (status.isDenied) {
          status = await Permission.photos.request();
        }
        if (status.isPermanentlyDenied) {
          _showPhotoPermissionDialog();
          return;
        }

        // Pick from gallery
        images = await _picker.pickMultiImage();
      }
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
      _waveformControllers[index].dispose();
      _waveformControllers.removeAt(index);
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
          final isPlaying = _currentlyPlayingPath == audioData['path'];

          return StaggeredGridTile.count(
            crossAxisCellCount: 2, // Make it full width
            mainAxisCellCount: 0.5, // Adjust height to be more compact
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors
                    .grey
                    .shade100, // Light grey background like the image
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Play button
                  GestureDetector(
                    onTap: () => _playAudio(audioData['path']),
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

                  // Waveform and Duration
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AudioFileWaveforms(
                          size: Size(
                            MediaQuery.of(context).size.width * 0.6,
                            30,
                          ),
                          playerController:
                              _waveformControllers[index], // Use the correct controller
                          waveformType: WaveformType.fitWidth,
                          playerWaveStyle: PlayerWaveStyle(
                            fixedWaveColor: Colors.grey.shade400,
                            liveWaveColor: const Color(0xFF115e5a),
                            spacing: 2.1, // Reduced for a more compact look
                            showSeekLine: false,
                            waveCap: StrokeCap.round,
                            waveThickness: 2,
                            scaleFactor: 100,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDuration(audioData['duration']),
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
                    onTap: () => _removeAudio(index),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.grey,
                        size: 16,
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

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    if (duration.inHours > 0) {
      return "${duration.inHours}:${twoDigits(duration.inMinutes.remainder(60))}:${twoDigits(duration.inSeconds.remainder(60))}";
    }
    return "${duration.inMinutes}:${twoDigits(duration.inSeconds.remainder(60))}";
  }

  Widget _buildWaveVisualization() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF115e5a), Color(0xFF0d4a47)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF115e5a).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Recording indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  )
                  .animate(onPlay: (controller) => controller.repeat())
                  .scale(
                    begin: const Offset(1.0, 1.0),
                    end: const Offset(1.2, 1.2),
                  )
                  .then()
                  .scale(
                    begin: const Offset(1.2, 1.2),
                    end: const Offset(1.0, 1.0),
                  ),
              const SizedBox(width: 12),
              Column(
                children: [
                  Text(
                    'Recording...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: GoogleFonts.inter().fontFamily,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDuration(_recordingDuration),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: GoogleFonts.inter().fontFamily,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Real-time wave bars
          SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(_numberOfWaveBars, (index) {
                return AnimatedBuilder(
                  animation: _waveBarAnimations[index],
                  builder: (context, child) {
                    return Container(
                      width: 3,
                      height: 60 * _waveBarAnimations[index].value,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  },
                );
              }),
            ),
          ),
          const SizedBox(height: 16),

          // Recording time and stop button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tap anywhere to stop',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 12,
                  fontFamily: GoogleFonts.inter().fontFamily,
                ),
              ),
              GestureDetector(
                onTap: _stopRecording,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.stop, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Stop',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
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
    );
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

  void _showCameraPermissionDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Camera Access Required',
            style: TextStyle(
              fontFamily: GoogleFonts.inter().fontFamily,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            'To take photos for your journal, please grant camera permission in your device settings.',
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

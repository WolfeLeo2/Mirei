import 'package:flutter/material.dart';

class AudioStreamingInfo extends StatelessWidget {
  const AudioStreamingInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Theme.of(context).primaryColor),
                const SizedBox(width: 12),
                const Text(
                  'Audio Streaming Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            _buildInfoSection(
              title: '🎵 Current Status',
              content: 'The app currently displays YouTube Music content but cannot stream audio directly due to API limitations.',
            ),
            
            _buildInfoSection(
              title: '🔧 Technical Details',
              content: 'ytmusicapi_dart provides metadata (titles, artists, thumbnails) but not direct streaming URLs for copyright protection.',
            ),
            
            _buildInfoSection(
              title: '📱 just_audio_background',
              content: 'Single player instance means only one AudioPlayer can be active at a time. Multiple instances would conflict with background playback and system audio controls.',
            ),
            
            _buildInfoSection(
              title: '💡 Solutions',
              content: '• Use YouTube Data API v3 with proper OAuth\n• Implement YouTube IFrame Player\n• Use local music files\n• Integrate with legal streaming APIs',
            ),
            
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Got it'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection({required String title, required String content}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black54,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// Show audio streaming information dialog
void showAudioStreamingInfo(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => const AudioStreamingInfo(),
  );
}

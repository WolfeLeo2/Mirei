import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/youtube_music_bloc.dart';
import '../services/youtube_music_auth_helper.dart';

class YouTubeMusicAuthStatus extends StatelessWidget {
  const YouTubeMusicAuthStatus({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<YouTubeMusicBloc, YouTubeMusicState>(
      builder: (context, state) {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'YouTube Music Status',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Using Public Access Only',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Authentication not yet available in ytmusicapi_dart. Only public search and browsing is supported.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => _showAuthInfo(context),
                icon: const Icon(Icons.help_outline, size: 16),
                label: const Text('Learn More'),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAuthInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('YouTube Music Authentication'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Current Status:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                YouTubeMusicAuthHelper.currentStatus,
                style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
              const SizedBox(height: 16),
              Text(
                'Available Features:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildFeaturesList(),
              const SizedBox(height: 16),
              Text(
                'Future Options:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                YouTubeMusicAuthHelper.futureOptions,
                style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesList() {
    final availableFeatures = [
      '✅ Search songs, albums, artists',
      '✅ Browse public playlists',
      '✅ Get trending music',
      '✅ Access public content',
    ];

    final unavailableFeatures = [
      '❌ Personal liked songs',
      '❌ Personal playlists',
      '❌ Library management',
      '❌ Personal recommendations',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...availableFeatures.map((feature) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(feature, style: TextStyle(fontSize: 12)),
        )),
        const SizedBox(height: 8),
        ...unavailableFeatures.map((feature) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(feature, style: TextStyle(fontSize: 12, color: Colors.grey)),
        )),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../services/youtube_music_streaming_service.dart';
import '../models/youtube_music_models.dart';

/// Demo screen showing InnerTube streaming capabilities
class InnerTubeDemo extends StatefulWidget {
  const InnerTubeDemo({super.key});

  @override
  State<InnerTubeDemo> createState() => _InnerTubeDemoState();
}

class _InnerTubeDemoState extends State<InnerTubeDemo> {
  final YouTubeMusicStreamingService _streamingService = YouTubeMusicStreamingService();
  final TextEditingController _searchController = TextEditingController();
  
  List<YouTubeSong> _searchResults = [];
  bool _isLoading = false;
  String? _currentlyPlaying;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  Future<void> _initializeService() async {
    try {
      setState(() => _isLoading = true);
      await _streamingService.initialize();
      setState(() => _isInitialized = true);
      
      // Load some initial suggestions
      final suggestions = await _streamingService.getSuggestions();
      setState(() {
        _searchResults = suggestions.take(10).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to initialize: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _testConnection() async {
    if (!_isInitialized) return;

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Testing connection...'),
          backgroundColor: Colors.blue,
        ),
      );

      final success = await _streamingService.testConnection();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success 
              ? '✅ Connection test successful! All systems working.'
              : '❌ Connection test failed. Check network and try again.'),
            backgroundColor: success ? Colors.green : Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _testInstances() async {
    if (!_isInitialized) return;

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Testing Piped instances...'),
          backgroundColor: Colors.orange,
        ),
      );

      final results = await _streamingService.testPipedInstances();
      
      if (mounted) {
        final workingCount = results.values.where((v) => v).length;
        final totalCount = results.length;
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Instance Test Results ($workingCount/$totalCount working)'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: results.entries.map((entry) {
                  final url = entry.key;
                  final working = entry.value;
                  final domain = Uri.parse(url).host;
                  
                  return ListTile(
                    leading: Icon(
                      working ? Icons.check_circle : Icons.error,
                      color: working ? Colors.green : Colors.red,
                    ),
                    title: Text(domain),
                    subtitle: Text(working ? 'Working' : 'Failed'),
                  );
                }).toList(),
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _searchSongs(String query) async {
    if (query.isEmpty || !_isInitialized) return;

    setState(() => _isLoading = true);
    
    try {
      final results = await _streamingService.searchSongs(query);
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _playSong(YouTubeSong song) async {
    if (!_isInitialized) return;

    setState(() {
      _isLoading = true;
      _currentlyPlaying = song.title;
    });

    try {
      final success = await _streamingService.playYouTubeSong(song);
      
      setState(() => _isLoading = false);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Now playing: ${song.title}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        setState(() => _currentlyPlaying = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Failed to play song - may be restricted'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _currentlyPlaying = null;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Playback error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showStreamingInfo(YouTubeSong song) async {
    if (!_isInitialized) return;

    try {
      final streamingInfo = await _streamingService.getStreamingInfo(song.videoId);
      
      if (streamingInfo != null && mounted) {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.grey[900],
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) => Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Streaming Info',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildInfoRow('Video ID', streamingInfo.videoId),
                _buildInfoRow('Audio Quality', streamingInfo.audioQuality ?? 'N/A'),
                _buildInfoRow('Audio Codec', streamingInfo.audioCodec ?? 'N/A'),
                _buildInfoRow('Audio Bitrate', '${streamingInfo.audioBitrate ?? 'N/A'} kbps'),
                _buildInfoRow('Duration', streamingInfo.duration?.toString().split('.').first ?? 'N/A'),
                _buildInfoRow('Available Qualities', streamingInfo.availableQualities.join(', ')),
                if (streamingInfo.audioUrl != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Audio URL:',
                    style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${streamingInfo.audioUrl!.substring(0, 100)}...',
                      style: TextStyle(
                        color: Colors.green[300],
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to get streaming info: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey[400],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[950],
      appBar: AppBar(
        title: const Text('InnerTube Demo'),
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Status Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: _isInitialized 
                ? Colors.green.withOpacity(0.1) 
                : Colors.orange.withOpacity(0.1),
            child: Row(
              children: [
                Icon(
                  _isInitialized ? Icons.check_circle : Icons.warning,
                  color: _isInitialized ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _isInitialized 
                        ? '✅ InnerTube Service Ready - Full YouTube Music Streaming'
                        : '⚠️ Initializing InnerTube Service...',
                    style: TextStyle(
                      color: _isInitialized ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Test Connection Button
          if (_isInitialized)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _testConnection,
                      icon: const Icon(Icons.network_check),
                      label: const Text('Test Connection'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _testInstances,
                      icon: const Icon(Icons.dns),
                      label: const Text('Test Instances'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search for songs (e.g., "Bohemian Rhapsody")',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey[400]),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey[800],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: _searchSongs,
              onChanged: (value) => setState(() {}),
            ),
          ),

          // Currently Playing
          if (_currentlyPlaying != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.music_note, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Now Playing: $_currentlyPlaying',
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Results List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _searchResults.isEmpty
                    ? Center(
                        child: Text(
                          _isInitialized 
                              ? 'No results found. Try searching for a song!'
                              : 'Initializing...',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final song = _searchResults[index];
                          return Card(
                            color: Colors.grey[800],
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: song.thumbnailUrl.isNotEmpty
                                    ? Image.network(
                                        song.thumbnailUrl,
                                        width: 56,
                                        height: 56,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) =>
                                            Container(
                                              width: 56,
                                              height: 56,
                                              color: Colors.grey[700],
                                              child: const Icon(Icons.music_note, color: Colors.white),
                                            ),
                                      )
                                    : Container(
                                        width: 56,
                                        height: 56,
                                        color: Colors.grey[700],
                                        child: const Icon(Icons.music_note, color: Colors.white),
                                      ),
                              ),
                              title: Text(
                                song.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                song.artists.isNotEmpty 
                                    ? song.artists.map((a) => a.name).join(', ')
                                    : song.artist,
                                style: TextStyle(color: Colors.grey[400]),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.info_outline, color: Colors.blue),
                                    onPressed: () => _showStreamingInfo(song),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.play_arrow, color: Colors.green),
                                    onPressed: () => _playSong(song),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _streamingService.dispose();
    super.dispose();
  }
}

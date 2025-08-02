class JournalEntry {
  final int? id;
  final String title;
  final String content;
  final DateTime createdAt;
  final String? mood;
  final List<String> imagePaths;
  final List<AudioRecording> audioRecordings;

  JournalEntry({
    this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    this.mood,
    required this.imagePaths,
    required this.audioRecordings,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'created_at': createdAt.millisecondsSinceEpoch,
      'mood': mood,
      'image_paths': imagePaths.join('|'), // Store as pipe-separated string
      'audio_recordings': audioRecordings.map((audio) => audio.toJson()).join('|||'), // Store as triple-pipe-separated JSON strings
    };
  }

  factory JournalEntry.fromMap(Map<String, dynamic> map) {
    return JournalEntry(
      id: map['id'],
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      mood: map['mood'],
      imagePaths: map['image_paths'] != null && map['image_paths'].isNotEmpty 
          ? map['image_paths'].split('|') 
          : <String>[],
      audioRecordings: map['audio_recordings'] != null && map['audio_recordings'].isNotEmpty
          ? map['audio_recordings'].split('|||').map<AudioRecording>((audioJson) => AudioRecording.fromJson(audioJson)).toList()
          : <AudioRecording>[],
    );
  }
}

class AudioRecording {
  final String path;
  final Duration duration;
  final DateTime timestamp;

  AudioRecording({
    required this.path,
    required this.duration,
    required this.timestamp,
  });

  String toJson() {
    return '{"path":"$path","duration":${duration.inMilliseconds},"timestamp":${timestamp.millisecondsSinceEpoch}}';
  }

  factory AudioRecording.fromJson(String json) {
    // Simple JSON parsing for our specific format
    final cleanJson = json.replaceAll('{', '').replaceAll('}', '').replaceAll('"', '');
    final parts = cleanJson.split(',');
    
    String path = '';
    int durationMs = 0;
    int timestampMs = 0;
    
    for (String part in parts) {
      final keyValue = part.split(':');
      if (keyValue.length == 2) {
        final key = keyValue[0].trim();
        final value = keyValue[1].trim();
        
        switch (key) {
          case 'path':
            path = value;
            break;
          case 'duration':
            durationMs = int.tryParse(value) ?? 0;
            break;
          case 'timestamp':
            timestampMs = int.tryParse(value) ?? 0;
            break;
        }
      }
    }
    
    return AudioRecording(
      path: path,
      duration: Duration(milliseconds: durationMs),
      timestamp: DateTime.fromMillisecondsSinceEpoch(timestampMs),
    );
  }
}

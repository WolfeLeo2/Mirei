class MoodEntry {
  final int? id;
  final String mood;
  final DateTime createdAt;
  final String? note; // Optional note for the mood

  MoodEntry({
    this.id,
    required this.mood,
    required this.createdAt,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mood': mood,
      'created_at': createdAt.millisecondsSinceEpoch,
      'note': note,
    };
  }

  static MoodEntry fromMap(Map<String, dynamic> map) {
    return MoodEntry(
      id: map['id'],
      mood: map['mood'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      note: map['note'],
    );
  }

  @override
  String toString() {
    return 'MoodEntry{id: $id, mood: $mood, createdAt: $createdAt, note: $note}';
  }
}

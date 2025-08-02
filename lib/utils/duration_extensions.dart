/// Extensions for formatting Duration objects
extension DurationFormatting on Duration {
  /// Format duration as MM:SS or HH:MM:SS
  String get formatted {
    if (inHours > 0) {
      return '${inHours}:${(inMinutes % 60).toString().padLeft(2, '0')}:${(inSeconds % 60).toString().padLeft(2, '0')}';
    } else {
      return '${inMinutes}:${(inSeconds % 60).toString().padLeft(2, '0')}';
    }
  }
}

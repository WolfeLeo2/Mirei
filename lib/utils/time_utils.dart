String formatTime(Duration d) {
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  final min = twoDigits(d.inMinutes.remainder(60));
  final sec = twoDigits(d.inSeconds.remainder(60));
  return '$min:$sec';
}

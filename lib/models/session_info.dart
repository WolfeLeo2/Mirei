class SessionInfo {
  final String greeting;
  final String mainCardText;
  final String time;

  SessionInfo(this.greeting, this.mainCardText, this.time);
}

SessionInfo getSessionInfo() {
  final hour = DateTime.now().hour;
   // Default name

  if (hour >= 5 && hour < 12) {
    return SessionInfo('GOOD MORNING', 'Morning\nAwakening', 'Morning');
  } else if (hour >= 12 && hour < 18) {
    return SessionInfo('GOOD AFTERNOON', 'Mid-day\nClarity', 'Afternoon');
  } else {
    return SessionInfo('WIND DOWN', 'Evening\nDrift', 'Evening');
  }
}

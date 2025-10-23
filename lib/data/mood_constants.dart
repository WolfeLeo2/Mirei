/// Constants for enhanced mood tracking system
class MoodConstants {
  // Existing mood types (keep consistent with current system)
  static const List<String> moodTypes = [
    'Happy',
    'Neutral',
    'Sad',
    'Angry',
  ];

  // Essential triggers for quick selection (reduced and capitalized)
  static const List<String> commonTriggers = [
    'Work',
    'Social interaction',
    'Family',
    'Health',
    'Financial',
    'Relationship',
    'Sleep',
    'Weather',
    'Physical',
    'Loneliness',
    'Time',
    'Other',
  ];

  // Essential activities for quick selection (reduced and capitalized)
  static const List<String> commonActivities = [
    'Exercise',
    'Meditation',
    'Reading',
    'Listening to music',
    'Talking to friends',
    'Walking',
    'Creative work',
    'Cooking',
    'Deep breathing',
    'Yoga',
    'Journaling',
    'Taking a bath',
    'Other',
  ];

  // Essential locations for context (reduced and capitalized)
  static const List<String> commonLocations = [
    'Home',
    'Work',
    'Outdoors',
    'Gym',
    'Commuting',
    'Social gathering',
    'Restaurant',
    'Park',
    'Car',
    'Bed',
    'Other',
  ];

  // Check-in type definitions
  static const List<String> checkInTypes = [
    'morning',
    'afternoon',
    'evening',
    'quick',
    'detailed',
    'simple',
    'manual',
  ];

  // Intensity scale labels for UI
  static const Map<int, String> intensityLabels = {
    1: 'Very Low',
    2: 'Low',
    3: 'Somewhat Low',
    4: 'Below Average',
    5: 'Neutral',
    6: 'Above Average',
    7: 'Good',
    8: 'Very Good',
    9: 'Excellent',
    10: 'Outstanding',
  };

  // Mood categorization for analytics
  static const Map<String, MoodCategory> moodCategories = {
    'Happy': MoodCategory.positive,
    'Neutral': MoodCategory.neutral,
    'Sad': MoodCategory.negative,
    'Angry': MoodCategory.negative,
  };

  // Helper methods
  static bool isPositiveMood(String mood) {
    return moodCategories[mood] == MoodCategory.positive;
  }

  static bool isNegativeMood(String mood) {
    return moodCategories[mood] == MoodCategory.negative;
  }

  static bool isNeutralMood(String mood) {
    return moodCategories[mood] == MoodCategory.neutral;
  }

  static String getIntensityLabel(int intensity) {
    return intensityLabels[intensity] ?? 'Unknown';
  }
}

enum MoodCategory { positive, negative, neutral }

 
import '../models/journal_template.dart';

class JournalTemplates {
  // Mental Wellness Category
  static const mentalWellness = [
    JournalTemplate(
      id: 'anxiety_checkin',
      name: 'Anxiety Check-In',
      emoji: '🧠',
      category: 'Mental Wellness',
      titleTemplate: 'Anxiety Check-In - {date}',
      contentTemplate: _anxietyCheckinTemplate,
      description: 'Structured anxiety self-assessment',
    ),
    JournalTemplate(
      id: 'gratitude_practice',
      name: 'Gratitude Practice',
      emoji: '😌',
      category: 'Mental Wellness',
      titleTemplate: 'Three Good Things - {date}',
      contentTemplate: _gratitudePracticeTemplate,
      description: 'Focus on positive moments',
    ),
  ];

  // Daily Structure Category
  static const dailyStructure = [
    JournalTemplate(
      id: 'morning_intentions',
      name: 'Morning Intentions',
      emoji: '🌅',
      category: 'Daily Structure',
      titleTemplate: 'Morning Intentions - {date}',
      contentTemplate: _morningIntentionsTemplate,
      description: 'Start your day with clarity',
    ),
    JournalTemplate(
      id: 'evening_reflection',
      name: 'Evening Reflection',
      emoji: '🌙',
      category: 'Daily Structure',
      titleTemplate: 'Evening Reflection - {date}',
      contentTemplate: _eveningReflectionTemplate,
      description: 'Reflect on your day',
    ),
  ];

  // Therapeutic Category
  static const therapeutic = [
    JournalTemplate(
      id: 'thought_record',
      name: 'Thought Record',
      emoji: '💭',
      category: 'Therapeutic',
      titleTemplate: 'Thought Record - {date}',
      contentTemplate: _thoughtRecordTemplate,
      description: 'CBT-style thought analysis',
    ),
    JournalTemplate(
      id: 'weekly_goals',
      name: 'Weekly Goals',
      emoji: '🎯',
      category: 'Therapeutic',
      titleTemplate: 'Weekly Goals - Week of {date}',
      contentTemplate: _weeklyGoalsTemplate,
      description: 'Goal setting and progress tracking',
    ),
  ];

  // Template Content Constants
  static const _anxietyCheckinTemplate = '''## Current Anxiety Level: _/10

**What triggered this feeling?**


**Physical sensations I'm noticing:**
- 
- 
- 

**Thoughts going through my mind:**


**Coping strategies I can try:**
- Deep breathing
- 
- 

**One thing I'm grateful for right now:**
''';

  static const _gratitudePracticeTemplate =
      '''## Three things that went well today:

1. **What happened:**
   **Why this was meaningful:**

2. **What happened:**
   **Why this was meaningful:**

3. **What happened:**
   **Why this was meaningful:**

## How do I feel writing this?
''';

  static const _morningIntentionsTemplate = '''## How I'm feeling this morning:


## Today's main priorities:
1.
2.
3. 

## One thing I'm excited about:


## Intention for today:
''';

  static const _eveningReflectionTemplate = '''## How was my day overall? ___/10

**Best moment:**


**Biggest challenge:**


**What I learned:**


**Tomorrow I want to:**


**Mood before sleep:**
''';

  static const _thoughtRecordTemplate = '''## Situation:
What happened? When? Where?


## Mood:
How did I feel? (Rate 1-10)


## Automatic Thoughts:
What went through my mind?


## Evidence For:
What supports this thought?


## Evidence Against:
What doesn't support this thought?


## Balanced Thought:
What's a more realistic perspective?


## New Mood:
How do I feel now? (Rate 1-10)
''';

  static const _weeklyGoalsTemplate = '''## Last week's wins:
- 
- 
- 

## This week's focus:
1. **Main Goal:**
   **Why this matters:**
   **Steps to take:**

2. **Secondary Goal:**
   **Why this matters:**
   **Steps to take:**

## Potential obstacles:


## Support I need:
''';

  // Get all templates organized by category
  static Map<String, List<JournalTemplate>> get categorizedTemplates => {
    'Mental Wellness': mentalWellness,
    'Daily Structure': dailyStructure,
    'Therapeutic': therapeutic,
  };

  // Get all templates as flat list
  static List<JournalTemplate> get allTemplates => [
    ...mentalWellness,
    ...dailyStructure,
    ...therapeutic,
  ];

  // Get template by ID
  static JournalTemplate? getTemplateById(String id) {
    return allTemplates.where((template) => template.id == id).firstOrNull;
  }

  // Get templates by category
  static List<JournalTemplate> getTemplatesByCategory(String category) {
    return categorizedTemplates[category] ?? [];
  }
}

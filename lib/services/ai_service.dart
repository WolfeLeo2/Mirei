import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:convert';

/// Provider-agnostic AI service entrypoint
/// - Uses Gemini via GeminiAiProvider by default
/// - Focused on: journal analysis(ONLY IF ALLOWED), mood insights, coping strategies, mood prediction
class AiService {
  AiService._internal(this._provider);
  static AiService? _instance;

  final AiProvider _provider;

  factory AiService() {
    return _instance ??= AiService._internal(GeminiAiProvider());
  }

  Future<MoodAnalysisResult> analyzeJournal({
    required String journalContent,
    String? currentMood,
    List<String>? recentMoods,
  }) {
    return _provider.analyzeJournal(
      journalContent: journalContent,
      currentMood: currentMood,
      recentMoods: recentMoods,
    );
  }

  Future<String> generateWellnessInsight({
    required List<MoodSample> recentMoodSamples,
    String? context,
  }) {
    return _provider.generateWellnessInsight(
      recentMoodSamples: recentMoodSamples,
      context: context,
    );
  }

  Future<List<ActivitySuggestion>> suggestCopingStrategies({
    required String mood,
    int? intensity,
    String? context,
  }) {
    return _provider.suggestCopingStrategies(
      mood: mood,
      intensity: intensity,
      context: context,
    );
  }

  Future<MoodPrediction> predictNextMood({
    required List<MoodSample> recentMoodSamples,
  }) {
    return _provider.predictNextMood(recentMoodSamples: recentMoodSamples);
  }
}

/// Abstraction so we can swap providers later (e.g., OpenAI, local model)
abstract class AiProvider {
  Future<MoodAnalysisResult> analyzeJournal({
    required String journalContent,
    String? currentMood,
    List<String>? recentMoods,
  });

  Future<String> generateWellnessInsight({
    required List<MoodSample> recentMoodSamples,
    String? context,
  });

  Future<List<ActivitySuggestion>> suggestCopingStrategies({
    required String mood,
    int? intensity,
    String? context,
  });

  Future<MoodPrediction> predictNextMood({
    required List<MoodSample> recentMoodSamples,
  });
}

/// Gemini implementation of AiProvider using official SDK
class GeminiAiProvider implements AiProvider {
  late final GenerativeModel _model;

  GeminiAiProvider() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY missing in .env');
    }

    _model = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 1024,
      ),
    );
  }

  @override
  Future<MoodAnalysisResult> analyzeJournal({
    required String journalContent,
    String? currentMood,
    List<String>? recentMoods,
  }) async {
    debugPrint(
      '📝 AI analyzeJournal: Journal(${journalContent.length}ch), Current($currentMood), Recent($recentMoods)',
    );

    final prompt = _buildJournalAnalysisPrompt(
      journalContent: journalContent,
      currentMood: currentMood,
      recentMoods: recentMoods,
    );

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text ?? '';
      final jsonMap = _safeExtractJson(text);

      return MoodAnalysisResult(
        detectedMood: jsonMap['detectedMood'] ?? currentMood ?? 'neutral',
        confidence: (jsonMap['confidence'] ?? 0.55).toDouble(),
        keyThemes: List<String>.from(jsonMap['keyThemes'] ?? const []),
        triggers: List<String>.from(jsonMap['triggers'] ?? const []),
        recommendedPractices: List<String>.from(
          jsonMap['recommendedPractices'] ?? const [],
        ),
        summary: jsonMap['summary'] ?? 'Journal analyzed successfully.',
      );
    } catch (e) {
      debugPrint('Gemini analyzeJournal failed: $e');
      throw Exception('AI servers could not be contacted. Try again later.');
    }
  }

  @override
  Future<String> generateWellnessInsight({
    required List<MoodSample> recentMoodSamples,
    String? context,
  }) async {
    debugPrint(
      '🧠 AI generateWellnessInsight: ${recentMoodSamples.length} samples, Context($context)',
    );

    final summary = recentMoodSamples
        .map(
          (m) =>
              '${m.mood}(${m.intensity ?? '-'})@${m.timestamp.toIso8601String()}',
        )
        .join(', ');

    final prompt =
        '''
Provide a brief, compassionate wellness insight based on the recent mood trend below.
Be supportive and specific.
Recent moods: $summary
Context: ${context ?? 'N/A'}
''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text?.trim() ?? 'Your wellness insight is ready.';
    } catch (e) {
      debugPrint('Gemini generateWellnessInsight failed: $e');
      throw Exception('AI servers could not be contacted. Try again later.');
    }
  }

  @override
  Future<List<ActivitySuggestion>> suggestCopingStrategies({
    required String mood,
    int? intensity,
    String? context,
  }) async {
    debugPrint(
      '🧘 AI suggestCopingStrategies: Mood($mood), Intensity($intensity), Context($context)',
    );

    final prompt =
        '''
Suggest 4 brief, practical coping activities as JSON for someone feeling "$mood"${intensity != null ? ' (intensity $intensity/10)' : ''}.
Context: ${context ?? 'N/A'}
Return valid JSON:
{
  "suggestions": [
    {"title": "...", "reason": "...", "durationMins": whatever duration is appropriate}
  ]
}
Keep them accessible, safe, and non-judgmental.
''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text ?? '';
      final map = _safeExtractJson(text);
      final list = (map['suggestions'] as List?) ?? const [];
      return list.map((s) {
        return ActivitySuggestion(
          title: s['title'],
          reason: s['reason'],
          durationMins: s['durationMins'] as int,
        );
      }).toList();
    } catch (e) {
      debugPrint('Gemini suggestCopingStrategies failed: $e');
      throw Exception('AI servers could not be contacted. Try again later.');
    }
  }

  @override
  Future<MoodPrediction> predictNextMood({
    required List<MoodSample> recentMoodSamples,
  }) async {
    debugPrint('🔮 AI predictNextMood called:');
    debugPrint('   Mood samples: ${recentMoodSamples.length}');
    if (recentMoodSamples.isNotEmpty) {
      debugPrint(
        '   Latest mood: ${recentMoodSamples.first.mood}(${recentMoodSamples.first.intensity})',
      );
    }

    final recent = recentMoodSamples
        .map(
          (m) => {
            'mood': m.mood,
            'intensity': m.intensity,
            'ts': m.timestamp.toIso8601String(),
            if (m.context != null) 'context': m.context,
          },
        )
        .toList();

    final prompt =
        '''
Given recent mood samples (JSON below), predict the next likely mood within 24 hours.
Return valid JSON: {"predictedMood": "...", "confidence": 0.0-1.0, "reason": "..."}

${jsonEncode(recent)}
''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text ?? '';
      final map = _safeExtractJson(text);
      return MoodPrediction(
        predictedMood: map['predictedMood'] ?? 'neutral',
        confidence: (map['confidence'] ?? 0.5).toDouble(),
        reason: map['reason'] ?? 'Prediction generated from recent trend.',
      );
    } catch (e) {
      debugPrint('Gemini predictNextMood failed: $e');
      throw Exception('AI servers could not be contacted. Try again later.');
    }
  }

  // Helper methods
  Map<String, dynamic> _safeExtractJson(String text) {
    final cleaned = text.replaceAll('```json', '').replaceAll('```', '').trim();
    try {
      final parsed = jsonDecode(cleaned);
      if (parsed is Map<String, dynamic>) return parsed;
      return {};
    } catch (_) {
      return {};
    }
  }

  String _buildJournalAnalysisPrompt({
    required String journalContent,
    String? currentMood,
    List<String>? recentMoods,
  }) {
    final current = currentMood != null ? ' Current mood: $currentMood.' : '';
    final recent = (recentMoods != null && recentMoods.isNotEmpty)
        ? ' Recent moods: ${recentMoods.join(', ')}.'
        : '';

    return '''
Analyze the following personal journal entry with a supportive, non-judgmental tone.
Identify the primary mood, confidence (0-1), 3-5 key themes, potential triggers, and 3 actionable practices.
Return valid JSON:
{
  "detectedMood": "...",
  "confidence": 0.0-1.0,
  "keyThemes": ["..."],
  "triggers": ["..."],
  "recommendedPractices": ["..."],
  "summary": "2-3 sentence compassionate summary"
}

Journal:
"""
$journalContent
"""$current$recent
''';
  }
}

/// Lightweight input type for mood history samples (provider-agnostic)
class MoodSample {
  final String mood;
  final int? intensity; // 1-10
  final DateTime timestamp;
  final String? context; // optional (e.g., work, home)

  const MoodSample({
    required this.mood,
    this.intensity,
    required this.timestamp,
    this.context,
  });
}

/// Journal analysis result
class MoodAnalysisResult {
  final String detectedMood;
  final double confidence;
  final List<String> keyThemes;
  final List<String> triggers;
  final List<String> recommendedPractices;
  final String summary;

  const MoodAnalysisResult({
    required this.detectedMood,
    required this.confidence,
    required this.keyThemes,
    required this.triggers,
    required this.recommendedPractices,
    required this.summary,
  });
}

/// Coping activity suggestion
class ActivitySuggestion {
  final String title;
  final String reason;
  final int durationMins;

  const ActivitySuggestion({
    required this.title,
    required this.reason,
    required this.durationMins,
  });
}

/// Next-mood prediction result
class MoodPrediction {
  final String predictedMood;
  final double confidence;
  final String reason;

  const MoodPrediction({
    required this.predictedMood,
    required this.confidence,
    required this.reason,
  });
}

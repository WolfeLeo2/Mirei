import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/realm_models.dart';
import '../utils/realm_database_helper.dart';
import '../services/enhanced_mood_analytics.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/mood_colors.dart';
import '../services/ai_service.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  _ProgressScreenState createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final EnhancedMoodAnalytics _analytics = EnhancedMoodAnalytics();

  bool isLoading = true;
  DateTime selectedDate = DateTime.now();

  // Analytics data
  IntensityTrend? _intensityTrend;
  Map<String, IntensityStats>? _moodIntensityDistribution;
  Map<String, TriggerAnalysis>? _triggerPatterns;
  Map<String, ActivityImpact>? _activityCorrelation;
  TimeBasedPatterns? _timePatterns;
  JournalMoodCorrelation? _journalCorrelation;
  List<WellnessRecommendation>? _recommendations;
  List<MoodEntryRealm> _recentMoods = [];

  // AI insights state
  final AiService _ai = AiService();
  MoodAnalysisResult? _aiJournalAnalysis;
  String? _aiWellnessInsight;
  List<ActivitySuggestion> _aiCopingSuggestions = const [];
  MoodPrediction? _aiMoodPrediction;

  // AI error states
  String? _aiWellnessError;
  String? _aiCopingError;
  String? _aiPredictionError;

  // AI loading states (for when refreshing cached data)
  bool _isRefreshingWellness = false;
  bool _isRefreshingCoping = false;
  bool _isRefreshingPrediction = false;

  // AI caching state
  String? _cachedMoodDataHash;
  String? _cachedJournalContent;
  DateTime? _lastAiRefresh;

  // Privacy settings
  bool _allowJournalAiAnalysis = false;

  // Original pie chart data
  Map<String, int> moodFrequency = {};
  int totalEntries = 0;
  int touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    debugPrint(
      '🔥 [${DateTime.now().toIso8601String()}] ProgressScreen initState - starting loads',
    );
    _loadPrivacySettings();
    _loadDataSequentially();
  }

  Future<void> _loadPrivacySettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _allowJournalAiAnalysis =
          prefs.getBool('allow_journal_ai_analysis') ?? false;
    });

    // Load cached AI data
    await _loadCachedAiData();
  }

  Future<void> _loadDataSequentially() async {
    // First load analytics data (includes _recentMoods)
    await _loadAllAnalytics();

    // Then load AI insights with populated mood data
    await _loadAiInsights();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllAnalytics() async {
    setState(() => isLoading = true);

    try {
      // Load all analytics data in parallel
      final results = await Future.wait([
        _analytics.getIntensityTrend(days: 30),
        _analytics.getMoodIntensityDistribution(),
        _analytics.getTriggerPatterns(),
        _analytics.getActivityMoodCorrelation(),
        _analytics.getTimeBasedMoodPatterns(),
        _analytics.getJournalMoodCorrelation(),
        _analytics.getPersonalizedRecommendations(),
        _loadRecentMoods(),
      ]);

      setState(() {
        _intensityTrend = results[0] as IntensityTrend;
        _moodIntensityDistribution = results[1] as Map<String, IntensityStats>;
        _triggerPatterns = results[2] as Map<String, TriggerAnalysis>;
        _activityCorrelation = results[3] as Map<String, ActivityImpact>;
        _timePatterns = results[4] as TimeBasedPatterns;
        _journalCorrelation = results[5] as JournalMoodCorrelation;
        _recommendations = results[6] as List<WellnessRecommendation>;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading analytics: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadRecentMoods() async {
    final dbHelper = RealmDatabaseHelper();
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    _recentMoods = await dbHelper.getMoodEntriesForPeriod(
      thirtyDaysAgo,
      DateTime.now(),
    );

    // Calculate frequency for original pie chart (using only latest mood per day)
    final latestMoodPerDay = <String, MoodEntryRealm>{};
    for (final mood in _recentMoods) {
      final dateKey = DateFormat('yyyy-MM-dd').format(mood.createdAt.toLocal());
      // Always overwrite to keep the latest
      latestMoodPerDay[dateKey] = mood;
    }
    final latestMoods = latestMoodPerDay.values.toList();

    final frequency = <String, int>{};
    for (final mood in latestMoods) {
      frequency[mood.mood] = (frequency[mood.mood] ?? 0) + 1;
    }

    moodFrequency = frequency;
    totalEntries = latestMoods.length;
  }

  Future<void> _loadAiInsights() async {
    try {
      // Build recent mood samples for AI
      final samples = _recentMoods
          .take(20)
          .map(
            (m) => MoodSample(
              mood: m.mood,
              intensity: m.intensity,
              timestamp: m.createdAt,
              context: m.context,
            ),
          )
          .toList();

      // Debug: Verify mood data is available for AI
      if (samples.isEmpty) {
        debugPrint(
          '⚠️ No mood samples available for AI - _recentMoods.length=${_recentMoods.length}',
        );
      }

      // Get latest journal content if available (last 1)
      String? latestJournal;
      try {
        final db = RealmDatabaseHelper();
        final start = DateTime.now().subtract(const Duration(days: 30));
        final journals = await db.getJournalEntriesForPeriod(
          start,
          DateTime.now(),
        );
        if (journals.isNotEmpty) {
          latestJournal = journals.first.content;
        }
      } catch (_) {}

      // Create data fingerprint for caching
      final moodDataHash = _createMoodDataHash(samples, latestJournal);

      // Check if we need to refresh AI insights
      final shouldRefresh = _shouldRefreshAiInsights(
        moodDataHash,
        latestJournal,
      );

      if (!shouldRefresh) {
        debugPrint('🎯 AI insights cached - skipping refresh');
        return;
      }

      debugPrint('🔄 Refreshing AI insights - data changed');

      // Clear any previous errors and set loading states
      setState(() {
        _aiWellnessError = null;
        _aiCopingError = null;
        _aiPredictionError = null;
        _isRefreshingWellness = true;
        _isRefreshingCoping = true;
        _isRefreshingPrediction = true;
      });

      // Journal analysis (only if privacy enabled)
      MoodAnalysisResult? analysis;
      if (latestJournal != null && _allowJournalAiAnalysis) {
        try {
          analysis = await _ai.analyzeJournal(
            journalContent: latestJournal,
            currentMood: _recentMoods.isNotEmpty
                ? _recentMoods.first.mood
                : null,
            recentMoods: _recentMoods.take(5).map((m) => m.mood).toList(),
          );
        } catch (e) {
          debugPrint('Journal analysis failed: $e');
          // Journal analysis errors are handled silently (privacy feature)
        }
      }

      // Wellness insight
      String? insight;
      try {
        insight = await _ai.generateWellnessInsight(
          recentMoodSamples: samples,
          context: _recentMoods.isNotEmpty ? _recentMoods.first.context : null,
        );
      } catch (e) {
        debugPrint('Wellness insight failed: $e');
        _aiWellnessError = e.toString().replaceFirst('Exception: ', '');
      } finally {
        _isRefreshingWellness = false;
      }

      // Coping strategies
      List<ActivitySuggestion> strategies = [];
      try {
        strategies = await _ai.suggestCopingStrategies(
          mood: _recentMoods.isNotEmpty ? _recentMoods.first.mood : 'neutral',
          intensity: _recentMoods.isNotEmpty
              ? _recentMoods.first.intensity
              : null,
          context: _recentMoods.isNotEmpty ? _recentMoods.first.context : null,
        );
      } catch (e) {
        debugPrint('Coping strategies failed: $e');
        _aiCopingError = e.toString().replaceFirst('Exception: ', '');
      } finally {
        _isRefreshingCoping = false;
      }

      // Mood prediction
      MoodPrediction? prediction;
      try {
        prediction = await _ai.predictNextMood(recentMoodSamples: samples);
      } catch (e) {
        debugPrint('Mood prediction failed: $e');
        _aiPredictionError = e.toString().replaceFirst('Exception: ', '');
      } finally {
        _isRefreshingPrediction = false;
      }

      if (!mounted) return;
      setState(() {
        _aiJournalAnalysis = analysis;
        _aiWellnessInsight = insight;
        _aiCopingSuggestions = strategies;
        _aiMoodPrediction = prediction;

        // Update cache state
        _cachedMoodDataHash = moodDataHash;
        _cachedJournalContent = latestJournal;
        _lastAiRefresh = DateTime.now();
      });

      // Save to persistent cache only if we have successful results
      if (insight != null || strategies.isNotEmpty || prediction != null) {
        await _saveCachedAiData();
      }
    } catch (e) {
      debugPrint('AI insights failed: $e');
    }
  }

  /// Create a hash of mood data for caching comparison
  String _createMoodDataHash(List<MoodSample> samples, String? journalContent) {
    final moodData = samples
        .map(
          (s) =>
              '${s.mood}-${s.intensity}-${s.timestamp.millisecondsSinceEpoch}',
        )
        .join(',');
    final journalHash = journalContent?.hashCode.toString() ?? 'no-journal';
    return '$moodData-$journalHash';
  }

  /// Check if AI insights should be refreshed based on data changes
  bool _shouldRefreshAiInsights(String currentHash, String? currentJournal) {
    // Always refresh on first load
    if (_cachedMoodDataHash == null) return true;

    // Refresh if data has changed
    if (_cachedMoodDataHash != currentHash) return true;

    // Refresh if journal content has changed
    if (_cachedJournalContent != currentJournal) return true;

    // Refresh if it's been more than 1 hour (to handle edge cases)
    if (_lastAiRefresh != null) {
      final hoursSinceLastRefresh = DateTime.now()
          .difference(_lastAiRefresh!)
          .inHours;
      if (hoursSinceLastRefresh >= 1) return true;
    }

    // Otherwise, use cached data
    return false;
  }

  /// Load cached AI data from persistent storage
  Future<void> _loadCachedAiData() async {
    final prefs = await SharedPreferences.getInstance();

    // Load cache metadata
    _cachedMoodDataHash = prefs.getString('ai_cache_mood_hash');
    _cachedJournalContent = prefs.getString('ai_cache_journal_content');
    final lastRefreshMs = prefs.getInt('ai_cache_last_refresh');
    if (lastRefreshMs != null) {
      _lastAiRefresh = DateTime.fromMillisecondsSinceEpoch(lastRefreshMs);
    }

    // Load cached AI results if still valid (within 1 hour)
    if (_lastAiRefresh != null) {
      final hoursSinceRefresh = DateTime.now()
          .difference(_lastAiRefresh!)
          .inHours;
      if (hoursSinceRefresh < 1) {
        // Load cached wellness insight
        final cachedWellnessInsight = prefs.getString(
          'ai_cache_wellness_insight',
        );
        _aiWellnessInsight = cachedWellnessInsight;

        // Load cached mood prediction
        final cachedPredictedMood = prefs.getString('ai_cache_predicted_mood');
        final cachedConfidence = prefs.getDouble('ai_cache_confidence');
        final cachedPredictionReason = prefs.getString(
          'ai_cache_prediction_reason',
        );
        if (cachedPredictedMood != null &&
            cachedConfidence != null &&
            cachedPredictionReason != null) {
          _aiMoodPrediction = MoodPrediction(
            predictedMood: cachedPredictedMood,
            confidence: cachedConfidence,
            reason: cachedPredictionReason,
          );
        }

        // Load cached coping strategies
        final cachedStrategiesCount =
            prefs.getInt('ai_cache_strategies_count') ?? 0;
        final strategies = <ActivitySuggestion>[];
        for (int i = 0; i < cachedStrategiesCount; i++) {
          final title = prefs.getString('ai_cache_strategy_${i}_title');
          final reason = prefs.getString('ai_cache_strategy_${i}_reason');
          final duration = prefs.getInt('ai_cache_strategy_${i}_duration');
          if (title != null && reason != null && duration != null) {
            strategies.add(
              ActivitySuggestion(
                title: title,
                reason: reason,
                durationMins: duration,
              ),
            );
          }
        }
        _aiCopingSuggestions = strategies;

        debugPrint(
          '🎯 Loaded cached AI insights from storage (${strategies.length} strategies, prediction: ${cachedPredictedMood ?? 'none'})',
        );
      }
    }
  }

  /// Save AI data to persistent cache
  Future<void> _saveCachedAiData() async {
    final prefs = await SharedPreferences.getInstance();

    // Save cache metadata
    if (_cachedMoodDataHash != null) {
      await prefs.setString('ai_cache_mood_hash', _cachedMoodDataHash!);
    }
    if (_cachedJournalContent != null) {
      await prefs.setString('ai_cache_journal_content', _cachedJournalContent!);
    }
    if (_lastAiRefresh != null) {
      await prefs.setInt(
        'ai_cache_last_refresh',
        _lastAiRefresh!.millisecondsSinceEpoch,
      );
    }

    // Save AI results
    if (_aiWellnessInsight != null) {
      await prefs.setString('ai_cache_wellness_insight', _aiWellnessInsight!);
    }

    // Save mood prediction
    if (_aiMoodPrediction != null) {
      await prefs.setString(
        'ai_cache_predicted_mood',
        _aiMoodPrediction!.predictedMood,
      );
      await prefs.setDouble(
        'ai_cache_confidence',
        _aiMoodPrediction!.confidence,
      );
      await prefs.setString(
        'ai_cache_prediction_reason',
        _aiMoodPrediction!.reason,
      );
    }

    // Save coping strategies
    await prefs.setInt(
      'ai_cache_strategies_count',
      _aiCopingSuggestions.length,
    );
    for (int i = 0; i < _aiCopingSuggestions.length; i++) {
      final strategy = _aiCopingSuggestions[i];
      await prefs.setString('ai_cache_strategy_${i}_title', strategy.title);
      await prefs.setString('ai_cache_strategy_${i}_reason', strategy.reason);
      await prefs.setInt(
        'ai_cache_strategy_${i}_duration',
        strategy.durationMins,
      );
    }
  }

  /// Show privacy dialog for journal AI analysis
  void _showJournalPrivacyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.privacy_tip, color: Colors.blue[700]),
            const SizedBox(width: 8),
            const Text('Journal Privacy'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Journal AI Analysis',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'When enabled, AI will analyze your journal entries to provide:\n\n'
              '• Key themes and insights\n'
              '• Emotional patterns\n'
              '• Personalized recommendations\n\n'
              'Your journal content will be processed by Google Gemini AI. '
              'This is optional and can be disabled anytime.',
              style: GoogleFonts.inter(fontSize: 14, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Disabled'),
          ),
          ElevatedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('allow_journal_ai_analysis', true);
              setState(() {
                _allowJournalAiAnalysis = true;
              });
              Navigator.pop(context);
              // Refresh AI insights with journal analysis enabled
              _loadAiInsights();
            },
            child: const Text('Enable AI Analysis'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFfaf6f1),
      appBar: AppBar(
        backgroundColor: const Color(0xFF115e5a),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: AppColors.surface,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Mood Analytics',
          style: GoogleFonts.inter(
            color: AppColors.surface,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Patterns'),
            Tab(text: 'Timeline'),
            Tab(text: 'Insights'),
          ],
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF115e5a)),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildPatternsTab(),
                _buildTimelineTab(),
                _buildInsightsTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick stats cards
          _buildQuickStatsRow(),
          const SizedBox(height: 24),

          // Intensity trend chart
          _buildIntensityTrendCard(),
          const SizedBox(height: 24),

          // Mood distribution chart
          _buildMoodDistributionCard(),
          const SizedBox(height: 24),

          // Recent activity summary
          _buildRecentActivityCard(),
        ],
      ),
    );
  }

  Widget _buildPatternsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top triggers
          _buildTriggersAnalysisCard(),
          const SizedBox(height: 24),

          // Activity impact
          _buildActivitiesAnalysisCard(),
          const SizedBox(height: 24),

          // Time patterns
          _buildTimeBasedPatternsCard(),
          const SizedBox(height: 24),

          // Journal correlation
          _buildJournalCorrelationCard(),
        ],
      ),
    );
  }

  Widget _buildTimelineTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month selector
          _buildMonthSelector(),
          const SizedBox(height: 24),

          // Mood timeline
          _buildMoodTimelineCard(),
          const SizedBox(height: 24),

          // Daily entries with timestamps
          _buildDailyEntriesCard(),
          const SizedBox(height: 24),

          // Weekly summary
          _buildWeeklySummaryCard(),
        ],
      ),
    );
  }

  Widget _buildInsightsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Personalized insights header
          _buildInsightsHeader(),
          const SizedBox(height: 24),

          // AI Insights
          _buildAiInsightsSection(),
          const SizedBox(height: 24),

          // Recommendations (non-AI)
          _buildRecommendationsSection(),
          const SizedBox(height: 24),

          // Progress summary
          _buildProgressSummaryCard(),
        ],
      ),
    );
  }

  Widget _buildQuickStatsRow() {
    final totalEntries = _recentMoods.length;
    final avgIntensity = _intensityTrend?.averageIntensity ?? 0;
    final streakDays = _calculateCurrentStreak();

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Total Entries',
            value: '$totalEntries',
            subtitle: 'Last 30 days',
            icon: Icons.timeline,
            color: const Color(0xFF115e5a),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: 'Avg Intensity',
            value: '${avgIntensity.toStringAsFixed(1)}/10',
            subtitle: 'General mood ${_getTrendText(_intensityTrend?.trend)}',
            icon: Icons.trending_up,
            color: _getTrendColor(_intensityTrend?.trend),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: 'Streak',
            value: '$streakDays',
            subtitle: 'days',
            icon: Icons.local_fire_department,
            color: streakDays > 7 ? Colors.orange : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.trending_up, color: color, size: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          Text(
            subtitle,
            style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildIntensityTrendCard() {
    if (_intensityTrend == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Intensity Trend',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getTrendColor(
                    _intensityTrend!.trend,
                  ).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getTrendText(_intensityTrend!.trend),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getTrendColor(_intensityTrend!.trend),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Intensity visualization
          Container(height: 200, child: _buildIntensityChart()),

          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildIntensityMetric(
                'Average',
                '${_intensityTrend!.averageIntensity.toStringAsFixed(1)}/10',
                Colors.blue,
              ),
              _buildIntensityMetric(
                'Change',
                '${_intensityTrend!.intensityChange > 0 ? '+' : ''}${_intensityTrend!.intensityChange.toStringAsFixed(2)}',
                _getTrendColor(_intensityTrend!.trend),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMoodDistributionCard() {
    if (_moodIntensityDistribution == null ||
        _moodIntensityDistribution!.isEmpty) {
      return const SizedBox();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mood Distribution',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Last 30 days',
            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 20),

          // Pie chart
          Container(height: 200, child: _buildMoodPieChart()),

          const SizedBox(height: 16),
          // Mood legend
          _buildMoodLegend(),
        ],
      ),
    );
  }

  Widget _buildRecentActivityCard() {
    // Show recent mood entries with timestamps
    final recentMoodsWithTime = _recentMoods.take(5).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Mood Entries',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          if (recentMoodsWithTime.isEmpty)
            Center(
              child: Text(
                'No recent mood entries',
                style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
              ),
            )
          else
            ...recentMoodsWithTime.map((mood) => _buildRecentMoodItem(mood)),
        ],
      ),
    );
  }

  Widget _buildTriggersAnalysisCard() {
    final topTriggers = _triggerPatterns?.entries
        .where((e) => !e.value.isPositiveTrigger)
        .toList();
    topTriggers?.sort(
      (a, b) => b.value.occurrences.compareTo(a.value.occurrences),
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
              const SizedBox(width: 8),
              Text(
                'Common Triggers',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (topTriggers?.isEmpty ?? true)
            Center(
              child: Text(
                'No trigger patterns identified yet',
                style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
              ),
            )
          else
            ...topTriggers!
                .take(5)
                .map((entry) => _buildTriggerItem(entry.value)),
        ],
      ),
    );
  }

  Widget _buildActivitiesAnalysisCard() {
    final topActivities = _activityCorrelation?.entries
        .where((e) => e.value.isPositiveActivity)
        .toList();
    topActivities?.sort(
      (a, b) => b.value.averageMoodScore.compareTo(a.value.averageMoodScore),
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.favorite, color: AppColors.success, size: 24),
              const SizedBox(width: 8),
              Text(
                'Mood Boosting Activities',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (topActivities?.isEmpty ?? true)
            Center(
              child: Text(
                'No positive activity patterns yet',
                style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
              ),
            )
          else
            ...topActivities!
                .take(5)
                .map((entry) => _buildActivityAnalysisItem(entry.value)),
        ],
      ),
    );
  }

  Widget _buildTimeBasedPatternsCard() {
    if (_timePatterns == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.access_time, color: Colors.purple, size: 24),
              const SizedBox(width: 8),
              Text(
                'Time Patterns',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Time of day comparison
          _buildTimeOfDayChart(),
          const SizedBox(height: 16),

          // Best times
          Row(
            children: [
              Expanded(
                child: _buildTimeMetric(
                  'Best Time',
                  _timePatterns!.bestTimeOfDay,
                  Icons.wb_sunny,
                  Colors.amber,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTimeMetric(
                  'Best Days',
                  _timePatterns!.bestDayType,
                  Icons.calendar_today,
                  Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildJournalCorrelationCard() {
    if (_journalCorrelation == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.book, color: Colors.indigo, size: 24),
              const SizedBox(width: 8),
              Text(
                'Journal Insights',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_journalCorrelation!.mostProductiveMood.isNotEmpty) ...[
            _buildJournalMetric(
              'Most Productive Mood',
              _journalCorrelation!.mostProductiveMood,
              'You write longer entries when feeling this way',
            ),
            const SizedBox(height: 12),
          ],

          _buildJournalMetric(
            'Writing Mood Average',
            '${_journalCorrelation!.averageWritingMood.toStringAsFixed(1)}/10',
            'Your typical mood when journaling',
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF115e5a),
            const Color(0xFF115e5a).withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology, color: AppColors.surface, size: 28),
              const SizedBox(width: 12),
              Text(
                'Personal Insights',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.surface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'AI-powered recommendations based on your mood patterns',
            style: GoogleFonts.inter(fontSize: 14, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsSection() {
    if (_recommendations?.isEmpty ?? true) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.lightbulb_outline, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(
                'Keep tracking your mood',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'More insights will appear as you log more entries',
                style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _recommendations!
          .map((rec) => _buildRecommendationCard(rec))
          .toList(),
    );
  }

  Widget _buildRecommendationCard(WellnessRecommendation recommendation) {
    final priorityColor = recommendation.priority == RecommendationPriority.high
        ? Colors.red
        : recommendation.priority == RecommendationPriority.medium
        ? Colors.orange
        : AppColors.success;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: priorityColor, width: 4)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getRecommendationIcon(recommendation.type),
                  color: priorityColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  recommendation.title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  recommendation.priority.name.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: priorityColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            recommendation.message,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
          if (recommendation.actionSuggestions.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...recommendation.actionSuggestions.map(
              (action) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(Icons.arrow_right, color: priorityColor, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        action,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Helper methods for UI components
  String _getTrendText(TrendDirection? trend) {
    switch (trend) {
      case TrendDirection.improving:
        return 'Improving';
      case TrendDirection.declining:
        return 'Declining';
      case TrendDirection.stable:
        return 'Stable';
      case TrendDirection.insufficient:
        return 'Need more data';
      default:
        return 'Unknown';
    }
  }

  Color _getTrendColor(TrendDirection? trend) {
    switch (trend) {
      case TrendDirection.improving:
        return AppColors.success;
      case TrendDirection.declining:
        return Colors.red;
      case TrendDirection.stable:
        return Colors.blue;
      case TrendDirection.insufficient:
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  int _calculateCurrentStreak() {
    if (_recentMoods.isEmpty) return 0;

    final sortedMoods = _recentMoods.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    int streak = 0;
    final today = DateTime.now();

    for (int i = 0; i < 30; i++) {
      final checkDate = today.subtract(Duration(days: i));
      final hasEntryForDay = sortedMoods.any(
        (mood) =>
            DateFormat('yyyy-MM-dd').format(mood.createdAt) ==
            DateFormat('yyyy-MM-dd').format(checkDate),
      );

      if (hasEntryForDay) {
        streak++;
      } else {
        break;
      }
    }

    return streak;
  }

  IconData _getRecommendationIcon(RecommendationType type) {
    switch (type) {
      case RecommendationType.intensity:
        return Icons.trending_up;
      case RecommendationType.trigger:
        return Icons.warning_amber;
      case RecommendationType.activity:
        return Icons.fitness_center;
      case RecommendationType.timing:
        return Icons.schedule;
      case RecommendationType.journaling:
        return Icons.book;
    }
  }

  // Chart building methods
  Widget _buildIntensityChart() {
    // Implementation for intensity trend line chart
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: _getIntensitySpots(),
            isCurved: true,
            color: const Color(0xFF115e5a),
            barWidth: 3,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF115e5a).withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodPieChart() {
    return PieChart(
      PieChartData(
        pieTouchData: PieTouchData(
          touchCallback: (FlTouchEvent event, pieTouchResponse) {
            setState(() {
              if (!event.isInterestedForInteractions ||
                  pieTouchResponse == null ||
                  pieTouchResponse.touchedSection == null) {
                touchedIndex = -1;
                return;
              }
              touchedIndex =
                  pieTouchResponse.touchedSection!.touchedSectionIndex;
            });
          },
        ),
        borderData: FlBorderData(show: false),
        sectionsSpace: 2,
        centerSpaceRadius: 0,
        sections: _buildOriginalPieChartSections(),
      ),
    );
  }

  Widget _buildTimeOfDayChart() {
    if (_timePatterns == null) return const SizedBox();

    return Container(
      height: 150,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 10,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final labels = ['Morning', 'Afternoon', 'Evening'];
                  if (value.toInt() >= 0 && value.toInt() < labels.length) {
                    return Text(
                      labels[value.toInt()],
                      style: GoogleFonts.inter(fontSize: 10),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          barGroups: [
            BarChartGroupData(
              x: 0,
              barRods: [
                BarChartRodData(
                  toY: _timePatterns!.morningAverage,
                  color: Colors.orange,
                  width: 20,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
            BarChartGroupData(
              x: 1,
              barRods: [
                BarChartRodData(
                  toY: _timePatterns!.afternoonAverage,
                  color: Colors.blue,
                  width: 20,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
            BarChartGroupData(
              x: 2,
              barRods: [
                BarChartRodData(
                  toY: _timePatterns!.eveningAverage,
                  color: Colors.purple,
                  width: 20,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Data processing methods
  List<FlSpot> _getIntensitySpots() {
    if (_recentMoods.isEmpty) return [];

    final moodsWithIntensity =
        _recentMoods.where((m) => m.intensity != null).toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    return moodsWithIntensity
        .asMap()
        .entries
        .map(
          (entry) =>
              FlSpot(entry.key.toDouble(), entry.value.intensity!.toDouble()),
        )
        .toList();
  }

  List<PieChartSectionData> _buildOriginalPieChartSections() {
    if (moodFrequency.isEmpty) return [];

    final sortedMoods = moodFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedMoods.asMap().entries.map((entry) {
      final index = entry.key;
      final moodEntry = entry.value;
      final isTouched = index == touchedIndex;
      final fontSize = isTouched ? 16.0 : 14.0;
      final radius = isTouched ? 120.0 : 100.0;
      final widgetSize = isTouched ? 50.0 : 40.0;

      final percentage = totalEntries > 0
          ? (moodEntry.value / totalEntries * 100).round()
          : 0;
      final moodExt = Theme.of(context).extension<MoodColors>();
      final color =
          moodExt?.byMood(moodEntry.key) ??
          AppColors.getEmotionColor(moodEntry.key);

      return PieChartSectionData(
        color: color,
        value: moodEntry.value.toDouble(),
        title: '$percentage%',
        radius: radius,
        titleStyle: GoogleFonts.inter(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: AppColors.surface,
          shadows: const [Shadow(color: Colors.black26, blurRadius: 2)],
        ),
        badgeWidget: _MoodBadge(
          mood: moodEntry.key,
          size: widgetSize,
          borderColor: color,
        ),
        badgePositionPercentageOffset: 0.98,
      );
    }).toList();
  }

  // Additional helper widgets
  Widget _buildIntensityMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildMoodLegend() {
    if (moodFrequency.isEmpty) return const SizedBox();

    final sortedMoods = moodFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: sortedMoods.map((entry) {
        final percentage = totalEntries > 0
            ? (entry.value / totalEntries * 100).round()
            : 0;
        final moodExt = Theme.of(context).extension<MoodColors>();
        final color =
            moodExt?.byMood(entry.key) ?? AppColors.getEmotionColor(entry.key);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  entry.key,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF115e5a),
                  ),
                ),
              ),
              Text(
                '$percentage% (${entry.value})',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecentMoodItem(MoodEntryRealm mood) {
    final timeAgo = _getTimeAgo(mood.createdAt);
    final exactTime = DateFormat('h:mm a').format(mood.createdAt.toLocal());
    final timeOfDay = mood.checkInType ?? 'unknown';
    final color =
        Theme.of(context).extension<MoodColors>()?.byMood(mood.mood) ??
        AppColors.getEmotionColor(mood.mood);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      mood.mood,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    if (mood.intensity != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${mood.intensity}/10',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 12, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      '$exactTime • $timeOfDay',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeAgo,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.grey[500],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(ActivityImpact activity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.favorite, color: AppColors.success, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.activityName,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  '${activity.occurrences} times • Avg intensity: ${activity.averageIntensity.toStringAsFixed(1)}/10',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '+${activity.moodImprovement.toStringAsFixed(1)}',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.surface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTriggerItem(TriggerAnalysis trigger) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber, color: Colors.orange, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trigger.triggerName,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  '${trigger.occurrences} times • Most common: ${trigger.mostCommonMood}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${trigger.averageIntensity.toStringAsFixed(1)}/10',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.surface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityAnalysisItem(ActivityImpact activity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.trending_up, color: AppColors.success, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.activityName,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${activity.occurrences} sessions',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+${activity.moodImprovement.toStringAsFixed(1)}',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
              Text(
                'mood boost',
                style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeMetric(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildJournalMetric(String label, String value, String description) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.indigo.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.indigo.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.edit, color: Colors.indigo, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    final now = DateTime.now();
    final isCurrentMonth =
        selectedDate.year == now.year && selectedDate.month == now.month;
    final canGoNext = selectedDate.isBefore(DateTime(now.year, now.month, 1));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: _navigateToPreviousMonth,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.chevron_left,
                color: Colors.grey[600],
                size: 24,
              ),
            ),
          ),
          Column(
            children: [
              Text(
                DateFormat('MMMM yyyy').format(selectedDate),
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              if (isCurrentMonth)
                Text(
                  'Current Month',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF115e5a),
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          GestureDetector(
            onTap: canGoNext ? _navigateToNextMonth : null,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: canGoNext ? Colors.grey[100] : Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.chevron_right,
                color: canGoNext ? Colors.grey[600] : Colors.grey[300],
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodTimelineCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mood Timeline',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Container(height: 200, child: _buildTimelineChart()),
        ],
      ),
    );
  }

  Widget _buildDailyEntriesCard() {
    // Show detailed daily entries with exact timestamps for selected month
    final monthMoods = _recentMoods.where((mood) {
      final moodDate = mood.createdAt;
      return moodDate.year == selectedDate.year &&
          moodDate.month == selectedDate.month;
    }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.schedule, color: Colors.indigo, size: 24),
              const SizedBox(width: 8),
              Text(
                'Daily Entries',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Showing exact timestamps for ${DateFormat('MMMM yyyy').format(selectedDate)}',
            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),

          if (monthMoods.isEmpty)
            Center(
              child: Text(
                'No mood entries for this month',
                style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
              ),
            )
          else
            Container(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: monthMoods.length,
                itemBuilder: (context, index) =>
                    _buildDetailedMoodEntry(monthMoods[index]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWeeklySummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weekly Summary',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildWeeklyBars(),
        ],
      ),
    );
  }

  Widget _buildProgressSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events, color: Colors.amber, size: 24),
              const SizedBox(width: 8),
              Text(
                'Your Progress',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildProgressMetric(
            'Tracking Streak',
            '${_calculateCurrentStreak()} days',
            Icons.local_fire_department,
            Colors.orange,
          ),
          const SizedBox(height: 12),

          _buildProgressMetric(
            'Total Check-ins',
            '${_recentMoods.length}',
            Icons.check_circle,
            AppColors.success,
          ),
          const SizedBox(height: 12),

          if (_intensityTrend != null)
            _buildProgressMetric(
              'Mood Trend',
              _getTrendText(_intensityTrend!.trend),
              Icons.trending_up,
              _getTrendColor(_intensityTrend!.trend),
            ),
        ],
      ),
    );
  }

  Widget _buildProgressMetric(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[700]),
              ),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineChart() {
    if (_recentMoods.isEmpty) {
      return Center(
        child: Text(
          'No mood data available',
          style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
        ),
      );
    }

    // Group moods by day for the selected month
    final monthMoods = _recentMoods.where((mood) {
      final moodDate = mood.createdAt;
      return moodDate.year == selectedDate.year &&
          moodDate.month == selectedDate.month;
    }).toList();

    if (monthMoods.isEmpty) {
      return Center(
        child: Text(
          'No mood data for ${DateFormat('MMMM yyyy').format(selectedDate)}',
          style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
        ),
      );
    }

    // Create timeline spots
    final spots = <FlSpot>[];
    final groupedByDay = <int, List<MoodEntryRealm>>{};

    for (final mood in monthMoods) {
      final day = mood.createdAt.day;
      groupedByDay.putIfAbsent(day, () => []).add(mood);
    }

    // Calculate average intensity per day
    groupedByDay.forEach((day, moods) {
      final intensities = moods
          .where((m) => m.intensity != null)
          .map((m) => m.intensity!.toDouble())
          .toList();

      if (intensities.isNotEmpty) {
        final avgIntensity =
            intensities.reduce((a, b) => a + b) / intensities.length;
        spots.add(FlSpot(day.toDouble(), avgIntensity));
      }
    });

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 2,
          getDrawingHorizontalLine: (value) {
            return FlLine(color: Colors.grey[300]!, strokeWidth: 1);
          },
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                if (value % 2 == 0) {
                  return Text(
                    value.toInt().toString(),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 25,
              interval: 5,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                );
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minX: 1,
        maxX: DateTime(
          selectedDate.year,
          selectedDate.month + 1,
          0,
        ).day.toDouble(),
        minY: 1,
        maxY: 10,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: const Color(0xFF115e5a),
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: const Color(0xFF115e5a),
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF115e5a).withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyBars() {
    if (_recentMoods.isEmpty) {
      return Center(
        child: Text(
          'No mood data available',
          style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
        ),
      );
    }

    // Group by week and calculate averages
    final weeklyData = <String, double>{};
    final weeklyIntensities = <String, List<double>>{};

    for (final mood in _recentMoods) {
      if (mood.intensity != null) {
        final weekStart = _getWeekStart(mood.createdAt);
        final weekKey = DateFormat('MMM dd').format(weekStart);

        weeklyIntensities
            .putIfAbsent(weekKey, () => [])
            .add(mood.intensity!.toDouble());
      }
    }

    weeklyIntensities.forEach((week, intensities) {
      weeklyData[week] =
          intensities.reduce((a, b) => a + b) / intensities.length;
    });

    final sortedWeeks = weeklyData.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Column(
      children: sortedWeeks.take(4).map((entry) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              SizedBox(
                width: 60,
                child: Text(
                  entry.key,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: entry.value / 10,
                    child: Container(
                      decoration: BoxDecoration(
                        color: _getIntensityColor(entry.value),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${entry.value.toStringAsFixed(1)}/10',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday;
    return date.subtract(Duration(days: weekday - 1));
  }

  Color _getIntensityColor(double intensity) {
    if (intensity >= 8) return AppColors.success;
    if (intensity >= 6) return Colors.lightGreen;
    if (intensity >= 4) return Colors.orange;
    return Colors.red;
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildDetailedMoodEntry(MoodEntryRealm mood) {
    final color =
        Theme.of(context).extension<MoodColors>()?.byMood(mood.mood) ??
        AppColors.getEmotionColor(mood.mood);
    final exactTime = DateFormat(
      'MMM dd, h:mm a',
    ).format(mood.createdAt.toLocal());
    final sequenceNumber = mood.sequenceNumber ?? 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          // Time indicator
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      mood.mood,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    if (mood.intensity != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${mood.intensity}/10',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (sequenceNumber > 1)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '#$sequenceNumber',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 12, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      exactTime,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
                if (mood.context != null && mood.context!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    mood.context!,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToPreviousMonth() {
    setState(() {
      selectedDate = DateTime(selectedDate.year, selectedDate.month - 1, 1);
      isLoading = true;
    });
    _loadAllAnalytics();
    // AI insights will be cached and only refresh if mood data changed
    _loadAiInsights();
  }

  void _navigateToNextMonth() {
    final now = DateTime.now();
    if (selectedDate.isBefore(DateTime(now.year, now.month, 1))) {
      setState(() {
        selectedDate = DateTime(selectedDate.year, selectedDate.month + 1, 1);
        isLoading = true;
      });
      _loadAllAnalytics();
      // AI insights will be cached and only refresh if mood data changed
      _loadAiInsights();
    }
  }

  // --- AI Insights UI ---
  Widget _buildAiInsightsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAiInsightCard(),
        const SizedBox(height: 16),
        _buildAiCopingSuggestions(),
        const SizedBox(height: 16),
        _buildAiPredictionCard(),
      ],
    );
  }

  Widget _buildAiInsightCard() {
    final hasInsight = _aiWellnessInsight != null;
    final hasError = _aiWellnessError != null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF115e5a).withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with status indicator
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF115e5a).withValues(alpha: 0.1),
                      const Color(0xFF115e5a).withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  hasInsight ? Icons.auto_awesome : Icons.hourglass_empty,
                  color: const Color(0xFF115e5a),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Wellness Insight',
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    if (hasError)
                      Text(
                        'Connection failed',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.red[600],
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    else if (!hasInsight)
                      Text(
                        'Analyzing your mood patterns...',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
              if (_isRefreshingWellness)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          valueColor: AlwaysStoppedAnimation(Colors.blue[700]),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Updating...',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                )
              else if (hasInsight)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 12,
                        color: Colors.green[700],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Fresh',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Content
          if (hasError)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withValues(alpha: 0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red[700],
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Connection Error',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.red[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _aiWellnessError!,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.red[600],
                    ),
                  ),
                ],
              ),
            )
          else if (!hasInsight)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.grey[600]),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Generating personalized insights...',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey[700],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF115e5a).withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF115e5a).withValues(alpha: 0.08),
                ),
              ),
              child: Text(
                _aiWellnessInsight!,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  height: 1.6,
                  color: Colors.black87,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          if (_aiJournalAnalysis != null) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _aiJournalAnalysis!.keyThemes
                  .take(4)
                  .map(
                    (t) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF115e5a).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        t,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF115e5a),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],

          // Privacy notice for journal analysis
          if (!_allowJournalAiAnalysis) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.privacy_tip_outlined,
                        size: 16,
                        color: Colors.blue[700],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Journal Privacy Protection',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Journal AI analysis is disabled for privacy. Enable to get personalized themes from your journal entries.',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.blue[600],
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _showJournalPrivacyDialog,
                    child: Text(
                      'Review Privacy Settings →',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[700],
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAiCopingSuggestions() {
    final hasStrategies = _aiCopingSuggestions.isNotEmpty;
    final hasError = _aiCopingError != null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with status
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.orange.withValues(alpha: 0.15),
                      Colors.orange.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Coping Strategies',
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      hasError
                          ? 'Connection failed'
                          : _isRefreshingCoping
                          ? 'Updating strategies...'
                          : hasStrategies
                          ? '${_aiCopingSuggestions.length} personalized suggestions'
                          : 'Generating strategies...',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: hasError
                            ? Colors.red[600]
                            : _isRefreshingCoping
                            ? Colors.blue[600]
                            : Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Content
          if (hasError)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withValues(alpha: 0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red[700],
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Connection Error',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.red[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _aiCopingError!,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.red[600],
                    ),
                  ),
                ],
              ),
            )
          else if (!hasStrategies)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.grey[600]),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Generating coping strategies...',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey[700],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: _aiCopingSuggestions.asMap().entries.map((entry) {
                final index = entry.key;
                final s = entry.value;
                return Container(
                  margin: EdgeInsets.only(
                    bottom: index < _aiCopingSuggestions.length - 1 ? 12 : 0,
                  ),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.1),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.orange[700],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.title,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              s.reason,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.black,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 2,
                          vertical: 6,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 14,
                              color: Colors.orange[700],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${s.durationMins}m',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.orange[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildAiPredictionCard() {
    final hasPrediction = _aiMoodPrediction != null;
    final hasError = _aiPredictionError != null;
    final confidencePercent = hasPrediction
        ? (_aiMoodPrediction!.confidence * 100).round()
        : 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Colors.purple.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with prediction
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.purple.withValues(alpha: 0.15),
                      Colors.purple.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  hasPrediction ? Icons.auto_graph : Icons.hourglass_empty,
                  color: Colors.purple[700],
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mood Prediction',
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      hasError
                          ? 'Connection failed'
                          : _isRefreshingPrediction
                          ? 'Updating prediction...'
                          : hasPrediction
                          ? 'Next 24 hours outlook'
                          : 'Analyzing patterns...',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: hasError
                            ? Colors.red[600]
                            : _isRefreshingPrediction
                            ? Colors.blue[600]
                            : Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isRefreshingPrediction)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          valueColor: AlwaysStoppedAnimation(Colors.blue[700]),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Updating...',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                )
              else if (hasPrediction)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: confidencePercent >= 70
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        confidencePercent >= 70
                            ? Icons.trending_up
                            : Icons.help_outline,
                        size: 12,
                        color: confidencePercent >= 70
                            ? Colors.green[700]
                            : Colors.amber[700],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$confidencePercent%',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: confidencePercent >= 70
                              ? Colors.green[700]
                              : Colors.amber[700],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Content
          if (hasError)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withValues(alpha: 0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red[700],
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Connection Error',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.red[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _aiPredictionError!,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.red[600],
                    ),
                  ),
                ],
              ),
            )
          else if (!hasPrediction)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.grey[600]),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Analyzing mood patterns...',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.grey[700],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.purple.withValues(alpha: 0.08),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Prediction result
                  Row(
                    children: [
                      Text(
                        'Likely feeling:',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 6,
                        ),
                        child: Text(
                          _aiMoodPrediction!.predictedMood,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.purple[700],
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Reasoning if available
                  if (_aiMoodPrediction!.reason.isNotEmpty) ...[
                    Container(
                      height: 1,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.purple.withValues(alpha: 0.1),
                            Colors.purple.withValues(alpha: 0.3),
                            Colors.purple.withValues(alpha: 0.1),
                          ],
                        ),
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            _aiMoodPrediction!.reason,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.black,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _MoodBadge extends StatelessWidget {
  const _MoodBadge({
    required this.mood,
    required this.size,
    required this.borderColor,
  });

  final String mood;
  final double size;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    // Map moods to emoji icons based on your emotion system
    final moodEmojis = {
      'Happy': '😊',
      'Cutesy': '🥰',
      'Shocked': '😲',
      'Neutral': '😐',
      'Awkward': '😅',
      'Disappointed': '😞',
      'Sad': '😢',
      'Angry': '😠',
      'Worried': '😟',
      'Tired': '😴',
    };

    final emoji = moodEmojis[mood] ?? '😐';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            offset: const Offset(2, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Center(
        child: Text(emoji, style: TextStyle(fontSize: size * 0.4)),
      ),
    );
  }
}

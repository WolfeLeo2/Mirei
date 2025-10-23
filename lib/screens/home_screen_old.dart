import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/typography.dart';

/// Headspace-inspired home screen
/// Features: Today's meditation, streaks, recommended content, categories
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 0,
            floating: true,
            pinned: false,
            backgroundColor: theme.scaffoldBackgroundColor,
            foregroundColor: theme.colorScheme.onBackground,
            elevation: 0,
            systemOverlayStyle: isDark 
              ? SystemUiOverlayStyle.light 
              : SystemUiOverlayStyle.dark,
            title: Text(
              'Today',
              style: CustomTextStyles.appBarTitle(
                color: theme.colorScheme.onBackground,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.person_outline, 
                  color: theme.colorScheme.onBackground),
                onPressed: () {
                  // Navigate to profile
                },
              ),
            ],
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  
                  // Greeting
                  _buildGreeting(context),
                  const SizedBox(height: 24),

                  // Today's Meditation Card
                  _buildTodayCard(context),
                  const SizedBox(height: 32),

                  // Streak Section
                  _buildStreakSection(context),
                  const SizedBox(height: 32),

                  // Recommended Section
                  _buildSectionHeader(context, 'Recommended for you'),
                  const SizedBox(height: 16),
                  _buildRecommendedList(context),
                  const SizedBox(height: 32),

                  // Categories
                  _buildSectionHeader(context, 'Explore'),
                  const SizedBox(height: 16),
                  _buildCategoryGrid(context),
                  const SizedBox(height: 100), // Bottom padding for nav bar
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGreeting(BuildContext context) {
    final theme = Theme.of(context);
    final hour = DateTime.now().hour;
    String greeting = 'Good morning';
    if (hour >= 12 && hour < 17) {
      greeting = 'Good afternoon';
    } else if (hour >= 17) {
      greeting = 'Good evening';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: CustomTextStyles.heroText(
            color: theme.colorScheme.onBackground,
          ).copyWith(fontSize: 32),
        ),
        const SizedBox(height: 4),
        Text(
          'How are you feeling today?',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onBackground.withOpacity(0.7),
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildTodayCard(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Navigate to meditation
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'TODAY',
                        style: CustomTextStyles.caption(
                          color: Colors.white,
                        ).copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Managing Stress',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '10 min · Meditation',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Icon(
                        Icons.play_arrow_rounded,
                        color: theme.colorScheme.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Start',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStreakSection(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.local_fire_department_rounded,
              color: theme.colorScheme.secondary,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '7 day streak',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Keep it going!',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onBackground,
      ),
    );
  }

  Widget _buildRecommendedList(BuildContext context) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 5,
        itemBuilder: (context, index) {
          return _buildRecommendedCard(context, index);
        },
      ),
    );
  }

  Widget _buildRecommendedCard(BuildContext context, int index) {
    final theme = Theme.of(context);
    final titles = [
      'Calm Anxiety',
      'Better Sleep',
      'Focus & Productivity',
      'Self-Compassion',
      'Stress Relief',
    ];
    
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 16),
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image placeholder
              Container(
                height: 100,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.self_improvement_rounded,
                    color: theme.colorScheme.primary,
                    size: 40,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titles[index],
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${5 + index} sessions',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryGrid(BuildContext context) {
    final theme = Theme.of(context);
    final categories = [
      {'icon': Icons.bedtime_rounded, 'title': 'Sleep'},
      {'icon': Icons.spa_rounded, 'title': 'Meditation'},
      {'icon': Icons.favorite_rounded, 'title': 'Stress'},
      {'icon': Icons.psychology_rounded, 'title': 'Focus'},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.5,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return Material(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(
                    category['icon'] as IconData,
                    color: theme.colorScheme.primary,
                    size: 32,
                  ),
                  Text(
                    category['title'] as String,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import '../models/meditation.dart';
import '../components/hero_meditation_card.dart';
import '../components/meditation_card.dart';
import '../services/meditation_player_service.dart';
import 'meditation_player_screen.dart';

class MeditationScreen extends StatefulWidget {
  const MeditationScreen({super.key});

  @override
  State<MeditationScreen> createState() => _MeditationScreenState();
}

class _MeditationScreenState extends State<MeditationScreen> {
  final PageController _heroPageController = PageController();
  final MeditationPlayerService _playerService = MeditationPlayerService();
  int _currentHeroPage = 0;

  final List<Meditation> _heroMeditations = [
    Meditation(
      title: 'Relax Mode',
      duration: '9 Minutes',
      imagePath:
          'https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=800',
      color: const Color(0xFFfce5e7),
      audioUrl: 'https://wolfeleo2.github.io/audio-cdn/breathing.mp3',
      category: 'SERENITY',
      gradientColors: const [Color(0xFFfce5e7), Color(0xFFe8e0f9)],
    ),
    Meditation(
      title: 'Deep Sleep',
      duration: '15 Minutes',
      imagePath:
          'https://images.unsplash.com/photo-1511376777868-611b54f68947?w=800',
      color: const Color(0xFFd9f0ff),
      audioUrl: 'https://wolfeleo2.github.io/audio-cdn/breathing.mp3',
      category: 'SLEEP',
      gradientColors: const [Color(0xFFd9f0ff), Color(0xFFcde5fe)],
    ),
    Meditation(
      title: 'Focus Mode',
      duration: '10 Minutes',
      imagePath:
          'https://images.unsplash.com/photo-1528715471579-d1bcf0ba5e83?w=800',
      color: const Color(0xFF6366f1),
      audioUrl: 'https://wolfeleo2.github.io/audio-cdn/breathing.mp3',
      category: 'FOCUS',
      gradientColors: const [Color(0xFF6366f1), Color(0xFF8b5cf6)],
    ),
  ];

  final List<Meditation> _morningMeditations = [
    Meditation(
      title: 'Morning Calm',
      duration: '5 min',
      imagePath:
          'https://images.unsplash.com/photo-1499209974431-9dddcece7f88?w=600',
      color: const Color(0xFFffd700),
      audioUrl: 'https://wolfeleo2.github.io/audio-cdn/breathing.mp3',
      gradientColors: const [Color(0xFFffd700), Color(0xFFffa500)],
    ),
    Meditation(
      title: 'Sunrise Energy',
      duration: '7 min',
      imagePath:
          'https://images.unsplash.com/photo-1495954484750-af469f2f9be5?w=600',
      color: const Color(0xFFff6b6b),
      audioUrl: 'https://wolfeleo2.github.io/audio-cdn/breathing.mp3',
      gradientColors: const [Color(0xFFff6b6b), Color(0xFFfeca57)],
    ),
    Meditation(
      title: 'Wake Up Flow',
      duration: '10 min',
      imagePath:
          'https://images.unsplash.com/photo-1508672019048-805c876b67e2?w=600',
      color: const Color(0xFF48dbfb),
      audioUrl: 'https://wolfeleo2.github.io/audio-cdn/breathing.mp3',
      gradientColors: const [Color(0xFF48dbfb), Color(0xFF0abde3)],
    ),
  ];

  final List<Meditation> _sleepMeditations = [
    Meditation(
      title: 'Deep Rest',
      duration: '20 min',
      imagePath:
          'https://images.unsplash.com/photo-1541781774459-bb2af2f05b55?w=600',
      color: const Color(0xFF341f97),
      audioUrl: 'https://wolfeleo2.github.io/audio-cdn/breathing.mp3',
      gradientColors: const [Color(0xFF341f97), Color(0xFF5f27cd)],
    ),
    Meditation(
      title: 'Night Peace',
      duration: '15 min',
      imagePath:
          'https://images.unsplash.com/photo-1519681393784-d120267933ba?w=600',
      color: const Color(0xFF192a56),
      audioUrl: 'https://wolfeleo2.github.io/audio-cdn/breathing.mp3',
      gradientColors: const [Color(0xFF192a56), Color(0xFF273c75)],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _heroPageController.addListener(() {
      final page = _heroPageController.page?.round() ?? 0;
      if (page != _currentHeroPage) {
        setState(() {
          _currentHeroPage = page;
        });
      }
    });
  }

  @override
  void dispose() {
    _heroPageController.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    if (hour < 21) return 'Good Evening';
    return 'Good Night';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/mesh-grad.png'),
            fit: BoxFit.cover,
            opacity: 0.9,
          ),
        ),
        child: SafeArea( 
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 30),
              physics: const BouncingScrollPhysics(),
              children: [
                RepaintBoundary(child: _buildDynamicSubtitle()),
                const SizedBox(height: 20),
                RepaintBoundary(child: _buildHeroSection()),
                const SizedBox(height: 20),
                RepaintBoundary(child: _buildPageIndicators()),
                const SizedBox(height: 30),
                RepaintBoundary(child: _buildNowPlayingWidget()),
                const SizedBox(height: 30),
                RepaintBoundary(
                  child: _buildSectionHeader('Morning Meditations'),
                ),
                const SizedBox(height: 16),
                RepaintBoundary(
                  child: _buildHorizontalList(_morningMeditations),
                ),
                const SizedBox(height: 30),
                RepaintBoundary(
                  child: _buildSectionHeader('Sleep Meditations'),
                ),
                const SizedBox(height: 16),
                RepaintBoundary(child: _buildHorizontalList(_sleepMeditations)),
                const SizedBox(height: 100),
              ],
            ),
          ),
      ),
    );
  }

  Widget _buildDynamicSubtitle() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          _getGreeting(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    final screenHeight = MediaQuery.of(context).size.height;

    return SizedBox(
      height: screenHeight * 0.3,
      child: PageView.builder(
        controller: _heroPageController,
        itemCount: _heroMeditations.length,
        itemBuilder: (context, index) {
          final meditation = _heroMeditations[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: HeroMeditationCard(
              meditation: meditation,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        MeditationPlayerScreen(meditation: meditation),
                  ),
                );
              },
              onPlayPressed: () {
                _playerService.playMeditation(meditation);
              },
              isPlaying:
                  _playerService.currentMeditation?.audioUrl ==
                      meditation.audioUrl &&
                  _playerService.isPlaying,
            ),
          );
        },
      ),
    );
  }

  Widget _buildPageIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_heroMeditations.length, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentHeroPage == index ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: _currentHeroPage == index
                ? const Color.fromARGB(255, 20, 50, 81)
                : const Color.fromARGB(100, 20, 50, 81),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _buildNowPlayingWidget() {
    return StreamBuilder<Meditation?>(
      stream: _playerService.currentMeditationStream,
      builder: (context, snapshot) {
        final currentMeditation = snapshot.data;
        final isPlaying = currentMeditation != null;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SizedBox(
            height: 240,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: Staggered stats grid (1x2 tall + two 1x1 tiles)
                Expanded(
                  flex: 2,
                  child: _buildStatsGrid(),
                ),
                const SizedBox(width: 12),
                // Right: Separate Now Playing card (same height as grid)
                Expanded(
                  flex: 3,
                  child: SizedBox(
                    height: 240,
                    child: isPlaying
                        ? _buildPlayingCard(currentMeditation)
                        : _buildEmptyPlayingCard(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String value, String label) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Color.fromARGB(255, 20, 50, 81),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Color.fromARGB(150, 20, 50, 81),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // Tall 1x2 stat tile with a simple "liquid" fill showing minutes/60
  Widget _buildTallStatCard({required int minutes, required String label}) {
    final clamped = minutes.clamp(0, 60);
    final target = clamped / 60.0; // 0.0 - 1.0
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: target),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            children: [
              // Liquid fill background
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: FractionallySizedBox(
                      heightFactor: value, // fill from bottom to value
                      widthFactor: 1,
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Color(0xFFE9D6FF),
                              Color(0xFFDCC7FF),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Content on top
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    '${clamped}m',
                    style: const TextStyle(
                      color: Color.fromARGB(255, 20, 50, 81),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Color.fromARGB(150, 20, 50, 81),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // Stats grid matching the reference (1x2 tall tile + two 1x1 tiles)
  Widget _buildStatsGrid() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1x2 tall tile on the left
        Expanded(
          child: _buildTallStatCard(minutes: 25, label: 'Today'),
        ),
        const SizedBox(width: 12),
        // Two stacked 1x1 tiles on the right
        Expanded(
          child: Column(
            children: [
              Expanded(child: _buildStatCard('7', 'Streak')),
              const SizedBox(height: 12),
              Expanded(child: _buildStatCard('3', 'Sessions')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyPlayingCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4EC), // Solid per request
        borderRadius: BorderRadius.circular(28),
      ),
      child: const Center(
        child: Text(
          'Nothing is playing',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color.fromARGB(255, 20, 50, 81),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildPlayingCard(Meditation meditation) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4EC), // Solid color even when active
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            meditation.category ?? 'Meditation',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color.fromARGB(150, 20, 50, 81),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            meditation.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color.fromARGB(255, 20, 50, 81),
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          StreamBuilder<Duration>(
            stream: _playerService.positionStream,
            builder: (context, positionSnapshot) {
              final position = positionSnapshot.data ?? Duration.zero;
              final minutes = position.inMinutes;
              final seconds = position.inSeconds % 60;
              return Text(
                '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  color: Color.fromARGB(150, 20, 50, 81),
                  fontSize: 13,
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          // Controls centered to mimic reference
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.replay_10),
                color: const Color.fromARGB(255, 20, 50, 81),
                iconSize: 32,
                onPressed: () {
                  final currentPosition = _playerService.currentPosition;
                  final newPosition = currentPosition - const Duration(seconds: 15);
                  _playerService.seek(newPosition > Duration.zero ? newPosition : Duration.zero);
                },
              ),
              const SizedBox(width: 8),
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Color.fromARGB(255, 20, 50, 81),
                  shape: BoxShape.circle,
                ),
                child: StreamBuilder<bool>(
                  stream: _playerService.isPlayingStream,
                  builder: (context, snapshot) {
                    final playing = snapshot.data ?? false;
                    return IconButton(
                      icon: Icon(playing ? Icons.pause : Icons.play_arrow,
                          color: Colors.white),
                         
                      onPressed: () {
                        if (playing) {
                          _playerService.pause();
                        } else {
                          _playerService.resume();
                        }
                      },
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.forward_10),
                color: const Color.fromARGB(255, 20, 50, 81),
                iconSize: 32,
                onPressed: () {
                  final currentPosition = _playerService.currentPosition;
                  final duration = _playerService.totalDuration;
                  final newPosition = currentPosition + const Duration(seconds: 10);
                  _playerService.seek(newPosition < duration ? newPosition : duration);
                },
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        title,
        style: const TextStyle(
          color: Color.fromARGB(255, 20, 50, 81),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildHorizontalList(List<Meditation> meditations) {
    return SizedBox(
      height: 170,
      child: ListView.builder(
        padding: const EdgeInsets.only(left: 20),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: meditations.length,
        itemBuilder: (context, index) {
          final meditation = meditations[index];
          return MeditationCard(
            meditation: meditation,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      MeditationPlayerScreen(meditation: meditation),
                ),
              );
            },
            onPlayPressed: () {
              _playerService.playMeditation(meditation);
            },
            isPlaying:
                _playerService.currentMeditation?.audioUrl ==
                    meditation.audioUrl &&
                _playerService.isPlaying,
          );
        },
      ),
    );
  }
}

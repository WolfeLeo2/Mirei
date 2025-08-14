import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mirei/bloc/media_player_bloc.dart';
import 'package:mirei/bloc/mood_bloc.dart';
import 'package:mirei/repositories/mood_repository.dart';
import 'package:mirei/screens/main_navigation.dart';
import 'package:mirei/services/audio_cache_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/performance_service.dart';
import 'services/database_maintenance_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services in parallel for faster startup
  await Future.wait([
    initializePerformanceService(),
    initializeDatabaseServices(),
    initializeAudioServices(),
  ]);

  runApp(const MyApp());
}

/// Initialize performance service for app optimization
Future<void> initializePerformanceService() async {
  try {
    final performanceService = PerformanceService();
    await performanceService.initialize();
    performanceService.startMonitoring();
  } catch (e) {
    // Silently handle errors - continue app startup
  }
}

/// Initialize database optimization services
Future<void> initializeDatabaseServices() async {
  try {
    final maintenanceService = DatabaseMaintenanceService();
    maintenanceService.startAutomatedMaintenance();
  } catch (e) {
    // Silently handle errors - continue app startup
  }
}

/// Initialize background audio services
Future<void> initializeAudioServices() async {
  try {
    // Background audio is now handled by just_audio_background
    // Pre-warm audio system
    final player = AudioPlayer();
    await player.dispose();
  } catch (e) {
    // Silently handle errors - continue app startup
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) =>
              MoodBloc(moodRepository: RealmMoodRepository())
                ..add(const LoadInitialMood()),
        ),
        BlocProvider(
          create: (context) => MediaPlayerBloc(
            audioPlayer: AudioPlayer(),
            cacheService: AudioCacheService(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Mirei',
        theme: ThemeData(
          textTheme: GoogleFonts.interTextTheme(),
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.black87
          ),
          useMaterial3: true,
        ),
        home: const MainNavigation(),
      ),
    );
  }
}

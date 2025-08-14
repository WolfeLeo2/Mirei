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

  // Initialize performance service
  await initializePerformanceService();

  // Initialize database maintenance service
  await initializeDatabaseServices();

  // Initialize background audio service
  await initializeAudioServices();

  runApp(const MyApp());
}

/// Initialize performance service for app optimization
Future<void> initializePerformanceService() async {
  try {
    final performanceService = PerformanceService();
    await performanceService.initialize();
    performanceService.startMonitoring();

    debugPrint('Performance service initialized successfully');
  } catch (e) {
    debugPrint('Error initializing performance service: $e');
    // Continue app startup even if performance service fails
  }
}

/// Initialize database optimization services
Future<void> initializeDatabaseServices() async {
  try {
    final maintenanceService = DatabaseMaintenanceService();
    maintenanceService.startAutomatedMaintenance();

    debugPrint('Database maintenance service initialized successfully');
  } catch (e) {
    debugPrint('Error initializing database services: $e');
    // Continue app startup even if database services fail
  }
}

/// Initialize background audio services
Future<void> initializeAudioServices() async {
  try {
    // Background audio is now handled by just_audio_background
    debugPrint('Background audio service initialized successfully');
  } catch (e) {
    debugPrint('Error initializing audio services: $e');
    // Continue app startup even if audio services fail
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
            seedColor: const Color.fromARGB(255, 11, 49, 22),
          ),
          useMaterial3: true,
        ),
        home: const MainNavigation(),
      ),
    );
  }
}

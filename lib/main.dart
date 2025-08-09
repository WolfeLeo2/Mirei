import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mirei/bloc/emotion_bloc.dart';
import 'package:mirei/repositories/mood_repository.dart';
import 'package:mirei/screens/main_navigation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/performance_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize performance service
  await initializePerformanceService();
  
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => EmotionBloc(
            moodRepository: RealmMoodRepository(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Mirei',
        theme: ThemeData(
          textTheme: GoogleFonts.interTextTheme(),
          colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 11, 49, 22)),
          useMaterial3: true,
        ),
        home: const MainNavigation(),
      ),
    );
  }
}

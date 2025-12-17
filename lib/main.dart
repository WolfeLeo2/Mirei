import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mirei/bloc/mood_bloc.dart';
import 'package:mirei/repositories/mood_repository.dart';
import 'package:mirei/screens/auth/auth_wrapper.dart';
import 'services/performance_service.dart';
import 'services/database_maintenance_service.dart';

import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
    if (kDebugMode) {
      print('✅ Environment variables loaded successfully');
    }
  } catch (e) {
    if (kDebugMode) {
      print('⚠️ Warning: Could not load .env file: $e');
    }
  }

  // Initialize Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );
  if (kDebugMode) {
    print('✅ Supabase initialized successfully');
  }

  // Realm is initialized automatically when first accessed
  if (kDebugMode) {
    print('✅ Using Realm for all data storage');
  }

  // Test SharedPreferences early to catch issues
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('test_key', 'test_value');
    final testValue = prefs.getString('test_key');
    if (testValue == 'test_value') {
      if (kDebugMode) {
        print('✅ SharedPreferences initialized successfully');
      }
    }
    await prefs.remove('test_key'); // Clean up test
  } catch (e) {
    if (kDebugMode) {
      print('⚠️ SharedPreferences initialization warning: $e');
    }
    // Continue anyway - the app will work with Realm storage
  }

  // Initialize services in parallel for faster startup
  await Future.wait([
    initializePerformanceService(),
    initializeDatabaseServices(),
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
      ],
      child: MaterialApp(
        title: 'Mirei',
        theme: AppTheme.light(),
        //darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        home: const AuthWrapper(),
      ),
    );
  }
}

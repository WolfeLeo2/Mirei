import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mirei/bloc/emotion_bloc.dart';
import 'package:mirei/bloc/youtube_music_bloc.dart';
import 'package:mirei/bloc/music_player_bloc.dart';
import 'package:mirei/screens/main_navigation.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => EmotionBloc()),
        BlocProvider(create: (context) => YouTubeMusicBloc()),
        BlocProvider(create: (context) => MusicPlayerBloc()..add(const InitializePlayer())),
      ],
      child: MaterialApp(
        title: 'Mirei',
        theme: ThemeData(
          textTheme: GoogleFonts.interTextTheme(),
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const MainNavigation(),
      ),
    );
  }
}

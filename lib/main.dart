import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // For custom fonts
import 'screens/home_screen.dart';

void main() {
  runApp(const MireiApp());
}

class MireiApp extends StatelessWidget {
  const MireiApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mirei',
      theme: ThemeData.light().copyWith(
        primaryColor: const Color(0xFFa9a0ff),
        textTheme: GoogleFonts.manropeTextTheme(),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: const Color(0xFFa9a0ff),
          secondary: const Color(0xFF1a237e),
        ),
      ),
      home: const HomeScreen(),
      
    );
  }
}

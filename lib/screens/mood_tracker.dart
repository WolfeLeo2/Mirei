import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mirei/components/activity_icon.dart';
import 'package:mirei/components/emotion_button.dart';
import 'package:mirei/models/user.dart';
import '../models/mood_entry.dart';
import '../utils/database_helper.dart';
import 'progress.dart';
import 'journal_list.dart';

class MoodTrackerScreen extends StatefulWidget {
  const MoodTrackerScreen({super.key});

  @override
  _MoodTrackerScreenState createState() => _MoodTrackerScreenState();
}

class _MoodTrackerScreenState extends State<MoodTrackerScreen> {
  int selectedEmotionIndex = 1;
  final List<String> emotions = [
    'Angelic', 'Sorry', 'Excited', 'Embarrassed', 'Happy', 
    'Romantic', 'Neutral', 'Sad', 'Silly'
  ];
  
  final User _user = User(
    name: 'User',
    email: 'user@example.com',
    avatarUrl: 'https://i.pravatar.cc/150?img=12',
  );

  Future<void> _saveMoodSelection(String mood) async {
    try {
      // Create a mood entry
      final moodEntry = MoodEntry(
        mood: mood,
        createdAt: DateTime.now(),
        note: null, // Could add note functionality later
      );

      // Save to database
      await DatabaseHelper().insertMoodEntry(moodEntry);

      // Show confirmation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Mood "$mood" saved successfully!',
              style: TextStyle(
                fontFamily: GoogleFonts.inter().fontFamily,
                color: Colors.white,
              ),
            ),
            backgroundColor: const Color(0xFF115e5a),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error saving mood: $e',
              style: TextStyle(
                fontFamily: GoogleFonts.inter().fontFamily,
                color: Colors.white,
              ),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF115e5a),
      body: Column(
            children: [
              Container(
                color: const Color(0xFF115e5a),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundImage: NetworkImage(_user.avatarUrl),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _user.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: '.SF Pro Display',
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _user.email,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      fontFamily: '.SF Pro Text',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Container(height: 2, color: Colors.white),
                                Container(height: 2, color: Colors.white),
                                Container(height: 2, color: Colors.white),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          Text(
                            'Hi, How do you\nfeel today?',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              height: 1.2,
                              fontFamily: GoogleFonts.inter().fontFamily,
                            ),
                          ),
                          Positioned(
                            top: -10,
                            left: -20,
                            child: SvgPicture.asset(
                              'assets/icons/emphasis.svg',
                              width: 20,
                              height: 20,
                              color: Colors.white,
                            ),
                          ),
                          Positioned(
                            bottom: -10,
                            right: 50,
                            child: SvgPicture.asset(
                              'assets/icons/underline.svg',
                              width: 17,
                              height: 17,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Select your current emotion',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          fontFamily: '.SF Pro Text',
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              Container(
                color: const Color(0xFF115e5a),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    children: [
                      EmotionButton(
                        emotion: 'Angelic',
                        svgPath: 'assets/icons/angelic.svg',
                        isSelected: selectedEmotionIndex == 0,
                        onTap: () => setState(() => selectedEmotionIndex = 0),
                        onDoubleTap: () => _saveMoodSelection('Angelic'),
                      ),
                      EmotionButton(
                        emotion: 'Sorry',
                        svgPath: 'assets/icons/disappointed.svg',
                        isSelected: selectedEmotionIndex == 1,
                        onTap: () => setState(() => selectedEmotionIndex = 1),
                        onDoubleTap: () => _saveMoodSelection('Sorry'),
                      ),
                      EmotionButton(
                        emotion: 'Excited',
                        svgPath: 'assets/icons/excited.svg',
                        isSelected: selectedEmotionIndex == 2,
                        onTap: () => setState(() => selectedEmotionIndex = 2),
                        onDoubleTap: () => _saveMoodSelection('Excited'),
                      ),
                      EmotionButton(
                        emotion: 'Embarrassed',
                        svgPath: 'assets/icons/embarrassed.svg',
                        isSelected: selectedEmotionIndex == 3,
                        onTap: () => setState(() => selectedEmotionIndex = 3),
                        onDoubleTap: () => _saveMoodSelection('Embarrassed'),
                      ),
                      EmotionButton(
                        emotion: 'Happy',
                        svgPath: 'assets/icons/Happy.svg',
                        isSelected: selectedEmotionIndex == 4,
                        onTap: () => setState(() => selectedEmotionIndex = 4),
                        onDoubleTap: () => _saveMoodSelection('Happy'),
                      ),
                      EmotionButton(
                        emotion: 'Romantic',
                        svgPath: 'assets/icons/loving.svg',
                        isSelected: selectedEmotionIndex == 5,
                        onTap: () => setState(() => selectedEmotionIndex = 5),
                        onDoubleTap: () => _saveMoodSelection('Romantic'),
                      ),
                      EmotionButton(
                        emotion: 'Neutral',
                        svgPath: 'assets/icons/neutral.svg',
                        isSelected: selectedEmotionIndex == 6,
                        onTap: () => setState(() => selectedEmotionIndex = 6),
                        onDoubleTap: () => _saveMoodSelection('Neutral'),
                      ),
                      EmotionButton(
                        emotion: 'Sad',
                        svgPath: 'assets/icons/sad.svg',
                        isSelected: selectedEmotionIndex == 7,
                        onTap: () => setState(() => selectedEmotionIndex = 7),
                        onDoubleTap: () => _saveMoodSelection('Sad'),
                      ),
                      EmotionButton(
                        emotion: 'Silly',
                        svgPath: 'assets/icons/silly.svg',
                        isSelected: selectedEmotionIndex == 8,
                        onTap: () => setState(() => selectedEmotionIndex = 8),
                        onDoubleTap: () => _saveMoodSelection('Silly'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFFfaf6f1),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(25),
                      topRight: Radius.circular(25),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Hook/Handle component
                      Container(
                        margin: const EdgeInsets.only(top: 8, bottom: 8),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFF115e5a).withOpacity(0.6),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              20,
                              12,
                              18,
                              100,
                            ), // Added bottom padding for nav bar
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                RichText(
                                  text: TextSpan(
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700,
                                      height: 1.3,
                                      fontFamily:
                                          GoogleFonts.inter().fontFamily,
                                    ),
                                    children: [
                                      const TextSpan(
                                        text: 'Do You know?\n3 Days Your',
                                      ),
                                      WidgetSpan(
                                        alignment: PlaceholderAlignment.middle,
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            SvgPicture.asset(
                                              'assets/icons/circle.svg',
                                              width: 50,
                                              height: 35,
                                              color: const Color.fromARGB(
                                                255,
                                                180,
                                                235,
                                                117,
                                              ),
                                            ),
                                            Text(
                                              'Happiness',
                                              style: TextStyle(
                                                color: const Color.fromARGB(
                                                  255,
                                                  17,
                                                  84,
                                                  70,
                                                ),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 22,
                                                fontFamily: GoogleFonts.inter()
                                                    .fontFamily,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Some things you might be\ninterested in doing',
                                        style: TextStyle(
                                          color: Colors.black54,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w400,
                                          height: 1.4,
                                          fontFamily:
                                              GoogleFonts.inter().fontFamily,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      'View More',
                                      style: TextStyle(
                                        color: const Color(0xFF115e5a),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: '.SF Pro Text',
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 32),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const JournalListScreen(),
                                          ),
                                        );
                                      },
                                      child: const ActivityIcon(
                                        label: 'My Journal',
                                        backgroundColor: Color(0XFFc6e99f),
                                        svgIcon: 'assets/icons/message.svg',
                                        svgShape: 'assets/icons/octagon.svg',
                                        shapeSize: 120,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const ProgressScreen(),
                                          ),
                                        );
                                      },
                                      child: const ActivityIcon(
                                        label: 'My Progress',
                                        backgroundColor: Color(0xFFECE9A5),
                                        svgIcon: 'assets/icons/pie-chart.svg',
                                        svgShape: 'assets/icons/b-circle.svg',
                                      ),
                                    ),
                                    const ActivityIcon(
                                      label: 'Self-Serenity',
                                      backgroundColor: Color(0xFFC1DFDF),
                                      svgIcon: 'assets/icons/meditation.svg',
                                      svgShape: 'assets/icons/heptagon.svg',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
      ),
    );
  }

}

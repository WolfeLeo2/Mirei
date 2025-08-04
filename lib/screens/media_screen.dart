import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'media_player_screen.dart';

class MediaScreen extends StatefulWidget {
  const MediaScreen({super.key});

  @override
  _MediaScreenState createState() => _MediaScreenState();
}

class _MediaScreenState extends State<MediaScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFfaf6f1),
      appBar: AppBar(
        backgroundColor: const Color(0xFFfaf6f1),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Color(0xFF115e5a),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Media Library',
          style: GoogleFonts.inter(
            color: const Color(0xFF115e5a),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Color(0xFF115e5a)),
            onPressed: () {
              // TODO: Implement search functionality
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAlbumCards(),
          ],
        ),
      ),
    );
  }

  Widget _buildAlbumCards() {
    return Column(  
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top Picks',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF115e5a),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 0),
            scrollDirection: Axis.horizontal,
            itemCount: 3,
            itemBuilder: (context, index) {
              final albumTitles = [
                'Lofi Mix',
                'Ocean Waves',
                'Morning Jazz',
              ];
              final albumSubtitles = [
                'Kick back and relax',
                'Nature Sounds',
                'Relaxing Vibes',
              ];
              final albumImages = [
                'assets/images/lofi.png',
                'assets/images/bg-afternoon.jpg',
                'assets/images/bg-evening.jpg',
              ];

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MediaPlayerScreen(
                        trackTitle: albumTitles[index],
                        artistName: 'Various Artists',
                        albumArt: albumImages[index],
                      ),
                    ),
                  );
                },
                child: Container(
                  width: 200,
                  height: 200,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.07),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Stack(
                    children: [
                      // Dynamic image background
                      Positioned.fill(
                        child: Image.asset(
                          albumImages[index], 
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            // Fallback gradient if image doesn't exist
                            final gradients = [
                              const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                              ),
                              const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
                              ),
                              const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
                              ),
                            ];
                            return Container(
                              decoration: BoxDecoration(gradient: gradients[index]),
                            );
                          },
                        ),
                      ),

                      // Gradient overlay
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: 90,
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Color.fromARGB(180, 255, 255, 255),
                                Color.fromARGB(60, 255, 255, 255),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Title and subtitle - left aligned
                      Positioned(
                        left: 20,
                        right: 20,
                        bottom: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              albumTitles[index],
                              style: const TextStyle(
                                color: Color.fromARGB(255, 255, 255, 255),
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              albumSubtitles[index],
                              style: TextStyle(
                                color: const Color.fromARGB(255, 204, 222, 246).withAlpha(165),
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                letterSpacing: -0.3,
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
            },
          ),
        ),
      ],
    );
  }
}

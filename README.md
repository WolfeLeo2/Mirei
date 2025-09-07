# Mirei - Mental Wellness App 🌸

A comprehensive Flutter-based mental wellness application focused on mood tracking, journaling, and music therapy.

## Features ✨

### 🧠 **Mood Tracking**

- 10 emotion types with beautiful SVG icons
- Multiple daily check-ins with context
- Intensity tracking (1-10 scale)
- Trigger and activity correlation
- Advanced analytics and progress visualization

### 📔 **Journaling**

- Rich text editor with multimedia support
- Voice recordings with waveform visualization
- Image attachments and templates
- Mood context integration
- Search and filtering capabilities

### 🎵 **Music Therapy**

- Spotify integration (Web API + SDK)
- YouTube live stream support
- Local playlist management
- Advanced audio caching and streaming
- Background playback with mini-player

### 🎨 **User Experience**

- Material 3 design with adaptive theming
- Glassmorphism effects and smooth animations
- Breathing animation during inactivity
- Performance-optimized UI components
- Dark/light theme support

## Architecture 🏗️

### **Database: Full Realm**

- **Primary Database**: Realm for all structured data
- **Unified Storage**: Eliminated dual-database complexity
- **Models**: User profiles, mood entries, journal entries, audio cache
- **Performance**: Indexed queries, automatic maintenance, LRU caching

### **State Management**

- **BLoC Pattern**: Clean separation of business logic
- **Stream-based**: Reactive programming with proper lifecycle management
- **Performance**: Debounced updates, memory leak prevention

### **Audio System**

- **Smart Caching**: Predictive preloading with Realm storage
- **Multiple Sources**: Spotify, YouTube, radio, local files
- **Background Support**: Continues playing when app backgrounded
- **Optimization**: Connection pooling, parallel downloads

### **Authentication**

- **Firebase Auth**: Google Sign-In and email/password
- **Secure Storage**: Environment variables for credentials
- **Profile Management**: Avatar support and user preferences

## Tech Stack 📚

```yaml
Framework: Flutter 3.x with Dart 3.8.1
Database: Realm (100% - no Hive/SQLite)
State Management: flutter_bloc + freezed
Authentication: Firebase Auth + Google Sign-In
Audio: just_audio with advanced caching
Music: Spotify Web API + SDK
UI: Material 3 + custom components
Performance: Optimized with RepaintBoundary and mixins
```

## Getting Started 🚀

### Prerequisites

1. Flutter 3.x installed
2. Firebase project configured
3. Spotify Developer account (optional)

### Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Generate Realm models:
   ```bash
   dart run realm generate
   ```
4. Create `.env` file with your credentials:

   ```env
   # Spotify Integration
   SPOTIFY_CLIENT_ID=your_spotify_client_id
   SPOTIFY_CLIENT_SECRET=your_spotify_client_secret
   SPOTIFY_REDIRECT_URL=spotify-sdk://auth


   ```

5. Run the app:
   ```bash
   flutter run
   ```

## Project Structure 📁

```
lib/
├── bloc/               # State management (BLoC pattern)
├── components/         # Reusable UI components
├── core/              # App constants, themes, utilities
├── models/            # Realm data models
├── screens/           # App screens and navigation
├── services/          # Business logic and external APIs
├── utils/             # Helper functions and performance mixins
└── widgets/           # Custom widgets
```

## Performance Optimizations ⚡

- **Database**: Automated maintenance, query optimization, proper indexing
- **UI**: RepaintBoundary usage, lazy loading, chunked processing
- **Memory**: Proper stream cleanup, debounced updates
- **Caching**: Multi-layer strategy (audio, images, HTTP responses)
- **Audio**: Predictive caching, connection pooling

## Contributing 🤝

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License 📄

This project is licensed under the MIT License - see the LICENSE file for details.

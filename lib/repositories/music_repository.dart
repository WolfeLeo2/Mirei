import 'package:equatable/equatable.dart';

/// A simple model representing a song.
class Song extends Equatable {
  final String title;
  final String artist;
  final String coverUrl;

  const Song({
    required this.title,
    required this.artist,
    required this.coverUrl,
  });

  @override
  List<Object?> get props => [title, artist, coverUrl];
}

/// Abstract definition for a music data source.
abstract class MusicRepository {
  Future<List<Song>> fetchLofiPlaylist();
}

/// A mock repository that returns hardcoded data.
/// This simulates fetching data from a real API.
class MockMusicRepository implements MusicRepository {
  @override
  Future<List<Song>> fetchLofiPlaylist() async {
    // Simulate a network delay
    await Future.delayed(const Duration(seconds: 1));

    // Return a list of hardcoded songs
    return const [
      Song(
        title: 'Lofi Chill',
        artist: 'Mirei Studios',
        coverUrl: 'asset:assets/images/lofi_cover.png',
      ),
      Song(
        title: 'Sunset Vibes',
        artist: 'Mirei Studios',
        coverUrl: 'asset:assets/images/rnb_cover.png',
      ),
      Song(
        title: 'Morning Coffee',
        artist: 'Mirei Studios',
        coverUrl: 'asset:assets/images/lofi_girl.jpeg',
      ),
    ];
  }
}

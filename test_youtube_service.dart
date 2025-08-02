import 'lib/services/youtube_music_service.dart';

void main() async {
  print('Testing YouTube Music Service...');

  final service = YouTubeMusicService();

  try {
    // Test song search
    print('Testing song search...');
    final songs = await service.searchSongs('lofi');
    print('Found ${songs.length} songs');

    // Test album search
    print('Testing album search...');
    final albums = await service.searchAlbums('lofi');
    print('Found ${albums.length} albums');

    // Test artist search
    print('Testing artist search...');
    final artists = await service.searchArtists('Taylor Swift');
    print('Found ${artists.length} artists');

    // Test playlist search
    print('Testing playlist search...');
    final playlists = await service.searchPlaylists('chill');
    print('Found ${playlists.length} playlists');

    // Test comprehensive search
    print('Testing comprehensive search...');
    final searchResult = await service.searchAll('popular music');
    print('Total results: ${searchResult.totalResults}');
    print('Songs: ${searchResult.songs.length}');
    print('Albums: ${searchResult.albums.length}');
    print('Artists: ${searchResult.artists.length}');
    print('Playlists: ${searchResult.playlists.length}');

    print('All tests completed successfully!');
  } catch (e) {
    print('Error during testing: $e');
  } finally {
    service.dispose();
  }
}

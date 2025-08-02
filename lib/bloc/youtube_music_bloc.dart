import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../services/youtube_music_service.dart';
import '../models/youtube_music_models.dart';

// Events
abstract class YouTubeMusicEvent extends Equatable {
  const YouTubeMusicEvent();

  @override
  List<Object?> get props => [];
}

class SearchYouTubeMusic extends YouTubeMusicEvent {
  final String query;
  final int limit;

  const SearchYouTubeMusic(this.query, {this.limit = 20});

  @override
  List<Object?> get props => [query, limit];
}

class SearchYouTubeMusicSongs extends YouTubeMusicEvent {
  final String query;
  final int limit;

  const SearchYouTubeMusicSongs(this.query, {this.limit = 20});

  @override
  List<Object?> get props => [query, limit];
}

class SearchYouTubeMusicAlbums extends YouTubeMusicEvent {
  final String query;
  final int limit;

  const SearchYouTubeMusicAlbums(this.query, {this.limit = 20});

  @override
  List<Object?> get props => [query, limit];
}

class SearchYouTubeMusicArtists extends YouTubeMusicEvent {
  final String query;
  final int limit;

  const SearchYouTubeMusicArtists(this.query, {this.limit = 20});

  @override
  List<Object?> get props => [query, limit];
}

class SearchYouTubeMusicPlaylists extends YouTubeMusicEvent {
  final String query;
  final int limit;

  const SearchYouTubeMusicPlaylists(this.query, {this.limit = 20});

  @override
  List<Object?> get props => [query, limit];
}

class InitializeYouTubeMusicAuth extends YouTubeMusicEvent {
  final Map<String, String>? cookies;
  final Map<String, String>? headers;

  const InitializeYouTubeMusicAuth({this.cookies, this.headers});

  @override
  List<Object?> get props => [cookies, headers];
}

// States
abstract class YouTubeMusicState extends Equatable {
  const YouTubeMusicState();

  @override
  List<Object?> get props => [];
}

class YouTubeMusicInitial extends YouTubeMusicState {}

class YouTubeMusicLoading extends YouTubeMusicState {}

class YouTubeMusicAuthenticated extends YouTubeMusicState {}

class YouTubeMusicSongsLoaded extends YouTubeMusicState {
  final List<YouTubeSong> songs;
  final String query;

  const YouTubeMusicSongsLoaded(this.songs, this.query);

  @override
  List<Object?> get props => [songs, query];
}

class YouTubeMusicAlbumsLoaded extends YouTubeMusicState {
  final List<YouTubeAlbum> albums;
  final String query;

  const YouTubeMusicAlbumsLoaded(this.albums, this.query);

  @override
  List<Object?> get props => [albums, query];
}

class YouTubeMusicArtistsLoaded extends YouTubeMusicState {
  final List<YouTubeArtist> artists;
  final String query;

  const YouTubeMusicArtistsLoaded(this.artists, this.query);

  @override
  List<Object?> get props => [artists, query];
}

class YouTubeMusicPlaylistsLoaded extends YouTubeMusicState {
  final List<YouTubePlaylist> playlists;
  final String query;

  const YouTubeMusicPlaylistsLoaded(this.playlists, this.query);

  @override
  List<Object?> get props => [playlists, query];
}

class YouTubeMusicSearchResultsLoaded extends YouTubeMusicState {
  final YouTubeSearchResult searchResult;
  final String query;

  const YouTubeMusicSearchResultsLoaded(this.searchResult, this.query);

  @override
  List<Object?> get props => [searchResult, query];
}

class YouTubeMusicError extends YouTubeMusicState {
  final String message;

  const YouTubeMusicError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class YouTubeMusicBloc extends Bloc<YouTubeMusicEvent, YouTubeMusicState> {
  final YouTubeMusicService _service = YouTubeMusicService();

  YouTubeMusicBloc() : super(YouTubeMusicInitial()) {
    on<SearchYouTubeMusic>(_onSearchYouTubeMusic);
    on<SearchYouTubeMusicSongs>(_onSearchYouTubeMusicSongs);
    on<SearchYouTubeMusicAlbums>(_onSearchYouTubeMusicAlbums);
    on<SearchYouTubeMusicArtists>(_onSearchYouTubeMusicArtists);
    on<SearchYouTubeMusicPlaylists>(_onSearchYouTubeMusicPlaylists);
    on<InitializeYouTubeMusicAuth>(_onInitializeYouTubeMusicAuth);
  }

  Future<void> _onSearchYouTubeMusic(
    SearchYouTubeMusic event,
    Emitter<YouTubeMusicState> emit,
  ) async {
    try {
      emit(YouTubeMusicLoading());
      final searchResult = await _service.searchAll(event.query, limit: event.limit);
      emit(YouTubeMusicSearchResultsLoaded(searchResult, event.query));
    } catch (e) {
      emit(YouTubeMusicError(e.toString()));
    }
  }

  Future<void> _onSearchYouTubeMusicSongs(
    SearchYouTubeMusicSongs event,
    Emitter<YouTubeMusicState> emit,
  ) async {
    try {
      emit(YouTubeMusicLoading());
      final songs = await _service.searchSongs(event.query, limit: event.limit);
      emit(YouTubeMusicSongsLoaded(songs, event.query));
    } catch (e) {
      emit(YouTubeMusicError(e.toString()));
    }
  }

  Future<void> _onSearchYouTubeMusicAlbums(
    SearchYouTubeMusicAlbums event,
    Emitter<YouTubeMusicState> emit,
  ) async {
    try {
      emit(YouTubeMusicLoading());
      final albums = await _service.searchAlbums(event.query, limit: event.limit);
      emit(YouTubeMusicAlbumsLoaded(albums, event.query));
    } catch (e) {
      emit(YouTubeMusicError(e.toString()));
    }
  }

  Future<void> _onSearchYouTubeMusicArtists(
    SearchYouTubeMusicArtists event,
    Emitter<YouTubeMusicState> emit,
  ) async {
    try {
      emit(YouTubeMusicLoading());
      final artists = await _service.searchArtists(event.query, limit: event.limit);
      emit(YouTubeMusicArtistsLoaded(artists, event.query));
    } catch (e) {
      emit(YouTubeMusicError(e.toString()));
    }
  }

  Future<void> _onSearchYouTubeMusicPlaylists(
    SearchYouTubeMusicPlaylists event,
    Emitter<YouTubeMusicState> emit,
  ) async {
    try {
      emit(YouTubeMusicLoading());
      final playlists = await _service.searchPlaylists(event.query, limit: event.limit);
      emit(YouTubeMusicPlaylistsLoaded(playlists, event.query));
    } catch (e) {
      emit(YouTubeMusicError(e.toString()));
    }
  }

  Future<void> _onInitializeYouTubeMusicAuth(
    InitializeYouTubeMusicAuth event,
    Emitter<YouTubeMusicState> emit,
  ) async {
    try {
      emit(YouTubeMusicLoading());
      _service.initializeWithAuth(
        cookies: event.cookies,
        headers: event.headers,
      );
      emit(YouTubeMusicAuthenticated());
    } catch (e) {
      emit(YouTubeMusicError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _service.dispose();
    return super.close();
  }
}
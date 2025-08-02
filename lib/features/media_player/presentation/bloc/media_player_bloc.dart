import 'package:flutter_bloc/flutter_bloc.dart';

enum MediaPlayerMode { library, streaming }

class MediaPlayerBloc extends Cubit<MediaPlayerMode> {
  MediaPlayerBloc() : super(MediaPlayerMode.library);

  void toggleMode() {
    emit(state == MediaPlayerMode.library 
        ? MediaPlayerMode.streaming 
        : MediaPlayerMode.library);
  }
}

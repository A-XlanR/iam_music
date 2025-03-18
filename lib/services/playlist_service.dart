import 'package:iam_music/models/song.dart';

class PlaylistService {
  static final List<Song> _playlist = [];

  static List<Song> getPlaylist() => _playlist;

  static void addToPlaylist(Song song) {
    if (!_playlist.contains(song)) {
      _playlist.add(song);
    }
  }

  static void removeFromPlaylist(Song song) {
    _playlist.remove(song);
  }

  static void clearPlaylist() {
    _playlist.clear();
  }
}

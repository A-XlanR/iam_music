import 'package:iam_music/models/song.dart';

class Playlist {
  final String name;
  final List<Song> songs;

  Playlist({required this.name, List<Song>? songs}) : songs = songs ?? [];

  // Ajouter une musique à la playlist
  void addSong(Song song) {
    if (!songs.any((m) => m.id == song.id)) {
      songs.add(song);
    }
  }

  // Supprimer une musique de la playlist
  void removeSong(Song song) {
    songs.removeWhere((m) => m.id == song.id);
  }

  // Vérifier si une musique est déjà présente
  bool contains(Song song) {
    return songs.any((m) => m.id == song.id);
  }

  // Convertir en JSON
  Map<String, dynamic> toJson() => {
    'name': name,
    'songs': songs.map((song) => song.toJson()).toList(),
  };

  // Créer une playlist depuis JSON
  factory Playlist.fromJson(Map<String, dynamic> json) => Playlist(
    name: json['name'],
    songs: (json['songs'] as List).map((e) => Song.fromJson(e)).toList(),
  );
}

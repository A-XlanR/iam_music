import 'dart:typed_data';

class Song {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String path;
  final String? artwork;
  final Uint8List? coverArt;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.path,
    required this.coverArt,
    this.artwork,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'artist': artist,
    'album': album,
    'path': path,
    'artwork': artwork,
  };

  factory Song.fromJson(Map<String, dynamic> json) => Song(
    id: json['id'],
    title: json['title'],
    artist: json['artist'],
    album: json['album'],
    path: json['path'],
    artwork: json['artwork'],
    coverArt: json['coverArt'],
  );

  @override
  String toString() {
    return 'Song{id: $id, title: $title, artist: $artist, album: $album, path: $path, artwork: $artwork, coverArt: $coverArt}';
  }
}

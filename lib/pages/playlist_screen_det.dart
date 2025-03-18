import 'package:flutter/material.dart';
import 'package:iam_music/models/playlist.dart';
import 'package:iam_music/models/song.dart';
import 'package:iam_music/services/storage_service.dart';

class PlaylistScreenDet extends StatefulWidget {
  final Playlist playlist;

  const PlaylistScreenDet({super.key, required this.playlist});

  @override
  PlaylistScreenDetState createState() => PlaylistScreenDetState();
}

class PlaylistScreenDetState extends State<PlaylistScreenDet> {
  void _removeSong(Song song) {
    setState(() {
      widget.playlist.removeSong(song);
      StorageService.savePlaylists([widget.playlist]);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.playlist.name)),
      body: ListView.builder(
        itemCount: widget.playlist.songs.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(widget.playlist.songs[index].title),
            subtitle: Text(widget.playlist.songs[index].artist),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _removeSong(widget.playlist.songs[index]),
            ),
          );
        },
      ),
    );
  }
}

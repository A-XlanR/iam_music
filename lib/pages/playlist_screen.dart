import 'package:flutter/material.dart';
import 'package:iam_music/models/playlist.dart';
import 'package:iam_music/pages/playlist_screen_det.dart';
import 'package:iam_music/services/storage_service.dart';

class PlaylistScreen extends StatefulWidget {
  const PlaylistScreen({super.key});

  @override
  PlaylistScreenState createState() => PlaylistScreenState();
}

class PlaylistScreenState extends State<PlaylistScreen> {
  List<Playlist> _playlists = [];

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  // Charger les playlists
  Future<void> _loadPlaylists() async {
    List<Playlist> playlists = await StorageService.loadPlaylists();
    setState(() {
      _playlists = playlists;
    });
  }

  // Ajouter une nouvelle playlist
  void _addPlaylist() async {
    TextEditingController nameController = TextEditingController();
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("New playlist"),
            content: TextField(
              controller: nameController,
              decoration: const InputDecoration(hintText: "Playlist name"),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Discard"),
              ),
              TextButton(
                onPressed: () {
                  if (nameController.text.isNotEmpty) {
                    setState(() {
                      _playlists.add(Playlist(name: nameController.text));
                    });
                    StorageService.savePlaylists(_playlists);
                    Navigator.pop(context);
                  }
                },
                child: const Text("Create"),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Playlists"),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _addPlaylist),
        ],
      ),
      body: ListView.builder(
        itemCount: _playlists.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(_playlists[index].name),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) =>
                          PlaylistScreenDet(playlist: _playlists[index]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

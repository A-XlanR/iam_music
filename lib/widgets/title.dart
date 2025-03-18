import 'package:flutter/material.dart';
import 'package:iam_music/models/song.dart';

class SongTile extends StatelessWidget {
  final Song song;
  final VoidCallback onTap;

  const SongTile({super.key, required this.song, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child:
              song.coverArt != null
                  ? Image.memory(
                    song.coverArt!,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  )
                  : const Icon(Icons.music_note, size: 50),
        ),
        title: Text(
          song.title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        subtitle: Text(
          song.artist != '' ? song.artist : 'Artiste inconnu',
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        onTap: onTap,
      ),
    );
  }
}

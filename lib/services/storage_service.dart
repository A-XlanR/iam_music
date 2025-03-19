import 'dart:io';
import 'dart:convert';

import 'package:audiotagger/audiotagger.dart';
import 'package:audiotagger/models/tag.dart';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:iam_music/models/song.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/playlist.dart';

class StorageService {
  static const String _SongListKey = 'Song_list';
  static const String _SongFolderKey = 'Song_folder';
  static const String _lastPlayedSongKey = 'last_played_Song';
  static const List<String> _allowedExtensions = [
    '.mp3',
    '.wav',
    '.flac',
    '.m4a',
  ];

  // Vérifier et demander la permission de stockage adaptée à la version Android
  static Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      int sdkVersion = int.parse(await getSdkVersion());

      if (sdkVersion <= 32) {
        if (!(await Permission.storage.request().isGranted)) {
          debugPrint("❌ Permission de stockage refusée");
          return false;
        }
      }

      if (sdkVersion >= 30) {
        var status = await Permission.manageExternalStorage.request();
        if (!status.isGranted) {
          debugPrint("❌ Permission d'accès complet au stockage refusée");
          return false;
        }
      }

      if (await Permission.manageExternalStorage.isPermanentlyDenied ||
          await Permission.storage.isPermanentlyDenied) {
        debugPrint(
          "⚠️ L'utilisateur a bloqué les permissions. Ouvrir les paramètres...",
        );
        await openAppSettings();
        return false;
      }
      debugPrint(
        "🔍 Storage permission: ${await Permission.storage.isGranted}",
      );
      debugPrint(
        "🔍 Manage External Storage: ${await Permission.manageExternalStorage.isGranted}",
      );
    }
    return true;
  }

  // Obtenir la version SDK de l'appareil Android
  static Future<String> getSdkVersion() async {
    return await Process.run('getprop', ['ro.build.version.sdk']).then((
        result,
        ) {
      return result.stdout.toString().trim();
    });
  }

  // Sélectionner un dossier contenant des musiques
  static Future<List<Song>> pickSongFilesFromFolder() async {
    bool permissionGranted = await requestStoragePermission();
    if (!permissionGranted) {
      return [];
    }

    // Ouvre le sélecteur de dossier
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory == null) {
      debugPrint("Aucun dossier sélectionné");
      return [];
    }

    // Récupérer les fichiers audio du dossier
    Directory directory = Directory(selectedDirectory);
    if (!directory.existsSync()) {
      debugPrint(
        "⚠️ Le dossier sélectionné n'existe pas ou est inaccessible !",
      );
      return [];
    }

    List folderPaths = await getSongFolderPaths();
    debugPrint("📂 Dossiers enregistrés : $folderPaths");
    if (folderPaths.contains(selectedDirectory)) {
      debugPrint("Le dossier est déjà enregistré");
      return await loadSongList();
    }

    List<FileSystemEntity> files = directory.listSync();
    if (files.isEmpty) {
      debugPrint("   ️ Aucun fichier audio trouvé dans le dossier sélectionné");
      return [];
    }

    List<Song> newSongList = [];

    for (var file in files) {
      debugPrint("!! Creating new Song list with file: ${file.path}");
      if (file is File && _allowedExtensions.any(file.path.endsWith)) {
        debugPrint("🔍 Traitement du fichier : ${file.path}");
        try {
          debugPrint("➡️ Début de l'extraction des métadonnées...");
          final tagger = Audiotagger();
          final Tag? metadata = await tagger.readTags(path: file.path);

          debugPrint("✅ Métadonnées extraites avec succès !");

          newSongList.add(
            Song(
              path: file.path,
              title: metadata?.title ?? file.uri.pathSegments.last,
              artist: metadata?.artist ?? "Inconnu",
              album: metadata?.album ?? "Inconnu",
              coverArt: metadata?.artwork != null ? File(metadata!.artwork!).readAsBytesSync() : null,
              id: file.hashCode.toString(),
            ),
          );
        } catch (e) {
          debugPrint("Erreur lors de l’extraction des métadonnées : $e");
        }
      }
    }

    if (newSongList.isEmpty) {
      debugPrint("⚠️ Aucun fichier audio trouvé dans le dossier sélectionné");
      return [];
    }

    // Mise à jour et sauvegarde de la liste des musiques
    folderPaths.add(selectedDirectory);
    List<Song> lastSongList = await loadSongList();
    List<Song> allSong = [...lastSongList, ...newSongList];
    allSong = allSong..sort((a, b) => a.artist.compareTo(b.artist));
    await saveSongList(allSong, folderPaths);

    debugPrint("✅ ${allSong.length} musiques chargées !");
    return allSong;
  }

  // Sauvegarder la liste des musiques dans SharedPreferences
  static Future<void> saveSongList(
      List<Song> SongList,
      List folderPaths,
      ) async {
    final prefs = await SharedPreferences.getInstance();
    final SongJsonList = SongList.map((Song) => Song.toJson()).toList();
    await prefs.setString(_SongListKey, jsonEncode(SongJsonList));
    await prefs.setString(_SongFolderKey, jsonEncode(folderPaths));
  }

  static Future<List> getSongFolderPaths() async {
    final prefs = await SharedPreferences.getInstance();
    String? paths = prefs.getString(_SongFolderKey);
    if (paths != null) {
      return jsonDecode(paths);
    }
    return [];
  }

  // Charger la liste des musiques
  static Future<List<Song>> loadSongList() async {
    final prefs = await SharedPreferences.getInstance();
    String? SongListJson = prefs.getString(_SongListKey);
    if (SongListJson != null) {
      List<dynamic> decodedList = jsonDecode(SongListJson);
      return decodedList.map((json) => Song.fromJson(json)).toList();
    }
    return [];
  }

  // Sauvegarder la dernière musique jouée
  static Future<void> saveLastPlayedSong(Song Song) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastPlayedSongKey, Song.path);
  }

  // Charger la dernière musique jouée
  static Future<Song?> getLastPlayedSong() async {
    final prefs = await SharedPreferences.getInstance();
    String? lastSongPlayedPath = prefs.getString(_lastPlayedSongKey);
    List<Song>? SongLists = await loadSongList();

    if (lastSongPlayedPath != null) {
      try {
        return SongLists.firstWhere((Song) => Song.path == lastSongPlayedPath);
      } catch (e) {
        debugPrint(e.toString());
        debugPrint("No music found here.");
        return null;
      }
    }
    return null;
  }

  static const String _playlistKey = 'playlists';

  // Sauvegarder les playlists dans SharedPreferences
  static Future<void> savePlaylists(List<Playlist> playlists) async {
    final prefs = await SharedPreferences.getInstance();
    final playlistJsonList =
    playlists.map((playlist) => playlist.toJson()).toList();
    await prefs.setString(_playlistKey, jsonEncode(playlistJsonList));
  }

  // Charger les playlists
  static Future<List<Playlist>> loadPlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    String? playlistsJson = prefs.getString(_playlistKey);
    if (playlistsJson != null) {
      List<dynamic> decodedList = jsonDecode(playlistsJson);
      return decodedList.map((json) => Playlist.fromJson(json)).toList();
    }
    return [];
  }
}

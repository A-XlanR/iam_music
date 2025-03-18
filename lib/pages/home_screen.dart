import 'package:flutter/material.dart';
import 'package:iam_music/models/song.dart';
import 'package:iam_music/pages/playlist_screen.dart';
import 'package:iam_music/services/storage_service.dart';
import 'package:iam_music/widgets/title.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

import '../models/playlist.dart';
import '../services/playlist_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Song> _musicList = [];
  List<Song> _filteredMusicList = []; // Liste filtrée pour l'affichage
  Song? _currentMusic;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final PanelController _panelController = PanelController();
  double _panelPosition = 0.0;
  bool _isSearching = false; // État pour afficher ou masquer la SearchBar
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeMusicData(); // Nouvelle méthode pour gérer l'initialisation

    // Mettre à jour la position actuelle
    _audioPlayer.positionStream.listen((pos) {
      setState(() {
        _position = pos;
      });
    });

    // Mettre à jour la durée totale
    _audioPlayer.durationStream.listen((dur) {
      setState(() {
        _duration = dur ?? Duration.zero;
      });
    });

    // Vérifier quand la lecture est terminée
    _audioPlayer.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        _playNext();
      }
    });

    _audioPlayer.currentIndexStream.listen((index) {
      if (index != null && index >= 0 && index < _musicList.length) {
        setState(() {
          _currentMusic = _musicList[index];
        });
      }
    });

    // Écouter les changements dans le champ de recherche
    _searchController.addListener(_filterMusicList);
  }

  // Nouvelle méthode pour initialiser les données de musique
  Future<void> _initializeMusicData() async {
    try {
      await _loadMusicList();
      if (_musicList.isEmpty) {
        debugPrint("no music found");
        return;
      }
      await _restoreLastPlayedMusic();
      setState(() {
        _filteredMusicList = List.from(_musicList);
      });
    } catch (e) {
      print("Error : $e");
      setState(() {
        _filteredMusicList = [];
      });
    }
  }

  // Filtrer la liste des musiques en fonction du texte saisi
  void _filterMusicList() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredMusicList = List.from(_musicList);
      } else {
        _filteredMusicList =
            _musicList.where((music) {
              return music.title.toLowerCase().contains(query) ||
                  music.artist.toLowerCase().contains(query);
            }).toList();
      }
    });
  }

  // Activer/désactiver le mode recherche
  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _filteredMusicList = List.from(_musicList); // Réinitialiser la liste
      }
    });
  }

  // Charger la liste des musiques
  Future<void> _loadMusicList() async {
    List<Song> savedMusicList = await StorageService.loadSongList();
    setState(() {
      _musicList = savedMusicList;
    });
  }

  // Restaurer la dernière musique jouée
  Future<void> _restoreLastPlayedMusic() async {
    Song? lastMusic = await StorageService.getLastPlayedSong();
    if (lastMusic != null) {
      setState(() {
        _currentMusic = lastMusic;
      });
    }
  }

  // Jouer ou mettre en pause la musique
  void _playMusic(Song music) async {
    if (_currentMusic == music) {
      if (_isPlaying) {
        await _audioPlayer.pause();
        setState(() {
          _isPlaying = false;
        });
      } else {
        await _audioPlayer.play();
        setState(() {
          _isPlaying = true;
        });
      }
    } else {
      await _audioPlayer.stop();
      await _audioPlayer.setAudioSource(
        AudioSource.uri(
          Uri.file(music.path),
          tag: MediaItem(
            id: music.path,
            title: music.title,
            artist: music.artist,
          ),
        ),
      );

      await _audioPlayer.play();
      setState(() {
        // _currentMusic = music;
        _isPlaying = true;
      });

      await StorageService.saveLastPlayedSong(_currentMusic!);
    }
  }

  // Passer à la musique suivante
  void _playNext() {
    if (_musicList.isEmpty) return;
    int currentIndex = _musicList.indexOf(_currentMusic!);
    int nextIndex = (currentIndex + 1) % _musicList.length;
    _playMusic(_musicList[nextIndex]);
  }

  // Passer à la musique précédente
  void _playPrevious() {
    if (_musicList.isEmpty) return;
    int currentIndex = _musicList.indexOf(_currentMusic!);
    int prevIndex = (currentIndex - 1) % _musicList.length;
    if (prevIndex < 0) prevIndex = _musicList.length - 1;
    _playMusic(_musicList[prevIndex]);
  }

  // Add music folder
  void _pickMusicFiles() async {
    List<Song> result = await StorageService.pickSongFilesFromFolder();
    setState(() {
      _musicList.addAll(result);
      _filteredMusicList = List.from(_musicList); // Synchronise après ajout
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _audioPlayer.dispose(); // Ajout pour éviter les fuites de mémoire
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            _isSearching
                ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: "Search for a song or artist...",
                    hintStyle: const TextStyle(color: Colors.black54),
                    border: InputBorder.none,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear, color: Colors.black54),
                      onPressed: () {
                        _searchController.clear();
                      },
                    ),
                  ),
                  style: const TextStyle(color: Colors.black, fontSize: 16),
                )
                : const Text(
                  'Music Player',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
        centerTitle: true,
        backgroundColor: Colors.pinkAccent, // Modern pink background
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.library_music,
              color: Colors.white,
            ), // Playlist icon
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PlaylistScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: Colors.white,
            ),
            onPressed: _toggleSearch,
          ),
          if (!_isSearching)
            IconButton(
              icon: const Icon(
                Icons.add_circle_outline,
                size: 28,
                color: Colors.white,
              ),
              onPressed: _pickMusicFiles,
            ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            color: Colors.black,
            child:
                _filteredMusicList.isEmpty && _musicList.isEmpty
                    ? const Center(
                      child: Icon(
                        Icons.create_new_folder_outlined,
                        color: Colors.white,
                      ), // Empty state icon
                    )
                    : ListView.builder(
                      itemCount: _filteredMusicList.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: SongTile(
                            song: _filteredMusicList[index],
                            onTap:
                                () => {
                                  _playMusic(_filteredMusicList[index]),
                                  setState(() {
                                    _currentMusic = _filteredMusicList[index];
                                  }),
                                },
                          ),
                        );
                      },
                    ),
          ),
          SlidingUpPanel(
            controller: _panelController,
            minHeight: 60,
            backdropEnabled: false,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            panelBuilder: (sc) => _buildExpandedPlayer(),
            collapsed: _buildMiniPlayer(),
            onPanelSlide: (position) {
              setState(() {
                _panelPosition = position;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMiniPlayer() {
    return Container(
      height: 55,
      margin: const EdgeInsets.only(right: 24, left: 24, bottom: 10),
      decoration: BoxDecoration(
        color: Colors.pinkAccent.withOpacity(0.8), // Pink accent background
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withAlpha(20),
            blurRadius: 20,
            spreadRadius: 10,
          ),
        ],
      ),
      child: GestureDetector(
        onTap: () => _panelController.open(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.pinkAccent.withOpacity(0.8),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: const [
              BoxShadow(
                color: Colors.white12,
                offset: Offset(0, 2),
                blurRadius: 8,
                spreadRadius: 0,
              ),
            ],
          ),
          height: 50 + (80 * _panelPosition),
          child: Row(
            children: [
              const Icon(Icons.music_note, size: 24, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 300),
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14 + (10 * _panelPosition),
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                      child: Text(
                        _currentMusic?.title ?? "No Music",
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      _currentMusic?.artist ?? "Unknown Artist",
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        fontFamily: 'Poppins',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.add,
                      color: Colors.white70,
                      size: 28,
                    ),
                    onPressed:
                        _currentMusic != null
                            ? () {
                              PlaylistService.addToPlaylist(_currentMusic!);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${_currentMusic!.title} added to the playlist!',
                                  ),
                                ),
                              );
                            }
                            : null,
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.add,
                      color: Colors.white70,
                      size: 28,
                    ),
                    onPressed:
                        _currentMusic != null
                            ? () async {
                              List<Playlist> playlists =
                                  await StorageService.loadPlaylists();

                              if (playlists.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Create a playlist first"),
                                  ),
                                );
                              } else {
                                showDialog(
                                  context: context,
                                  builder:
                                      (context) => AlertDialog(
                                        title: const Text("Add to Playlist"),
                                        content: SizedBox(
                                          width: double.maxFinite,
                                          child: ListView.builder(
                                            shrinkWrap: true,
                                            itemCount: playlists.length,
                                            itemBuilder: (context, index) {
                                              return ListTile(
                                                title: Text(
                                                  playlists[index].name,
                                                ),
                                                onTap: () {
                                                  playlists[index].addSong(
                                                    _currentMusic!,
                                                  );
                                                  StorageService.savePlaylists(
                                                    playlists,
                                                  );
                                                  Navigator.pop(context);
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        "${_currentMusic!.title} added to ${playlists[index].name}!",
                                                      ),
                                                    ),
                                                  );
                                                },
                                              );
                                            },
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed:
                                                () => Navigator.pop(context),
                                            child: const Text("Cancel"),
                                          ),
                                        ],
                                      ),
                                );
                              }
                            }
                            : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedPlayer() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          child:
              _currentMusic?.coverArt != null
                  ? Image.memory(
                    _currentMusic!.coverArt!,
                    height: 200,
                    width: 200,
                    fit: BoxFit.cover,
                  )
                  : const Icon(Icons.music_note, size: 75, color: Colors.white),
        ),
        const SizedBox(height: 20),
        Text(
          _currentMusic?.title ?? "No Music",
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          _currentMusic?.artist ?? '',
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white70,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Text(
              _formatDuration(_position),
              style: const TextStyle(fontSize: 12, color: Colors.white),
            ),
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 8,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 16,
                  ),
                  trackHeight: 4,
                ),
                child: Slider(
                  value: _position.inSeconds.toDouble(),
                  max: _duration.inSeconds.toDouble(),
                  activeColor: Colors.pinkAccent, // Active slider color
                  inactiveColor: Colors.grey[300],
                  onChanged: (value) {
                    _audioPlayer.seek(Duration(seconds: value.toInt()));
                    setState(
                      () => _position = Duration(seconds: value.toInt()),
                    );
                  },
                ),
              ),
            ),
            Text(
              _formatDuration(_duration),
              style: const TextStyle(fontSize: 12, color: Colors.white),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(
                Icons.skip_previous,
                size: 36,
                color: Colors.white,
              ),
              onPressed: _playPrevious,
            ),
            IconButton(
              icon: Icon(
                _isPlaying ? Icons.pause_circle : Icons.play_circle,
                size: 48,
                color: Colors.white,
              ),
              onPressed:
                  _currentMusic != null
                      ? () => _playMusic(_currentMusic!)
                      : null,
            ),
            IconButton(
              icon: const Icon(Icons.skip_next, size: 36, color: Colors.white),
              onPressed: _playNext,
            ),
          ],
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String minutes = twoDigits(duration.inMinutes);
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }
}

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;

class MusicPickerScreen extends StatefulWidget {
  const MusicPickerScreen({super.key});

  @override
  State<MusicPickerScreen> createState() => _MusicPickerScreenState();
}

class _MusicPickerScreenState extends State<MusicPickerScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  List<Map<String, dynamic>> _results = [];
  Map<String, dynamic>? _selectedTrack; // {id,title,artist,preview,cover}
  final AudioPlayer _player = AudioPlayer();
  bool isPlaying = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSelectedTrack();
    _searchController.addListener(_onSearchChanged);
    // Load default tracks on startup
    _loadDefaultTracks();
  }

  Future<void> _saveSelectedTrack(Map<String, dynamic> track) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_track_title', track['title'] ?? '');
    await prefs.setString('selected_track_artist', track['artist'] ?? '');
    await prefs.setString('selected_track_preview', track['preview'] ?? '');
    await prefs.setString('selected_track_cover', track['cover'] ?? '');
  }

  Future<void> _loadSelectedTrack() async {
    final prefs = await SharedPreferences.getInstance();
    final title = prefs.getString('selected_track_title');
    final artist = prefs.getString('selected_track_artist');
    final preview = prefs.getString('selected_track_preview');
    final cover = prefs.getString('selected_track_cover');
    if ((title ?? '').isNotEmpty && (artist ?? '').isNotEmpty) {
      setState(() {
        _selectedTrack = {
          'title': title,
          'artist': artist,
          'preview': preview,
          'cover': cover,
        };
      });
    }
  }

  Future<void> playPreview(String url) async {
    await _player.stop();
    if (url.isNotEmpty) {
      await _player.play(UrlSource(url));
      setState(() => isPlaying = true);
    }
  }

  Future<void> stopMusic() async {
    await _player.stop();
    setState(() => isPlaying = false);
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  void confirmSelection() async {
    if (_selectedTrack != null) {
      await _saveSelectedTrack(_selectedTrack!);
      Navigator.pop(context, _selectedTrack);
    } else {
      Navigator.pop(context);
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final q = _searchController.text.trim();
      if (q.isNotEmpty) {
        _searchDeezer(q);
      } else {
        // If search is empty, show default tracks
        _loadDefaultTracks();
      }
    });
  }

  Future<void> _loadDefaultTracks() async {
    // Load popular tracks from Deezer
    await _searchDeezer('popular music');
  }

  Future<void> _searchDeezer(String query) async {
    setState(() => _isLoading = true);
    try {
      final uri = Uri.parse('https://api.deezer.com/search?q=${Uri.encodeComponent(query)}');
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        final List list = (data['data'] as List? ?? []);
        final mapped = list.map<Map<String, dynamic>>((item) {
          final Map<String, dynamic> artist = item['artist'] ?? {};
          final Map<String, dynamic> album = item['album'] ?? {};
          return {
            'id': item['id']?.toString() ?? '',
            'title': item['title'] ?? '',
            'artist': artist['name'] ?? '',
            'preview': item['preview'] ?? '',
            'cover': album['cover_medium'] ?? album['cover'] ?? '',
          };
        }).where((e) => (e['preview'] as String).isNotEmpty).toList();
        setState(() => _results = mapped);
      }
    } catch (e) {
      print('Deezer API error: $e');
      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Musiqi yüklənə bilmədi. İnternet bağlantısını yoxlayın.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF191414), Color(0xFF1DB954)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Musiqi Seç', style: TextStyle(color: Color(0xFF1DB954), fontWeight: FontWeight.bold)),
          iconTheme: const IconThemeData(color: Color(0xFF1DB954)),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Deezer-də axtar...',
                  hintStyle: const TextStyle(color: Colors.white70),
                  prefixIcon: const Icon(Icons.search, color: Colors.white70),
                  filled: true,
                  fillColor: Colors.black.withOpacity(0.3),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF1DB954),
                      ),
                    )
                  : _results.isEmpty
                      ? const Center(
                          child: Text(
                            'Musiqi tapılmadı',
                            style: TextStyle(color: Colors.white70, fontSize: 16),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _results.length,
                          itemBuilder: (context, index) {
                            final item = _results[index];
                            final bool isSelected = _selectedTrack != null && _selectedTrack!['preview'] == item['preview'];
                            return Card(
                              color: Colors.black.withOpacity(0.7),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.green.withOpacity(0.2),
                                  backgroundImage: (item['cover'] as String).isNotEmpty ? NetworkImage(item['cover']) : null,
                                  child: (item['cover'] as String).isEmpty ? const Icon(Icons.music_note, color: Colors.white) : null,
                                ),
                                title: Text(item['title'] ?? '', style: const TextStyle(color: Colors.white)),
                                subtitle: Text(item['artist'] ?? '', style: const TextStyle(color: Colors.white70)),
                                trailing: IconButton(
                                  icon: Icon(isPlaying && isSelected ? Icons.stop : Icons.play_arrow, color: Colors.white),
                                  onPressed: () {
                                    if (isPlaying && isSelected) {
                                      stopMusic();
                                    } else {
                                      playPreview(item['preview'] ?? '');
                                      setState(() => _selectedTrack = item);
                                    }
                                  },
                                ),
                                onTap: () {
                                  setState(() => _selectedTrack = item);
                                },
                              ),
                            );
                          },
                        ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check, color: Color(0xFF1DB954)),
                label: const Text('Seç və çıx', style: TextStyle(color: Color(0xFF1DB954))),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: confirmSelection,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

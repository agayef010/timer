import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mads/screen/background_picker.dart';
// ignore: duplicate_import
import 'background_picker.dart';
import 'music_picker.dart';
import 'package:audioplayers/audioplayers.dart';
// ignore: unused_import
import 'package:shared_preferences/shared_preferences.dart';
import 'setting_screen.dart';
// ignore: unused_import
import 'dart:math';
import 'package:webview_flutter/webview_flutter.dart';



class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  static const int workDuration = 25 * 60;
  int remainingSeconds = workDuration;
  bool isRunning = false;
  Timer? timer;
  String backgroundImage = 'assets/images/sekil1.jpg';
  final AudioPlayer _player = AudioPlayer();
  bool isMusicPlaying = false;
  late AnimationController _iconController;
  String? userNote;
  List<Map<String, String>> notes = [];
  bool showNotes = false;

  // Deezer-selected track data
  String? selectedTitle;
  String? selectedArtist;
  String? selectedPreview;
  String? selectedCover;

  // Spotify mini player (search view) controller
  WebViewController? _spotifyController;

  @override
  void initState() {
    super.initState();
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _loadPrefs();
    _loadUserNote();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      backgroundImage = prefs.getString('background_image') ?? backgroundImage;
      selectedTitle = prefs.getString('selected_track_title');
      selectedArtist = prefs.getString('selected_track_artist');
      selectedPreview = prefs.getString('selected_track_preview');
      selectedCover = prefs.getString('selected_track_cover');
    });
    _initSpotifyWebView();
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('background_image', backgroundImage);
  }

  Future<void> _playPreviewUrl(String url) async {
    await _player.stop();
    if (url.isNotEmpty) {
      await _player.play(UrlSource(url));
      setState(() => isMusicPlaying = true);
      _iconController.forward();
    }
  }

  Future<void> _stopMusic() async {
    await _player.stop();
    setState(() => isMusicPlaying = false);
  }

  void startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (remainingSeconds > 0) {
        setState(() => remainingSeconds--);
      } else {
        stopTimer();
      }
    });
    setState(() => isRunning = true);
  }

  void stopTimer() {
    timer?.cancel();
    setState(() => isRunning = false);
  }

  void resetTimer() {
    stopTimer();
    setState(() => remainingSeconds = workDuration);
  }

  String formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  @override
  void dispose() {
    timer?.cancel();
    _player.dispose();
    _iconController.dispose();
    super.dispose();
  }

  void _pauseCurrentTrack() {
    _stopMusic();
    setState(() => isMusicPlaying = false);
    _iconController.reverse();
  }

  void _initSpotifyWebView() {
    final queryParts = <String>[];
    if ((selectedTitle ?? '').isNotEmpty) queryParts.add(selectedTitle!);
    if ((selectedArtist ?? '').isNotEmpty) queryParts.add(selectedArtist!);
    final query = queryParts.join(' ');
    if (query.isEmpty) {
      _spotifyController = null;
      return;
    }
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..loadRequest(Uri.parse('https://open.spotify.com/search/${Uri.encodeComponent(query)}'));
    _spotifyController = controller;
  }

  Widget _spotifyStylePlayer() {
    final String title = selectedTitle ?? 'Seçilmiş musiqi yoxdur';
    final String artist = selectedArtist ?? '';
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(left: 8, right: 8, bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.92),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      width: MediaQuery.of(context).size.width - 16,
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF1DB954), Color(0xFF191414)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: selectedCover != null && (selectedCover!.isNotEmpty)
                ? ClipOval(child: Image.network(selectedCover!, fit: BoxFit.cover))
                : const Icon(Icons.music_note, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  artist,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 64,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _spotifyController != null
                        ? IgnorePointer(
                            child: Opacity(
                              opacity: 0.95,
                              child: WebViewWidget(controller: _spotifyController!),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: Icon(
              isMusicPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
              color: Colors.green,
              size: 32,
            ),
            onPressed: () {
              if (isMusicPlaying) {
                _pauseCurrentTrack();
              } else {
                if ((selectedPreview ?? '').isNotEmpty) {
                  _playPreviewUrl(selectedPreview!);
                }
              }
            },
            splashRadius: 24,
          ),
        ],
      ),
    );
  }

  void _showDurationPicker() async {
    int? selected = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF191414),
          title: const Text('Vaxt seç', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _durationOption(25),
              _durationOption(40),
              _durationOption(60),
            ],
          ),
        );
      },
    );
    if (selected != null) {
      setState(() {
        remainingSeconds = selected * 60;
      });
    }
  }

  Widget _durationOption(int min) {
    return ListTile(
      title: Text('$min dəqiqə', style: const TextStyle(color: Colors.white)),
      onTap: () => Navigator.of(context).pop(min),
    );
  }

  Future<void> _showNoteDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF191414),
          title: const Text('Not yaz', style: TextStyle(color: Color(0xFF1DB954))),
          content: TextField(
            controller: controller,
            maxLines: 4,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Buraya notunuzu yazın...',
              hintStyle: TextStyle(color: Colors.white54),
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.black26,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Bağla', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1DB954),
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('Yadda saxla'),
            ),
          ],
        );
      },
    );
    if (result != null && result.trim().isNotEmpty) {
      final now = DateTime.now();
      final note = {
        'text': result.trim(),
        'date': '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
      };
      setState(() {
        notes.add(note);
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('notes_json', notes.map((n) => '${n['text']}||${n['date']}').join('##'));
    }
  }

  Future<void> _loadUserNote() async {
    final prefs = await SharedPreferences.getInstance();
    final notesRaw = prefs.getString('notes_json');
    if (notesRaw != null && notesRaw.isNotEmpty) {
      notes = notesRaw.split('##').map((e) {
        final parts = e.split('||');
        return {'text': parts[0], 'date': parts.length > 1 ? parts[1] : ''};
      }).toList();
    } else {
      notes = [];
    }
    setState(() {});
  }

  void _toggleShowNotes() {
    setState(() {
      showNotes = !showNotes;
    });
  }

  Future<void> _editNoteDialog(int index) async {
    final controller = TextEditingController(text: notes[index]['text']);
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF191414),
          title: const Text('Notu redaktə et', style: TextStyle(color: Color(0xFF1DB954))),
          content: TextField(
            controller: controller,
            maxLines: 4,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Notu dəyiş...',
              hintStyle: TextStyle(color: Colors.white54),
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.black26,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Bağla', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1DB954),
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('Yadda saxla'),
            ),
          ],
        );
      },
    );
    if (result != null && result.trim().isNotEmpty) {
      setState(() {
        notes[index]['text'] = result.trim();
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('notes_json', notes.map((n) => '${n['text']}||${n['date']}').join('##'));
    }
  }

  Future<void> _deleteNote(int index) async {
    setState(() {
      notes.removeAt(index);
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('notes_json', notes.map((n) => '${n['text']}||${n['date']}').join('##'));
  }

  @override
  Widget build(BuildContext context) {
    double progress = 1 - remainingSeconds / workDuration;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Graham Timer'),
        backgroundColor: const Color(0xFF191414),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Color(0xFF1DB954)),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingScreen()),
              );
              if (result is Map) {
                setState(() {
                  if (result['background'] != null) backgroundImage = result['background'];
                });
                _savePrefs();
              }
            },
          ),
        ],
      ),
      backgroundColor: const Color(0xFF121212),
      drawer: Drawer(
        backgroundColor: const Color(0xFF191414),
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Color(0xFF1DB954),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Center(
                child: Text(
                  'Ayarlar',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            ListTile(
              title: const Text('Arxa fonu seç', style: TextStyle(color: Colors.white)),
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const BackgroundPickerScreen()),
                );
                if (result is String && result.isNotEmpty) {
                  setState(() {
                    backgroundImage = result;
                  });
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('background_image', result);
                }
              },
            ),
            ListTile(
              title: const Text('Musiqi seç', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MusicPickerScreen()),
                ).then((value) async {
                  await _loadPrefs();
                  setState(() {});
                });
              },
            ),
            ListTile(
              title: const Text('Not yaz', style: TextStyle(color: Colors.white)),
              onTap: _showNoteDialog,
              leading: const Icon(Icons.note, color: Color(0xFF1DB954)),
            ),
            ListTile(
              title: const Text('Notlara bax', style: TextStyle(color: Colors.white)),
              leading: const Icon(Icons.sticky_note_2, color: Color(0xFF1DB954)),
              onTap: _toggleShowNotes,
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: showNotes
                  ? Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: notes.isEmpty
                          ? const Text('Heç bir not yoxdur.', style: TextStyle(color: Colors.white70))
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ...notes.asMap().entries.map((entry) {
                                  final i = entry.key;
                                  final n = entry.value;
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                    margin: const EdgeInsets.symmetric(vertical: 6),
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Icon(Icons.circle, size: 8, color: Color(0xFF1DB954)),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                n['text'] ?? '',
                                                style: const TextStyle(color: Colors.white, fontSize: 14),
                                              ),
                                              if ((n['date'] ?? '').isNotEmpty)
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 2.0),
                                                  child: Text(
                                                    n['date']!,
                                                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.edit, color: Colors.white70, size: 18),
                                          tooltip: 'Redaktə et',
                                          onPressed: () => _editNoteDialog(i),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.redAccent, size: 18),
                                          tooltip: 'Sil',
                                          onPressed: () => _deleteNote(i),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                    )
                  : const SizedBox.shrink(),
            ),
            const Spacer(),
            Container(
              width: double.infinity,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(Icons.favorite, color: Colors.white.withOpacity(0.7), size: 18),
                  const SizedBox(width: 8),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 400),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 1.2,
                      fontFamily: 'Montserrat',
                    ),
                    child: const Text('agayeff'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 600),
            child: Image.asset(
              backgroundImage,
              key: ValueKey(backgroundImage),
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              alignment: Alignment.center,
            ),
          ),
          Container(color: Colors.black.withOpacity(0.5)),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 400),
                style: const TextStyle(
                  fontSize: 32,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
                child: const Text(' Timer'),
              ),
              const SizedBox(height: 40),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 200,
                    height: 200,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: progress),
                      duration: const Duration(milliseconds: 600),
                      builder: (context, value, child) {
                        return CircularProgressIndicator(
                          value: value,
                          strokeWidth: 12,
                          color: Colors.green,
                          backgroundColor: Colors.white24,
                        );
                      },
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: Text(
                      formatTime(remainingSeconds),
                      key: ValueKey(remainingSeconds),
                      style: const TextStyle(
                        fontSize: 40,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1DB954),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                    onPressed: isRunning ? stopTimer : startTimer,
                    child: Text(isRunning ? 'Dayandır' : 'Başlat'),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white10,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                    onPressed: resetTimer,
                    child: const Text('Reset'),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF191414),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    ),
                    onPressed: _showDurationPicker,
                    child: const Text('Vaxtı seç'),
                  ),
                ],
              ),
            ],
          ),
          // Spotify stilində player sağ aşağıda
          Positioned(
            right: 0,
            bottom: 0,
            child: _spotifyStylePlayer(),
          ),
        ],
      ),
    );
  }
}

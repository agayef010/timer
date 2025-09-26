import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';

class SettingScreen extends StatefulWidget {
  static const List<String> backgrounds = [
    'assets/images/sekil1.jpg',
    'assets/images/sekil2.jpg',
    'assets/images/sekil3.jpg',
    'assets/images/sekil4.jpg',
    'assets/images/sekil5.jpg',
    'assets/images/sekil6.jpg',
    'assets/images/sekil7.jpg',
    'assets/images/sekil8.jpg',
    'assets/images/sekil9.jpg',
    'assets/images/sekil10.jpg',
  ];
  static const List<String> musics = [
    
  ];

  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  String? selectedBackground;
  String? selectedMusic;
  final AudioPlayer _player = AudioPlayer();
  bool isPlaying = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedBackground = prefs.getString('background_image') ?? SettingScreen.backgrounds[0];
      selectedMusic = prefs.getString('selected_music') ?? SettingScreen.musics[0];
    });
  }

  Future<void> _saveBackground(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('background_image', path);
    setState(() => selectedBackground = path);
  }

  Future<void> _saveMusic(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_music', path);
    setState(() => selectedMusic = path);
  }

  Future<void> _playMusic(String path) async {
    await _player.stop();
    await _player.play(AssetSource(path.replaceFirst('assets/', '')));
    setState(() => isPlaying = true);
  }

  Future<void> _stopMusic() async {
    await _player.stop();
    setState(() => isPlaying = false);
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
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
          title: const Text('Ayarlar', style: TextStyle(color: Color(0xFF1DB954), fontWeight: FontWeight.bold)),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.check, color: Color(0xFF1DB954)),
              onPressed: () {
                Navigator.pop(context, {
                  'background': selectedBackground,
                  'music': selectedMusic,
                });
              },
            ),
          ],
          iconTheme: const IconThemeData(color: Color(0xFF1DB954)),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              const Text('Arxa fon seç', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 10),
              SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: SettingScreen.backgrounds.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final bg = SettingScreen.backgrounds[index];
                    return GestureDetector(
                      onTap: () async {
                        await _saveBackground(bg);
                      },
                      child: Container(
                        width: 100,
                        decoration: BoxDecoration(
                          border: Border.all(color: selectedBackground == bg ? Colors.green : Colors.grey),
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: AssetImage(bg),
                            fit: BoxFit.cover,
                            filterQuality: FilterQuality.high,
                          ),
                        ),
                        child: selectedBackground == bg
                            ? const Icon(Icons.check_circle, color: Colors.white)
                            : null,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 30),
              const Text('Musiqi seç', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 10),
              ...SettingScreen.musics.map((music) => Card(
                    color: Colors.black.withOpacity(0.7),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      title: Text(music.split('/').last, style: const TextStyle(color: Colors.white)),
                      leading: Icon(selectedMusic == music ? Icons.music_note : Icons.audiotrack, color: Colors.green),
                      trailing: IconButton(
                        icon: Icon(isPlaying && selectedMusic == music ? Icons.stop : Icons.play_arrow, color: Colors.white),
                        onPressed: () {
                          if (isPlaying && selectedMusic == music) {
                            _stopMusic();
                          } else {
                            _playMusic(music);
                            _saveMusic(music);
                          }
                        },
                      ),
                      onTap: () async {
                        await _saveMusic(music);
                      },
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

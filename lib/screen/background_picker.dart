// TODO Implement this library.
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BackgroundPickerScreen extends StatefulWidget {
  const BackgroundPickerScreen({super.key});

  @override
  State<BackgroundPickerScreen> createState() => _BackgroundPickerScreenState();
}

class _BackgroundPickerScreenState extends State<BackgroundPickerScreen> {
  List<String> imageList = List.generate(
    10,
    (index) => 'assets/images/sekil${index + 1}.jpg',
  );

  String? selectedImage;

  Future<void> saveSelectedImage(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('background_image', path);
  }

  Future<void> loadSelectedImage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedImage = prefs.getString('background_image');
    });
  }

  @override
  void initState() {
    super.initState();
    loadSelectedImage();
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
          title: const Text('Arxa fonu seç', style: TextStyle(color: Color(0xFF1DB954), fontWeight: FontWeight.bold)),
          iconTheme: const IconThemeData(color: Color(0xFF1DB954)),
        ),
        body: GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: imageList.length,
          itemBuilder: (context, index) {
            final imagePath = imageList[index];
            return GestureDetector(
              onTap: () async {
                await saveSelectedImage(imagePath);
                if (context.mounted) {
                  Navigator.pop(context, imagePath);
                }
              },
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: selectedImage == imagePath
                            ? Colors.green
                            : Colors.transparent,
                        width: 4,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        imagePath,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
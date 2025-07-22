import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:screenshot/screenshot.dart';

import 'image_saver_selector.dart'; // handles platform-specific saving

class ScoreImagePage extends StatefulWidget {
  const ScoreImagePage({super.key});

  @override
  State<ScoreImagePage> createState() => _ScoreImagePageState();
}

class _ScoreImagePageState extends State<ScoreImagePage> {
    final _titleController = TextEditingController();

  final _teamAController = TextEditingController();
  final _teamBController = TextEditingController();
  final _scoreAController = TextEditingController();
  final _scoreBController = TextEditingController();

  final ScreenshotController _screenshotController = ScreenshotController();

  Future<void> _saveImage() async {
    final image = await _screenshotController.capture();
    if (image != null) {
      final saver = getImageSaver(); // uses conditional import
      await saver.save(image);
      if (!kIsWeb) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Image saved")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Generate Match Image")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
                        TextField(
  controller: _titleController,
  decoration: const InputDecoration(labelText: "Title"),
  onChanged: (_) => setState(() {}),
),
            TextField(
  controller: _teamAController,
  decoration: const InputDecoration(labelText: "Team A"),
  onChanged: (_) => setState(() {}),
),
TextField(
  controller: _scoreAController,
  decoration: const InputDecoration(labelText: "Team A"),
  onChanged: (_) => setState(() {}),
),
            const SizedBox(height: 8),
TextField(
  controller: _teamBController,
  decoration: const InputDecoration(labelText: "Team B"),
  onChanged: (_) => setState(() {}),
),  
TextField(
  controller: _scoreBController,
  decoration: const InputDecoration(labelText: "Team B"),
  onChanged: (_) => setState(() {}),
),               
            const SizedBox(height: 20),
            Screenshot(
              controller: _screenshotController,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.asset('assets/template.png'), // your template
                                    Positioned(
                    top: 180,
                    
                    child: Text(
                      '${_titleController.text}',
                      style: const TextStyle(fontFamily: 'Gilroy',
    fontSize: 28, color: Color.fromARGB(255, 255, 255, 255), fontWeight: FontWeight.bold,),
                    ),
                  ),
                  Positioned(
                    top: 280,
                    
                    child: Text(
                      '${_teamAController.text} ${_scoreAController.text}',
                      style: const TextStyle(fontFamily: 'Gilroy',
    fontSize: 28, color: Color.fromARGB(255, 255, 255, 255), fontWeight: FontWeight.bold,),
                    ),
                  ),
                  Positioned(
                    top: 320,
                    child: Text(
                      '${_teamBController.text} ${_scoreBController.text}',
                      style: const TextStyle(fontFamily: 'Gilroy', fontSize: 28, color: Color.fromARGB(255, 255, 255, 255), fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveImage,
              child: const Text("Generate & Save Image"),
            ),
          ],
        ),
      ),
    );
  }
}

// lib/plant_detector_page.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';

class PlantDetectorPage extends StatefulWidget {
  const PlantDetectorPage({Key? key}) : super(key: key);

  @override
  State<PlantDetectorPage> createState() => _PlantDetectorPageState();
}

class _PlantDetectorPageState extends State<PlantDetectorPage> {
  XFile? _image;
  bool _loading = false;
  String? _result;

  Future<void> _pick() async {
    final img = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (img == null) return;
    setState(() {
      _image = img;
      _result = null;
    });
    await _analyse(img);
  }

  Future<void> _analyse(XFile img) async {
    setState(() => _loading = true);

    try {
      final bytes = await img.readAsBytes();
      final base64Img = base64Encode(bytes);
      final mime = lookupMimeType(img.path) ?? 'image/jpeg';

      final apiKey = dotenv.env['GEMINI_API_KEY'];
      final uri = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent');


      final headers = {
        'Content-Type': 'application/json',
      };

      const prompt = '''
Tu es un expert en botanique et phytopathologie.
Étape 1 : Réponds uniquement "PLANT" ou "NOT_PLANT".
Étape 2 : Si c'est une PLANT, donne 2 maladies possibles.
Réponds en français, clair et court.
''';

      final body = {
        "contents": [
          {
            "parts": [
              {"text": prompt},
              {
                "inlineData": {
                  "mimeType": mime,
                  "data": base64Img,
                }
              }
            ]
          }
        ]
      };

      final response = await http.post(uri, headers: headers, body: jsonEncode(body));
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final text = data['candidates'][0]['content']['parts'][0]['text'];
        setState(() => _result = text.trim());
      } else {
        setState(() => _result = 'Erreur API : ${data['error'] ?? response.body}');
      }
    } catch (e) {
      setState(() => _result = 'Erreur réseau : $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Détecteur de maladies')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_image != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(File(_image!.path), height: 220),
              ),
            const SizedBox(height: 16),
            _loading
                ? const CircularProgressIndicator()
                : _result != null
                    ? Text(
                        _result!,
                        style: const TextStyle(fontSize: 16),
                      )
                    : const Text(
                        'Appuie sur le bouton pour choisir une image.',
                        textAlign: TextAlign.center,
                      ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _loading ? null : _pick,
              icon: const Icon(Icons.photo),
              label: const Text('Choisir une image'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

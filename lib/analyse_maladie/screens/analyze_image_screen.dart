import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:robotic_app/shared/colors.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/image_analysis_service.dart';
import '../models/diagnostic_model.dart';
import 'image_preview_screen.dart';

class AnalyzeImageScreen extends StatefulWidget {
  const AnalyzeImageScreen({Key? key}) : super(key: key);

  @override
  _AnalyzeImageScreenState createState() => _AnalyzeImageScreenState();
}

class _AnalyzeImageScreenState extends State<AnalyzeImageScreen> with TickerProviderStateMixin {
  DiagnosticModel? diagnostic;
  bool isLoading = false;
  String? errorMessage;
  File? selectedImageFile;

  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> pickImageFromGallery() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        selectedImageFile = File(pickedFile.path);
      });
      await analyzeSelectedImage();
    }
  }

  Future<void> takePhotoWithCamera() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        selectedImageFile = File(pickedFile.path);
      });
      await analyzeSelectedImage();
    }
  }

  Future<void> analyzeSelectedImage() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
        diagnostic = null;
      });

      if (selectedImageFile == null) {
        throw Exception('Aucune image sélectionnée');
      }

      final bytes = await selectedImageFile!.readAsBytes();
      final base64Image = base64Encode(bytes);

      final result = await ImageAnalysisService.analyzePlantImage(base64Image);

      setState(() {
        diagnostic = result;
        isLoading = false;
      });

      _controller.forward();
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  Future<void> searchOnGoogle(String query) async {
    final url = Uri.parse('https://www.google.com/search?q=${Uri.encodeComponent(query)}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Impossible d\'ouvrir $url';
    }
  }

  Color getRiskColor(double probability) {
    if (probability >= 0.7) {
      return Colors.red;
    } else if (probability >= 0.4) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  String getRiskLabel(double probability) {
    if (probability >= 0.7) {
      return 'Haut risque';
    } else if (probability >= 0.4) {
      return 'Risque moyen';
    } else {
      return 'Faible risque';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
       appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          "Analyse d'image",
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 19),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (selectedImageFile != null)
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ImagePreviewScreen(
                        imageProvider: FileImage(selectedImageFile!),
                      ),
                    ),
                  );
                },
                child: Hero(
                  tag: 'selectedImage',
                  child: Container(
                    height: 250,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: FileImage(selectedImageFile!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              )
            else
              Container(
                height: 250,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text('Aucune image sélectionnée'),
                ),
              ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(mainColor),
                  ),
                  onPressed: pickImageFromGallery,
                  icon: const Icon(Icons.photo,color: Colors.white,),
                  label: const Text('Galerie', style: TextStyle(color: Colors.white),),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                   style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(mainColor),
                  ),
                  onPressed: takePhotoWithCamera,
                  icon: const Icon(Icons.camera_alt,color: Colors.white,),
                  label: const Text('Caméra', style: TextStyle(color: Colors.white),),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (isLoading) const CircularProgressIndicator(),
            if (errorMessage != null)
              Text(
                'Erreur : $errorMessage',
                style: const TextStyle(color: Colors.red),
              ),
            if (diagnostic != null)
              FadeTransition(
                opacity: _animation,
                child: Column(
                  children: diagnostic!.suggestions.map((suggestion) {
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              suggestion.plantName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  'Probabilité : ${(suggestion.probability * 100).toStringAsFixed(2)}%',
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: getRiskColor(suggestion.probability),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    getRiskLabel(suggestion.probability),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => searchOnGoogle('${suggestion.plantName} plant disease'),
                                child: const Text(
                                  'Rechercher sur Google',
                                  style: TextStyle(color: Colors.blue),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

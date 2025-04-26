import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:quickalert/quickalert.dart';

import '../shared/colors.dart';

class AddQuestionPage extends StatefulWidget {
  const AddQuestionPage({Key? key}) : super(key: key);

  @override
  State<AddQuestionPage> createState() => _AddQuestionPageState();
}

class _AddQuestionPageState extends State<AddQuestionPage> {
  File? _pickedImage;
  final TextEditingController _questionController = TextEditingController();
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _pickedImage = File(picked.path));
    }
  }

  Future<void> _submitQuestion() async {
    final questionText = _questionController.text.trim();
    if (questionText.isEmpty || _pickedImage == null) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        title: 'Erreur',
        text: 'Veuillez choisir une image et saisir la question.',
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Récupérer l'utilisateur
      final user = FirebaseAuth.instance.currentUser!;
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final nom = userDoc['nom'] as String;
      final prenom = userDoc['prenom'] as String;


      final storageRef = FirebaseStorage.instance
          .ref()
          .child('questionImages/${DateTime.now().millisecondsSinceEpoch}');
      await storageRef.putFile(_pickedImage!);
      final imageUrl = await storageRef.getDownloadURL();


      await FirebaseFirestore.instance.collection('question').add({
        'nom': nom,
        'prenom': prenom,
        'userId': user.uid,
        'image': imageUrl,
        'question': questionText,
        'timestamp': FieldValue.serverTimestamp(),
      });

      QuickAlert.show(
        context: context,
        type: QuickAlertType.success,
        text: 'Question postée avec succès !',
      );

      // Réinitialiser le formulaire
      setState(() {
        _pickedImage = null;
        _questionController.clear();
      });
    } catch (e) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        title: 'Erreur',
        text: 'Impossible de poster la question.',
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          "Ajouter une question",
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 19),
        ),
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Gap(30),
             Container(
  decoration: BoxDecoration(
    border: Border.all(color: mainColor, width: 2),
    borderRadius: BorderRadius.circular(16),
  ),
  padding: const EdgeInsets.all(12),
  child: GestureDetector(
    onTap: _pickImage,
    child: SizedBox(
      height: 220,
      child: _pickedImage == null
          // si pas d'image, on affiche une icône de chargement centrée
          ? Center(
              child: Icon(
                Icons.cloud_upload,
                color: mainColor,
                size: 40,
              ),
            )
          // sinon on affiche l'image sélectionnée, couvrant tout l'espace
          : ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                _pickedImage!,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
    ),
  ),
),
const SizedBox(height: 20),

              // Question input container
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: mainColor, width: 2),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ajouter Votre question',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _questionController,
                      maxLines: 6,
                      decoration: InputDecoration(
                        hintText: 'Ecriez votre question...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 12),
                      ),
                    ),
                  ],
                ),
              ),
              Spacer(),

             
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitQuestion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mainColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? LoadingAnimationWidget.staggeredDotsWave(
                          color: Colors.white, size: 32)
                      : const Text(
                          'Add your question',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const Gap(20),
            ],
          ),
        ),
      ),
    );
  }
}

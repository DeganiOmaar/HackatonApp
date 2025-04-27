import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import 'case_model.dart';

class AddCaseScreen extends StatefulWidget {
  final String userRole;
  final String userLocalisation;

  const AddCaseScreen({
    Key? key,
    required this.userRole,
    required this.userLocalisation,
  }) : super(key: key);

  @override
  State<AddCaseScreen> createState() => _AddCaseScreenState();
}

class _AddCaseScreenState extends State<AddCaseScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  XFile? _pickedImage;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _pickedImage = picked);
    }
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final desc = _descriptionController.text.trim();
    if (_pickedImage == null || title.isEmpty || desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Veuillez ajouter un titre, une image et une description.',
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      // 1. Upload de l'image
      final storageRef = FirebaseStorage.instance.ref().child(
        'cases/${const Uuid().v4()}',
      );
      UploadTask uploadTask;
      if (kIsWeb) {
        uploadTask = storageRef.putData(await _pickedImage!.readAsBytes());
      } else {
        uploadTask = storageRef.putFile(File(_pickedImage!.path));
      }
      final snap = await uploadTask;
      final imageUrl = await snap.ref.getDownloadURL();

      // 2. Récupération latitude/longitude depuis localisation
      double? latitude;
      double? longitude;
      try {
        final locations = await locationFromAddress(widget.userLocalisation);
        if (locations.isNotEmpty) {
          latitude = locations.first.latitude;
          longitude = locations.first.longitude;
        }
      } catch (e) {
        debugPrint('Erreur lors de la géolocalisation : $e');
      }

      // 3. Création du cas
      final caseId = const Uuid().v4();
      final newCase = CaseModel(
        id: caseId,
        title: title,
        imageUrl: imageUrl,
        description: desc,
        role: widget.userRole.toLowerCase(),
        localisation: widget.userLocalisation.toLowerCase(),
        createdAt: DateTime.now(),
        latitude: latitude,
        longitude: longitude,
        likes: 0, // ✅ Ajout ici obligatoire
      );

      // 4. Sauvegarde du cas
      await FirebaseFirestore.instance.collection('cases').doc(caseId).set({
        ...newCase.toMap(),
        'userId': uid,
      });

      // 5. Ajout aussi dans la sous-collection utilisateur
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('cases')
          .doc(caseId)
          .set({...newCase.toMap(), 'userId': uid});

      // 6. Récupération des infos de l'utilisateur pour la notification
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final userData = userDoc.data() ?? {};
      final nom = userData['nom'] ?? '';
      final prenom = userData['prenom'] ?? '';

      // 7. Enregistrement de la notification
      await FirebaseFirestore.instance.collection('notifications').add({
        'title': title,
        'content': desc,
        'date': FieldValue.serverTimestamp(),
        'role': widget.userRole,
        'nom': nom,
        'prenom': prenom,
        'userId': uid,
        'caseId': caseId,
        'imageUrl': imageUrl,
        'latitude': latitude,
        'longitude': longitude,
      });

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur : $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Partager un Cas'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Titre du cas...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey),
                ),
                child:
                    _pickedImage != null
                        ? ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child:
                              kIsWeb
                                  ? Image.network(
                                    _pickedImage!.path,
                                    fit: BoxFit.cover,
                                  )
                                  : Image.file(
                                    File(_pickedImage!.path),
                                    fit: BoxFit.cover,
                                  ),
                        )
                        : const Center(
                          child: Icon(
                            Icons.add_a_photo,
                            size: 50,
                            color: Colors.grey,
                          ),
                        ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Description du problème...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child:
                  _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                        'Partager',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}

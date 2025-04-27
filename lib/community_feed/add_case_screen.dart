import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

import 'case_model.dart';
import 'case_service.dart';

class AddCaseScreen extends StatefulWidget {
  final String userRole;
  final String userLocalisation;

  const AddCaseScreen({Key? key, required this.userRole, required this.userLocalisation}) : super(key: key);

  @override
  State<AddCaseScreen> createState() => _AddCaseScreenState();
}

class _AddCaseScreenState extends State<AddCaseScreen> {
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
    if (_pickedImage == null || _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez ajouter une image et une description.')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final ref = FirebaseStorage.instance.ref().child('cases/${const Uuid().v4()}');
      UploadTask uploadTask;

      if (kIsWeb) {
        uploadTask = ref.putData(await _pickedImage!.readAsBytes());
      } else {
        uploadTask = ref.putFile(File(_pickedImage!.path));
      }

      final snapshot = await uploadTask;
      final imageUrl = await snapshot.ref.getDownloadURL();

      final newCase = CaseModel(
        id: const Uuid().v4(),
        imageUrl: imageUrl,
        description: _descriptionController.text.trim(),
        role: widget.userRole.trim().toLowerCase(), // ⬆️ Force lowercase
        localisation: widget.userLocalisation.trim().toLowerCase(), // ⬆️ Force lowercase
        createdAt: DateTime.now(),
      );

      await CaseService.addCase(newCase);

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Partager un Cas'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey),
                ),
                child: _pickedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: kIsWeb
                            ? Image.network(_pickedImage!.path, fit: BoxFit.cover)
                            : Image.file(File(_pickedImage!.path), fit: BoxFit.cover),
                      )
                    : const Center(child: Icon(Icons.add_a_photo, size: 50, color: Colors.grey)),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _descriptionController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Description du problème...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Partager', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

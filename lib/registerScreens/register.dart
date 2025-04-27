import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:get/get.dart';
import 'package:quickalert/quickalert.dart';
import 'package:robotic_app/registerScreens/login.dart';
import 'package:robotic_app/registerScreens/registertextfield.dart';
import 'package:robotic_app/screens/screens.dart';
import '../../shared/colors.dart';
import 'package:geocoding/geocoding.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  bool isPasswordVisible = true;
  bool isLoading = false;

  final nomController = TextEditingController();
  final prenomController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  File? selectedImage;
  String? selectedRole;
  String? detectedCity;

  @override
  void initState() {
    super.initState();
    _detectCity();
  }

  Future<void> _detectCity() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      setState(() {
        detectedCity = placemarks.first.locality ?? placemarks.first.subAdministrativeArea;
      });
    } catch (e) {
      debugPrint('Erreur détection localisation : $e');
    }
  }

  Future<void> pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => selectedImage = File(picked.path));
    }
  }

  Future<String?> uploadImage() async {
    if (selectedImage == null) return null;
    final ref = FirebaseStorage.instance
        .ref()
        .child('userImages/${DateTime.now().millisecondsSinceEpoch}');
    await ref.putFile(selectedImage!);
    return ref.getDownloadURL();
  }

  Future<void> register() async {
    if (selectedImage == null || selectedRole == null || detectedCity == null) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        title: 'Erreur',
        text: 'Veuillez choisir une image, un rôle et attendre la localisation',
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );
      final fcmTooken = await FirebaseMessaging.instance.getToken();
      final imgUrl = await uploadImage();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(cred.user!.uid)
          .set({
        'nom': nomController.text.trim(),
        'prenom': prenomController.text.trim(),
        'email': emailController.text.trim(),
        'password': passwordController.text,
        'localisation': detectedCity,
        'uid': cred.user!.uid,
        'image': imgUrl,
        'role': selectedRole,
        'experience': '',
        'materiels': '',
        //'token' : fcmTooken,
      });

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Screens()),
      );
    } on FirebaseAuthException catch (e) {
      final msg = e.code == 'weak-password'
          ? 'Mot de passe trop faible'
          : e.code == 'email-already-in-use'
              ? 'Cet email est déjà utilisé'
              : 'Erreur : ${e.message}';
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        title: 'Échec',
        text: msg,
      );
    } catch (_) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        title: 'Oops...',
        text: 'Une erreur est survenue, réessayez.',
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Widget _buildPasswordField(String hint, TextEditingController ctrl) {
    return TextFormField(
      controller: ctrl,
      obscureText: isPasswordVisible,
      validator: (v) => v!.length < 6 ? 'Au moins 6 caractères' : null,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(CupertinoIcons.lock, size: 22),
        suffixIcon: GestureDetector(
          onTap: () =>
              setState(() => isPasswordVisible = !isPasswordVisible),
          child: Icon(
            isPasswordVisible
                ? CupertinoIcons.eye
                : CupertinoIcons.eye_slash,
            size: 22,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: const BorderSide(color: Colors.black54),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: const BorderSide(color: Colors.black),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 40),
                const Text(
                  'Inscription',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Rejoignez notre communauté en quelques étapes simples.',
                  style: TextStyle(color: Colors.black),
                ),
                const SizedBox(height: 40),
                // Avatar
                Center(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: selectedImage != null
                            ? FileImage(selectedImage!)
                            : null,
                        child: selectedImage == null
                            ? SvgPicture.asset(
                                'assets/img/avtr.svg',
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: -4,
                        right: -4,
                        child: InkWell(
                          onTap: pickImage,
                          child: Container(
                            decoration: BoxDecoration(
                              color: mainColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            padding: const EdgeInsets.all(6),
                            child: const Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                // Nom & Prénom
                Row(
                  children: [
                    Expanded(
                      child: RegistrationTextField(
                        icon: CupertinoIcons.person,
                        text: 'Nom',
                        controller: nomController,
                        validator: (v) =>
                            v!.isEmpty ? 'Entrez un nom valide' : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: RegistrationTextField(
                        icon: CupertinoIcons.person,
                        text: 'Prénom',
                        controller: prenomController,
                        validator: (v) =>
                            v!.isEmpty ? 'Entrez un prénom valide' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                // Rôle
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black54),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: DropdownButton<String>(
                    value: selectedRole,
                    hint: const Text('Choisissez votre rôle'),
                    isExpanded: true,
                    underline: const SizedBox(),
                    icon: const Icon(Icons.arrow_drop_down, size: 24),
                    onChanged: (v) => setState(() => selectedRole = v),
                    items: [
                      'Fruit', 'Légumineuses', 'Oliviers', 'Blé', 'Pommes de terre',
                    ].map((role) {
                      return DropdownMenuItem(
                        value: role,
                        child: Text(role),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 30),
                // Localisation automatique
                TextFormField(
                  readOnly: true,
                  controller: TextEditingController(text: detectedCity),
                  validator: (_) => detectedCity == null
                      ? 'Localisation requise'
                      : null,
                  decoration: InputDecoration(
                    hintText:
                        detectedCity == null ? 'Chargement localisation...' : null,
                    prefixIcon: const Icon(CupertinoIcons.location_solid),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: const BorderSide(color: Colors.black54),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: const BorderSide(color: Colors.black),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                // Email
                RegistrationTextField(
                  icon: CupertinoIcons.mail,
                  text: 'Email',
                  controller: emailController,
                validator:
                      (email) =>
                          email!.contains(
                                RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$"),
                              )
                              ? null
                              : "Entrez un email valide",
                ),
                const SizedBox(height: 30),
                // Mot de passe
                _buildPasswordField('Mot de passe', passwordController),
                const SizedBox(height: 30),
                _buildPasswordField('Confirmer mot de passe', confirmPasswordController),
                const SizedBox(height: 30),
                // Bouton Enregistrer
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: mainColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: isLoading
                        ? LoadingAnimationWidget.staggeredDotsWave(
                            color: Colors.white, size: 24)
                        : const Text(
                            'Enregistrer',
                            style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                // Lien vers la page de connexion
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Vous avez un compte ?'),
                    TextButton(
                      onPressed: () => Get.off(
                        () => const LoginPage(),
                        transition: Transition.upToDown,
                      ),
                      child: const Text(
                        "S'identifier",
                        style: TextStyle(
                            color: mainColor, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

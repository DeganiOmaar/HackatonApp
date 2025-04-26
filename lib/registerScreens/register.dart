import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:get/get.dart';
import 'package:quickalert/quickalert.dart';
import 'package:robotic_app/registerScreens/login.dart';
import 'package:robotic_app/registerScreens/registertextfield.dart';
import 'package:robotic_app/screens/screens.dart';
import '../../shared/colors.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

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
  final locationController = TextEditingController();

  File? selectedImage;
  String? selectedRole;

  Future<void> pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => selectedImage = File(picked.path));
    }
  }

  Future<String?> uploadImage() async {
    if (selectedImage == null) return null;
    final ref = FirebaseStorage.instance.ref().child(
      'userImages/${DateTime.now().millisecondsSinceEpoch}',
    );
    await ref.putFile(selectedImage!);
    return ref.getDownloadURL();
  }

  Future<void> register() async {
    if (selectedImage == null || selectedRole == null) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        title: 'Erreur',
        text: 'Veuillez choisir une image et un rôle',
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
      final imgUrl = await uploadImage();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(cred.user!.uid)
          .set({
            "nom": nomController.text.trim(),
            "prenom": prenomController.text.trim(),
            "email": emailController.text.trim(),
            "password": passwordController.text,
            "localisation" : locationController.text,
            "uid": cred.user!.uid,
            "image": imgUrl,
            "role": selectedRole,
          });

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Screens()),
      );
    } on FirebaseAuthException catch (e) {
      final msg =
          e.code == 'weak-password'
              ? 'Mot de passe trop faible'
              : e.code == 'email-already-in-use'
              ? 'Cet email est déjà utilisé'
              : 'Erreur : ${e.message}';
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
                  "Inscription",
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                const Text(
                  "Rejoignez notre communauté en quelques étapes simples.",
                  style: TextStyle(color: Colors.black),
                ),
                const SizedBox(height: 40),

                // -- AVATAR + ICON +
                Center(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[200],
                        // si une image a été sélectionnée, on l’affiche
                        backgroundImage:
                            selectedImage != null
                                ? FileImage(selectedImage!)
                                : null,
                        // sinon on tombe sur ton SVG
                        child:
                            selectedImage == null
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
                Row(
                  children: [
                    Expanded(
                      child: RegistrationTextField(
                        icon: CupertinoIcons.person,
                        text: "Nom",
                        controller: nomController,
                        validator:
                            (v) => v!.isEmpty ? "Entrez un nom valide" : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: RegistrationTextField(
                        icon: CupertinoIcons.person,
                        text: "Prénom",
                        controller: prenomController,
                        validator:
                            (v) =>
                                v!.isEmpty ? "Entrez un prénom valide" : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black54),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: DropdownButton<String>(
                    value: selectedRole,
                    hint: const Text("Choisissez votre rôle"),
                    isExpanded: true,
                    underline: const SizedBox(),
                    icon: const Icon(Icons.arrow_drop_down, size: 24),
                    onChanged: (v) => setState(() => selectedRole = v),
                    items:
                        [
                          'Fruit',
                          'Légumineuses',
                          'Oliviers',
                          'Blé',
                          'Pommes de terre',
                        ].map((role) {
                          return DropdownMenuItem(
                            value: role,
                            child: Text(role),
                          );
                        }).toList(),
                  ),
                ),
                const SizedBox(height: 30),
                RegistrationTextField(
                  icon: CupertinoIcons.mail,
                  text: "Email",
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
                  RegistrationTextField(
                  icon: CupertinoIcons.map_pin,
                  text: "Location",
                  controller: locationController,
                  validator:
                            (v) =>
                                v!.isEmpty ? "Entrez un localisation valide" : null,
                ),
                const SizedBox(height: 30),

                // -- MOT DE PASSE
                _buildPasswordField("Mot de passe", passwordController),
                const SizedBox(height: 30),
                _buildPasswordField(
                  "Confirmer mot de passe",
                  confirmPasswordController,
                ),
                const SizedBox(height: 30),

                // -- BOUTON ENREGISTRER
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
                    child:
                        isLoading
                            ? LoadingAnimationWidget.staggeredDotsWave(
                              color: Colors.white,
                              size: 24,
                            )
                            : const Text(
                              "Enregistrer",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                  ),
                ),
                const SizedBox(height: 20),

                // -- Lien vers connexion
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Vous avez un compte ?"),
                    TextButton(
                      onPressed:
                          () => Get.off(
                            () => const LoginPage(),
                            transition: Transition.upToDown,
                          ),
                      child: const Text(
                        "S'identifier",
                        style: TextStyle(
                          color: mainColor,
                          fontWeight: FontWeight.bold,
                        ),
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

  Widget _buildPasswordField(String hint, TextEditingController ctrl) {
    return TextFormField(
      controller: ctrl,
      obscureText: isPasswordVisible,
      validator: (v) => v!.length < 6 ? "Au moins 6 caractères" : null,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(CupertinoIcons.lock, size: 22),
        suffixIcon: GestureDetector(
          onTap: () => setState(() => isPasswordVisible = !isPasswordVisible),
          child: Icon(
            isPasswordVisible ? CupertinoIcons.eye : CupertinoIcons.eye_slash,
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
}

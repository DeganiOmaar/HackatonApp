import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:robotic_app/notificationpage/notifications.dart';
import 'package:robotic_app/profilepages/editprofile.dart';
import 'package:robotic_app/profilepages/profilecard.dart';
import 'package:robotic_app/registerScreens/login.dart';
import 'package:robotic_app/statistique/rendement_statistics_screen.dart';

import '../shared/colors.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  Map userData = {};
  bool isLoading = true;

  getData() async {
    setState(() {
      isLoading = true;
    });
    try {
      DocumentSnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser!.uid)
              .get();

      userData = snapshot.data()!;
    } catch (e) {
      print(e.toString());
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    getData();
  }

  void _openExperienceMaterialDialog() {
    final experienceController = TextEditingController(
      text: userData['experience'] ?? '',
    );
    final materielsController = TextEditingController(
      text: userData['materiels'] ?? '',
    );

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Text(
                        'Modifier votre expérience',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: experienceController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Expérience',
                        hintText: 'Décrivez brièvement votre expérience',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: materielsController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Matériels',
                        hintText: 'Listez vos équipements',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Annuler'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: mainColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () async {
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(FirebaseAuth.instance.currentUser!.uid)
                                .update({
                                  'experience':
                                      experienceController.text.trim(),
                                  'materiels': materielsController.text.trim(),
                                });
                            Navigator.pop(context);
                            getData();
                          },
                          child: const Text(
                            'Enregistrer',
                            style: TextStyle(color: Colors.white),
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

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: LoadingAnimationWidget.discreteCircle(
              size: 32,
              color: const Color.fromARGB(255, 16, 16, 16),
              secondRingColor: Colors.indigo,
              thirdRingColor: Colors.pink.shade400,
            ),
          ),
        )
        : Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            title: const Text(
              "Profile",
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 19),
            ),
            centerTitle: true,
            actions: [
              IconButton(onPressed: () {
                Get.to(()=>Notifications());
              }, icon: Icon(Icons.notifications, color: mainColor,)),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                Stack(
                  children: [
                    Positioned(
                      child: Container(height: 170, color: Colors.white),
                    ),

                    Positioned(
                      top: 30,
                      right: MediaQuery.of(context).size.width / 2 - 60,
                      child: Center(
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.white,
                          backgroundImage:
                              (userData['image'] != null &&
                                      userData['image'].toString().isNotEmpty)
                                  ? NetworkImage(userData['image'])
                                  : const AssetImage('assets/img/avatr.png')
                                      as ImageProvider,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  "${userData['nom']} ${userData['prenom']}",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Gap(20),
                        Row(
                          children: [
                            const Text(
                              "Type",
                              style: TextStyle(
                                fontSize: 17,
                                color: Colors.grey,
                              ),
                            ),
                            Spacer(),
                            Text(
                              userData['role'],
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                        Gap(20),
                        Row(
                          children: [
                            const Text(
                              "Email",
                              style: TextStyle(
                                fontSize: 17,
                                color: Colors.grey,
                              ),
                            ),
                            Spacer(),
                            Text(
                              userData['email'],
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                        Gap(20),
                        Divider(thickness: 1, color: Colors.grey[200]),
                        Gap(10),
                        ProfileSettingCard(
                          text: "Ajouter/Modifier Expérience & Matériels",
                          icon: CupertinoIcons.add_circled,
                          onPressed: () => _openExperienceMaterialDialog(),
                        ),
                        Gap(20),
                        ProfileSettingCard(
                          text: "Modifier votre profil",
                          icon: LineAwesomeIcons.user_edit_solid,
                          onPressed: () async {
                            Get.to(() => EditProfilePage());
                          },
                        ),
                        Gap(10),
                        ProfileSettingCard(
                          text: "Statistiques de Rendement",
                          icon: CupertinoIcons.chart_bar,
                          onPressed:
                              () => Get.to(
                                () => const RendementStatisticsScreen(),
                              ),
                        ),

                        Gap(10),
                        Gap(20),
                        ProfileSettingCard(
                          text: "Obtenir l'aide",
                          icon: CupertinoIcons.question,
                          onPressed: () {},
                        ),
                        Gap(20),
                        ProfileSettingCard(
                          text: "A propos de nous",
                          icon: CupertinoIcons.info,
                          onPressed: () {},
                        ),
                        Gap(20),
                        ProfileSettingCard(
                          text: "Supprimer le compte",
                          icon: CupertinoIcons.delete,
                          onPressed: () {},
                        ),
                        Gap(20),
                        ListTile(
                          onTap: () async {
                            await FirebaseAuth.instance.signOut();
                            if (!mounted) return;
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (context) => const LoginPage(),
                              ),
                              (route) => false,
                            );
                          },
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(100),
                              color: Colors.blue.withOpacity(0.1),
                            ),
                            child: Icon(
                              LineAwesomeIcons.sign_in_alt_solid,
                              color: Colors.red[800],
                            ),
                          ),
                          title: Text(
                            "Déconnexion",
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.red[800],
                            ),
                          ),
                          trailing: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(100),
                              color: Colors.grey.withOpacity(0.1),
                            ),
                            child: Icon(
                              LineAwesomeIcons.angle_right_solid,
                              color: Colors.black87,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:robotic_app/analyse_maladie/screens/analyze_image_screen.dart';
import 'package:robotic_app/community_feed/community_feed_screen.dart';
import 'package:robotic_app/messagesscreens/listuser.dart';
import 'package:robotic_app/notificationpage/notifications.dart';
import 'package:robotic_app/questionpages/addquestion.dart';
import 'package:robotic_app/questionpages/questionlist.dart';
import 'package:robotic_app/recherche_agriculteur/search_agriculteur_screen.dart';
import 'package:robotic_app/screens/home_page.dart';
import 'package:robotic_app/shared/colors.dart';

import '../chatbot/chatbot.dart';
import '../profilepages/profile.dart';

class Screens extends StatefulWidget {
  const Screens({super.key});

  @override
  State<Screens> createState() => _ScreensState();
}

class _ScreensState extends State<Screens> {
  Map userData = {};
  bool isLoading = true;

  getData() async {
    setState(() {
      isLoading = true;
    });
    try {
      DocumentSnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance
              .collection('users') //client
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

  final PageController _pageController = PageController();

  int currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? Scaffold(
          backgroundColor: Colors.white,
          body: Center(child: CircularProgressIndicator(color: Colors.black)),
        )
        : Scaffold(
          backgroundColor: Colors.white,
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.only(
              left: 25,
              right: 25,
              top: 4,
              bottom: 4,
            ),
            child: GNav(
              backgroundColor: Colors.white,
              gap: 10,
              color: Colors.grey,
              activeColor: mainColor,
              curve: Curves.decelerate,
              padding: const EdgeInsets.only(
                bottom: 10,
                left: 6,
                right: 6,
                top: 2,
              ),
              onTabChange: (index) {
                _pageController.jumpToPage(index);
                setState(() {
                  currentPage = index;
                });
              },
              tabs: [
                GButton(
                  icon: LineAwesomeIcons.question_circle,
                  text: 'Question',
                ),

                const GButton(icon: Icons.image_outlined, text: 'Images'),
                GButton(icon: LineAwesomeIcons.search_solid, text: 'Recherche'),

                const GButton(icon: CupertinoIcons.list_bullet, text: ' Feed'),
                const GButton(
                  icon: CupertinoIcons.person_alt_circle,
                  text: 'Profile',
                ),
              ],
            ),
          ),
          body: PageView(
            onPageChanged: (index) {},
            physics: const NeverScrollableScrollPhysics(),
            controller: _pageController,
            children: [
              const QuestionsListPage(),
              const AnalyzeImageScreen(),
              const SearchAgriculteurScreen(),
              CommunityFeedScreen(
                userRole: userData['role'],
                userLocalisation: userData['localisation'],
              ),
              const Profile(),
            ],
          ),
        );
  }
}

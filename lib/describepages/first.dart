import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:robotic_app/registerScreens/login.dart';
import 'package:robotic_app/shared/colors.dart';
import 'second.dart';

class FirstPage extends StatelessWidget {
  const FirstPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
              onPressed: () {
                Get.off(() => const LoginPage());
              },
              icon: const Icon(Icons.forward))
        ],
      ),
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 20.0, right: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(0),
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  child: AnimatedTextKit(
                      displayFullTextOnTap: true,
                      isRepeatingAnimation: false,
                      repeatForever: false,
                      animatedTexts: [
                        TyperAnimatedText(
                          "Chaque graine plantée est une promesse d'avenir.",
                          speed: const Duration(milliseconds: 40),
                          textStyle: const TextStyle(
                              fontFamily: "Cera Pro",
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                              color: secondaryColor),
                        )
                      ]),
                ),
                Container(
                  padding: const EdgeInsets.all(0),
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  child: AnimatedTextKit(
                      displayFullTextOnTap: true,
                      isRepeatingAnimation: false,
                      repeatForever: false,
                      animatedTexts: [
                        TyperAnimatedText(
                          "Le chemin vers une agriculture florissante est semé d'efforts et de persévérance, mais chaque récolte en vaut la peine.",
                          speed: const Duration(milliseconds: 40),
                          textStyle: const TextStyle(
                            fontFamily: "Cera Pro",
                            fontWeight: FontWeight.w600,
                            color: Color.fromARGB(255, 170, 170, 170),
                          ),
                        )
                      ]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15,),
          Padding(
            padding: const EdgeInsets.only(left: 13.0),
            child: Image.asset("assets/img/first.png"),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(left: 20.0, right: 20, bottom: 15),
            child: Container(
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                  color: mainColor,
                  borderRadius: BorderRadius.circular(12)),
              child: TextButton(
                onPressed: () {
                  Get.off(() => const SecondPage(), transition: Transition.rightToLeft);
                },
                child: const Text(
                  'Suivant',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

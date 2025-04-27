import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:robotic_app/describepages/second.dart';
import 'package:robotic_app/registerScreens/login.dart';
import 'package:robotic_app/shared/colors.dart';

class ThirdPage extends StatelessWidget {
  const ThirdPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 20.0, right: 20, top: 40),
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
                          "Découvrez la passion de la terre et le fruit du travail patient de l'agriculteur.",
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
                  child: AnimatedTextKit(
                      displayFullTextOnTap: true,
                      isRepeatingAnimation: false,
                      repeatForever: false,
                      animatedTexts: [
                        TyperAnimatedText(
                          "Chaque saison est une promesse : semer aujourd'hui pour récolter demain.",
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
          const SizedBox(height: 30,),
          Padding(
            padding: const EdgeInsets.only(right: 5.0),
            child: Image.asset("assets/img/three.png"),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(left: 20.0, right: 20, bottom: 15),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                        color: mainColor,
                        borderRadius: BorderRadius.circular(12)),
                    child: TextButton(
                      onPressed: () {
                        Get.off(() => const SecondPage(),
                            transition: Transition.leftToRight);
                      },
                      child: const Text(
                        'Retour',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                        color: mainColor,
                        borderRadius: BorderRadius.circular(12)),
                    child: TextButton(
                      onPressed: () {
                        Get.off(() => const LoginPage(),
                            transition: Transition.rightToLeft);
                      },
                      child: const Text(
                        'Connexion',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}



import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:robotic_app/profilepages/profile.dart';
import 'package:robotic_app/screens/home_page.dart';
import 'package:robotic_app/screens/screens.dart';
import 'package:robotic_app/testpage.dart';
import 'firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'registerScreens/login.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

Future<void> setup() async{
  await dotenv.load(
    fileName: ".env"
  );
  MapboxOptions.setAccessToken(dotenv.env["MAPBOX_ACCES_TOKEN"]!,);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
    Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      home: FirebaseAuth.instance.currentUser == null
              ? const LoginPage()
              : const Screens(),
    );
  }
}

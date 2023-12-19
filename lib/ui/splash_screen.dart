import 'package:face_recognition_demo/check_in_out_screen.dart';
import 'package:face_recognition_demo/common/utils/shared__preferences.dart';
import 'package:face_recognition_demo/main.dart';
import 'package:face_recognition_demo/servicies/ml_service.dart';
import 'package:face_recognition_demo/servicies/models/database_model.dart';
import 'package:face_recognition_demo/servicies/models/face_detector_model.dart';
import 'package:face_recognition_demo/ui/home/home_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../servicies/models/ml_view_model.dart';

class SplashScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _splashScreenState();
}

class _splashScreenState extends State<SplashScreen> {
  Future<bool> isUserLoggedIn() async {
    return await PreferenceManager.instance.getUser() == null ? false : true;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
        future: isUserLoggedIn(),
        builder: (context, snapshot) {
          if (snapshot.data == null ||
              snapshot.hasError ||
              !snapshot.hasData) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: ThemeData(
                colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
                useMaterial3: false,
              ),
              home: Scaffold(
                body: Container(
                  color: Colors.red,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
            );
          } else if (snapshot.data!) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: ThemeData(
                colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
                useMaterial3: false,
              ),
              home: const DashboardScreen(),
            );
          } else {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: ThemeData(
                colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
                useMaterial3: false,
              ),
              home: const LandingScreen(),
            );
          }
        });
  }
}

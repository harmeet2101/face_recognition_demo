import 'package:face_recognition_demo/servicies/database_helper.dart';
import 'package:face_recognition_demo/servicies/face_detector_service.dart';
import 'package:face_recognition_demo/servicies/ml_service.dart';
import 'package:face_recognition_demo/servicies/models/ml_view_model.dart';
import 'package:face_recognition_demo/ui/camera/camera_preview_screen.dart';
import 'package:face_recognition_demo/ui/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (context) => MLService()),
      ChangeNotifierProvider(create: (context) => FaceDetectorService()),
    ],
    child: SplashScreen(),
  ));
}

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  @override
  Widget build(BuildContext context) {
    return
      Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          title: const Text('Clocking T&A'),
        ),
        body:
        Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => CameraPreviewScreen(
                        navigateFrom: NavigateFrom.register,
                        //   mlService: mlvm,
                        //   faceDetectorService: fds,
                      )));
                },
                child: const Text('Register user'),
              ),
            ),
          ),
          const SizedBox(
            height: 16.0,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => CameraPreviewScreen(
                          navigateFrom: NavigateFrom.login,
                          //  mlService: mlvm,
                          //  faceDetectorService: fds,
                        )));
                  },
                  child: const Text('User login')),
            ),
          )
        ]),
      );
      /*MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => MLService()),
        ChangeNotifierProvider(create: (context) => FaceDetectorService()),
      ],
      builder: (context, _) {
        return Consumer2(builder: (context, mlm, fds, _) {
          final mlvm = context.read<MLService>();
          final fds = context.read<FaceDetectorService>();
          return Scaffold(
            appBar: AppBar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              title: const Text('Clocking T&A'),
            ),
            body:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => CameraPreviewScreen(
                                navigateFrom: NavigateFrom.register,
                             //   mlService: mlvm,
                             //   faceDetectorService: fds,
                              )));
                    },
                    child: const Text('Register user'),
                  ),
                ),
              ),
              const SizedBox(
                height: 16.0,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => CameraPreviewScreen(
                                  navigateFrom: NavigateFrom.login,
                                //  mlService: mlvm,
                                //  faceDetectorService: fds,
                                )));
                      },
                      child: const Text('User login')),
                ),
              )
            ]),
          );
        });
      },
    )*/;
  }
}

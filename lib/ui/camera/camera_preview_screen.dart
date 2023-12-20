import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:face_recognition_demo/common/utils/image_utils.dart';
import 'package:face_recognition_demo/servicies/models/camera_preview_model.dart';
import 'package:face_recognition_demo/ui/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:face_recognition_demo/servicies/face_detector_service.dart';
import 'package:face_recognition_demo/FacePainter.dart';
import 'package:face_recognition_demo/servicies/ml_service.dart';
import 'package:face_recognition_demo/register_screen.dart';
import 'package:face_recognition_demo/servicies/database_helper.dart';
import 'package:provider/provider.dart';

enum NavigateFrom { register, login }

class CameraPreviewScreen extends StatefulWidget {
  final NavigateFrom navigateFrom;

  const CameraPreviewScreen({
    super.key,
    required this.navigateFrom,
  });

  @override
  State<StatefulWidget> createState() => _CameraPreviewScreenState();
}

class _CameraPreviewScreenState extends State<CameraPreviewScreen> {
  late CameraController _cameraController;
  bool _cameraFront = true;
  Size? imageSize;

  late final MLService _mlViewModel = context.read<MLService>();
  late final FaceDetectorService _faceDetectorService =
      context.read<FaceDetectorService>();

  late final CameraPreviewModel _cameraPreviewModel = CameraPreviewModel(
      faceDetectorService: _faceDetectorService, mlService: _mlViewModel);

  @override
  void initState() {
    super.initState();
  }

  Future<List<CameraDescription>> _availableCameras() async {
    final cameras = await availableCameras();

    if (cameras.isNotEmpty) {
      _cameraController = CameraController(
          _cameraFront ? cameras[1] : cameras[0], ResolutionPreset.high);

      await _cameraController.initialize().then((value) {
        _cameraPreviewModel.cameraController = _cameraController;
        _cameraPreviewModel.startFaceDetection();

        if (widget.navigateFrom == NavigateFrom.login) {
          DatebaseHelper.instance.initailize();
        }
      }).onError((error, stackTrace) => throw Future.error('Error $error'));
    }

    return cameras;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<CameraDescription>>(
          future: _availableCameras(),
          builder: (BuildContext context,
              AsyncSnapshot<List<CameraDescription>> snapshot) {
            if (snapshot.hasError) {
              return const Center(
                child: Text('Something went wrong'),
              );
            } else if (snapshot.hasData) {
              return Stack(children: [
                Transform.scale(
                  scale: 1.0,
                  child: AspectRatio(
                    aspectRatio: MediaQuery.of(context).size.aspectRatio,
                    child: OverflowBox(
                      alignment: Alignment.center,
                      child: FittedBox(
                        fit: BoxFit.fitHeight,
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width,
                          height: MediaQuery.of(context).size.width *
                              _cameraController.value.aspectRatio,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CameraPreview(_cameraController),
                              ChangeNotifierProvider.value(
                                value: _cameraPreviewModel,
                                builder: (context, _) {
                                  final model =
                                      context.watch<CameraPreviewModel>();
                                  final controller = context
                                      .watch<CameraPreviewModel>()
                                      .cameraController;

                                  if (controller != null) {
                                    return CustomPaint(
                                      painter: FacePainter(
                                          face: model.faceDetected,
                                          imageSize: ImageUitls.getImageSize(
                                              controller)),
                                    );
                                  } else {
                                    return Container();
                                  }
                                  ;
                                },
                              ),
                              ChangeNotifierProvider.value(
                                value: _cameraPreviewModel,
                                builder: (context, _) {
                                  final value = context
                                      .watch<CameraPreviewModel>()
                                      .capturingImage;
                                  if (value) {
                                    return Material(
                                      color: Colors.transparent,
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(
                                            sigmaX: 10, sigmaY: 10),
                                        child: const Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              CircularProgressIndicator(),
                                              SizedBox(
                                                height: 15,
                                              ),
                                              Text(
                                                'Please wait...',
                                                style: TextStyle(
                                                    color: Colors.white),
                                              )
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  } else {
                                    return const SizedBox.shrink();
                                  }
                                },
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 22.0),
                    child: Material(
                      color: Colors.transparent,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Ink(
                            child: IconButton(
                                onPressed: () {
                                  _cameraFront = !_cameraFront;
                                  setState(() {});
                                },
                                icon: Icon(
                                  _cameraFront
                                      ? Icons.camera_front
                                      : Icons.camera_rear,
                                  color: Colors.white,
                                  size: 35.0,
                                )),
                          ),
                          const SizedBox(
                            width: 10.0,
                          ),
                          Ink(
                            decoration: const ShapeDecoration(
                              color: Colors.transparent,
                              shape: CircleBorder(),
                            ),
                            child: IconButton(
                                onPressed: () async {
                                  if (widget.navigateFrom ==
                                      NavigateFrom.register) {
                                    final res =
                                        await _cameraPreviewModel.capturing();

                                    if (res == null) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(const SnackBar(
                                        content: Text('No face detected!'),
                                        backgroundColor: Colors.red,
                                        duration: Duration(milliseconds: 1000),
                                      ));
                                    }

                                    if (res != null) {
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  RegisterFormWidget(
                                                      picture: res)));
                                    }
                                  } else {
                                    final res =
                                        await _cameraPreviewModel.predict();

                                    if (res == null) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(const SnackBar(
                                        content: Text('No face detected!'),
                                        backgroundColor: Colors.red,
                                        duration: Duration(milliseconds: 1000),
                                      ));
                                    }

                                    if (res != null) {
                                      if (res) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                          content: Text('User found'),
                                          duration:
                                              Duration(milliseconds: 1000),
                                          backgroundColor: Colors.green,
                                        ));

                                        Navigator.of(context)
                                            .pushAndRemoveUntil(
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  const DashboardScreen()),
                                          (route) => false,
                                        );
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(const SnackBar(
                                          content:
                                              Text('User record not found'),
                                          duration:
                                              Duration(milliseconds: 1000),
                                          backgroundColor: Colors.red,
                                        ));
                                      }
                                    }
                                  }
                                },
                                icon: const Icon(
                                  Icons.camera_sharp,
                                  size: 35.0,
                                  color: Colors.white,
                                ),
                                padding: EdgeInsets.zero),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              ]);
            } else {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
          }),
    );
  }

  @override
  void dispose() {
    if (mounted) {
      _cameraPreviewModel.dispose();
    }
    super.dispose();
  }
}

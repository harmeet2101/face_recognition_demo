import 'package:camera/camera.dart';
import 'package:face_recognition_demo/common/utils/file_utils.dart';
import 'package:face_recognition_demo/common/utils/image_utils.dart';
import 'package:face_recognition_demo/common/utils/shared__preferences.dart';
import 'package:face_recognition_demo/common/widgets/custom_progress_dialog.dart';
import 'package:face_recognition_demo/ui/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:face_recognition_demo/servicies/face_detector_service.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import 'package:face_recognition_demo/FacePainter.dart';

import 'package:face_recognition_demo/servicies/ml_service.dart';

import 'package:face_recognition_demo/register_screen.dart';

import 'package:face_recognition_demo/servicies/database_helper.dart';

enum NavigateFrom { register, login }

class CameraPreviewScreen extends StatefulWidget {
  final NavigateFrom navigateFrom;

  const CameraPreviewScreen({super.key, required this.navigateFrom});

  @override
  State<StatefulWidget> createState() => _CameraPreviewScreenState();
}

class _CameraPreviewScreenState extends State<CameraPreviewScreen> {
  Future<List<CameraDescription>>? _camerasList;
  late CameraController _cameraController;
  late FaceDetectorService _faceDetector;
  late MLService _mlService;
  Face? _faceDetected;
  bool _detectingFaces = false;
  bool _capturingImage = false;
  bool _cameraFront = true;
  bool _predicting = false;
  bool _saving = false;
  Size? imageSize;

  @override
  void initState() {
    //  _camerasList = _availableCameras();
    initilize();
    super.initState();
  }

  Future<List<CameraDescription>> _availableCameras() async {



    final cameras = await availableCameras();

    if (cameras.isNotEmpty) {
        _cameraController = CameraController(
            _cameraFront ? cameras[1] : cameras[0], ResolutionPreset.high);
        await _cameraController
            .initialize()
            /*.then((value) => startFaceDetection())*/
            .onError((error, stackTrace) => throw Future.error('Error $error'));
      }

      return cameras;
    }


  void initilize() {
    _faceDetector = FaceDetectorService();
    _faceDetector.initialize();
    _mlService = MLService.instance;
    _mlService.initialize();

    if (widget.navigateFrom == NavigateFrom.login) {
      DatebaseHelper.instance.initailize();
    }
  }

  void startFaceDetection() {
    if (!_cameraController.value.isInitialized) {
      return;
    }

    imageSize = ImageUitls.getImageSize(_cameraController);

    _cameraController.startImageStream((image) async {
      try {
        if (_detectingFaces) return;
        _detectingFaces = true;

        final faces = await _faceDetector.processImage(image,
            inputImageRotation: ImageUitls.rotationIntToImageRotation(
                _cameraController.description.sensorOrientation));

        if (faces.isNotEmpty) {
          _faceDetected = faces[0];

          if (_saving) {
            _mlService.setCurrentPrediction(image, _faceDetected);

            if (widget.navigateFrom == NavigateFrom.login) {
              await _predictingImage(data: _mlService.predictedData);
            }
            _saving = false;
            setState(() {});
          }
        } else {
          _faceDetected = null;
        }

        _detectingFaces = false;

          setState(() {});
      } on Error catch (e) {
        _detectingFaces = false;
        print('Error while detectiing face: $e');
        //  setState(() {});
      }
    });
  }

  Future<void> _predict() async {
    if (_faceDetected == null) {
      ScaffoldMessenger.of(context).clearSnackBars();

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('No face detected!'),
        backgroundColor: Colors.red,
        duration: Duration(milliseconds: 1000),
      ));
      return;
    }

    if (!_cameraController.value.isInitialized) {
      return;
    }
    if (_cameraController.value.isTakingPicture) {
      return;
    }

    _saving = true;
    _capturingImage = true;
    _predicting = true;
    setState(() {});
  }

  Future<void> _savingImage() async {
    if (_faceDetected == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('No face detected!'),
        backgroundColor: Colors.red,
        duration: Duration(milliseconds: 1000),
      ));
      return;
    }

    if (!_cameraController.value.isInitialized) {
      return;
    }
    if (_cameraController.value.isTakingPicture) {
      return;
    }

    _saving = true;
    _capturingImage = true;
    setState(() {});

    CustomProgressDialog(context: context).show();

    await Future.delayed(const Duration(seconds: 2));

    XFile file = await _cameraController.takePicture();

    final imageFile = await FileUtils.saveCapturedImage(file.path);

    CustomProgressDialog(context: context).hide();

    _capturingImage = false;
    setState(() {});

    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => RegisterFormWidget(picture: imageFile!)));
  }

  Future<void> _predictingImage({required List<dynamic> data}) async {
    final user = await _mlService.predict(data);

    Future.delayed(Duration(milliseconds: 3000));

    if (user != null) {
      await PreferenceManager.instance.saveUser(user);
      _predicting = false;
      _capturingImage = false;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('User found'),
        duration: Duration(milliseconds: 1000),
        backgroundColor: Colors.green,
      ));
      Future.delayed(Duration(milliseconds: 1000));
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('User record not found'),
        duration: Duration(milliseconds: 1000),
        backgroundColor: Colors.red,
      ));
    }
    _capturingImage = false;
    _predicting = false;
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
                                      !_capturingImage ||
                                      !_predicting
                                  ? CustomPaint(
                                      painter: FacePainter(
                                          face: _faceDetected,
                                          imageSize: ImageUitls.getImageSize(_cameraController)),
                                    )
                                  : const SizedBox.shrink(),
                              _predicting
                                  ? const Center(
                                      child: CircularProgressIndicator(),
                                    )
                                  : const SizedBox.shrink()
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
                          SizedBox(
                            width: 10.0,
                          ),
                          Ink(
                            decoration: const ShapeDecoration(
                              color: Colors.transparent,
                              shape: CircleBorder(),
                            ),
                            child: IconButton(
                                onPressed: () =>
                                    widget.navigateFrom == NavigateFrom.register
                                        ? _savingImage()
                                        : _predict(),
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
    _cameraController.dispose();
    _faceDetector.dispose();
    _mlService.dispose();
    super.dispose();
  }
}

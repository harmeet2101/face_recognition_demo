import 'dart:io';
import 'package:camera/camera.dart';
import 'package:face_recognition_demo/servicies/face_detector_service.dart';
import 'package:face_recognition_demo/servicies/ml_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:face_recognition_demo/common/utils/image_utils.dart';
import 'package:face_recognition_demo/common/utils/file_utils.dart';
import 'package:face_recognition_demo/common/utils/shared__preferences.dart';

class CameraPreviewModel with ChangeNotifier {
  final MLService mlService;
  final FaceDetectorService faceDetectorService;

  late CameraController? _cameraController;

  CameraController? get cameraController => _cameraController;

  set cameraController(CameraController? value) => _cameraController = value;

  Face? _faceDetected;

  Face? get faceDetected => _faceDetected;

  late CameraImage cameraImage;

  bool _stopDetectingFaces = false;

  bool _capturingImage = false;

  bool get capturingImage => _capturingImage;

  CameraPreviewModel(
      {required this.faceDetectorService, required this.mlService});

  void startFaceDetection() {
    if (!_cameraController!.value.isInitialized) {
      return;
    }

    _cameraController!.startImageStream((image) async {
      try {
        if (_stopDetectingFaces) return;
        _stopDetectingFaces = true;

        final faces = await faceDetectorService.processImage(image,
            inputImageRotation: ImageUitls.rotationIntToImageRotation(
                _cameraController!.description.sensorOrientation));
        cameraImage = image;
        if (faces.isNotEmpty) {
          _faceDetected = faces[0];
        } else {
          _faceDetected = null;
        }

        print(
            'Face detected: topLeftOffset ${_faceDetected!.boundingBox.topLeft}, id: ${_faceDetected!.trackingId}');

        _stopDetectingFaces = false;
      } on Error catch (e) {
        _stopDetectingFaces = false;
        print('Error while detectiing face: $e');
      } finally {
        notifyListeners();
      }
    });
  }

  Future<File?> capturing() async {
    if (_faceDetected == null) {
      return null;
    }

    if (!_cameraController!.value.isInitialized) {
      return null;
    }
    if (_cameraController!.value.isTakingPicture) {
      return null;
    }

    _capturingImage = true;
    _stopDetectingFaces = true;

    notifyListeners();

    if (_capturingImage) {
      mlService.setCurrentPrediction(cameraImage, _faceDetected);
    }

    await Future.delayed(const Duration(milliseconds: 2000));

    XFile file = await _cameraController!.takePicture();

    final imageFile = await FileUtils.saveCapturedImage(file.path);

    _capturingImage = false;
    _stopDetectingFaces = false;

    notifyListeners();

    return imageFile;
  }

  Future<bool?> predict() async {
    if (_faceDetected == null ||
        !_cameraController!.value.isInitialized ||
        _cameraController!.value.isTakingPicture) {
      return null;
    }

    _capturingImage = true;
    _stopDetectingFaces = true;

    notifyListeners();

    if (_capturingImage) {
      mlService.setCurrentPrediction(cameraImage, _faceDetected);
    }

    final user = await mlService.predict(mlService.predictedData);

    await Future.delayed(const Duration(milliseconds: 2000));

    bool res = false;

    if (user != null) {
      await PreferenceManager.instance.saveUser(user);
      res = true;
    } else {
      res = false;
    }

    _capturingImage = false;
    _stopDetectingFaces = false;

    notifyListeners();

    return res;
  }

  @override
  void dispose() async {
    _cameraController?.stopImageStream();
    await Future.delayed(const Duration(milliseconds: 500));
    _cameraController?.dispose();

    super.dispose();
  }
}

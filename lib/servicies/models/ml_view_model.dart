import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:face_recognition_demo/servicies/models/database_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter/src/bindings/tensorflow_lite_bindings_generated.dart';
import 'package:image/image.dart' as imglib;
import 'package:face_recognition_demo/common/utils/image_converter.dart';
import 'package:face_recognition_demo/model/User.dart';
import 'package:face_recognition_demo/servicies/database_helper.dart';

class MlViewModel with ChangeNotifier {
  Interpreter? _interpreter;
  double threshold = 1.5;

  List<dynamic> _predictedData = [];
  List<dynamic> get predictedData => _predictedData;
  bool _startPrediction = false;
  bool get startPrediction => _startPrediction;
  set startPrediction(bool value) => _startPrediction = value;

 // DataBaseModel dataBaseModel;

  MlViewModel() {
    initialize();
  }

  Future initialize() async {
    late Delegate delegate;
    try {
      if (Platform.isAndroid) {
        delegate = GpuDelegateV2(
          options: GpuDelegateOptionsV2(
            isPrecisionLossAllowed: false,
            inferencePreference: TfLiteGpuInferenceUsage
                .TFLITE_GPU_INFERENCE_PREFERENCE_FAST_SINGLE_ANSWER,
            inferencePriority1: TfLiteGpuInferencePriority
                .TFLITE_GPU_INFERENCE_PRIORITY_MIN_LATENCY,
            inferencePriority2:
                TfLiteGpuInferencePriority.TFLITE_GPU_INFERENCE_PRIORITY_AUTO,
            inferencePriority3:
                TfLiteGpuInferencePriority.TFLITE_GPU_INFERENCE_PRIORITY_AUTO,
          ),
        );
      } else if (Platform.isIOS) {
        delegate = GpuDelegate(
          options: GpuDelegateOptions(
              allowPrecisionLoss: true,
              waitType: TFLGpuDelegateWaitType.TFLGpuDelegateWaitTypeActive),
        );
      }
      var interpreterOptions = InterpreterOptions()..addDelegate(delegate);
      this._interpreter = await Interpreter.fromAsset(
          'assets/tflite/mobilefacenet.tflite',
          options: interpreterOptions);
    } catch (e) {
      print('Failed to load model.$e');
    }
  }

  @override
  void dispose() {
    this._predictedData.clear();
    this._interpreter = null;
    super.dispose();
  }

  void setCurrentPrediction(CameraImage cameraImage, Face? face) {
    if (_interpreter == null) throw Exception('Interpreter is null');
    if (face == null) throw Exception('Face is null');
    List input = preProcess(cameraImage, face);

    input = input.reshape([1, 112, 112, 3]);
    //  print('input shape ${input.shape}');
    List output = List.generate(1, (index) => List.filled(192, 0));
    //  print('output $output');
    this._interpreter?.run(input, output);
    //   print('output shape ${output.shape}');
    output = output.reshape([192]);
//    print('output reshape ${output.shape}');
    this._predictedData = List.from(output);
    print('predictedData ${_predictedData}');

    /*if (_startPrediction) {
      predict(_predictedData)
          .then((value) => {value==null?print('not found'):print('user found ${value.username}'),});
    }*/
  }

  Future<User?> predict(List data) async {
    return _searchResult(data);
  }

  List preProcess(CameraImage image, Face faceDetected) {
    imglib.Image croppedImage = cropFace(image, faceDetected);
    imglib.Image img = imglib.copyResizeCropSquare(croppedImage, 112);

    Float32List imageAsList = imageToByteListFloat32(img);
    return imageAsList;
  }

  imglib.Image cropFace(CameraImage image, Face faceDetected) {
    imglib.Image convertedImage = _convertCameraImage(image);
    double x = faceDetected.boundingBox.left - 10.0;
    double y = faceDetected.boundingBox.top - 10.0;
    double w = faceDetected.boundingBox.width + 10.0;
    double h = faceDetected.boundingBox.height + 10.0;
    return imglib.copyCrop(
        convertedImage, x.round(), y.round(), w.round(), h.round());
  }

  imglib.Image _convertCameraImage(CameraImage image) {
    var img = convertToImage(image);
    var img1 = imglib.copyRotate(img, -90);
    return img1;
  }

  Float32List imageToByteListFloat32(imglib.Image image) {
    var convertedBytes = Float32List(1 * 112 * 112 * 3);
    var buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;

    for (var i = 0; i < 112; i++) {
      for (var j = 0; j < 112; j++) {
        var pixel = image.getPixel(j, i);
        buffer[pixelIndex++] = (imglib.getRed(pixel) - 128) / 128;
        buffer[pixelIndex++] = (imglib.getGreen(pixel) - 128) / 128;
        buffer[pixelIndex++] = (imglib.getBlue(pixel) - 128) / 128;
      }
    }
    return convertedBytes.buffer.asFloat32List();
  }

  Future<User?> _searchResult(List predictedData) async {
    DatebaseHelper _dbHelper = DatebaseHelper.instance;

    List<User> users = await _dbHelper.getAllUsers();
    print('users ${users.length}');
    double minDist = 999;
    double currDist = 0.0;
    User? predictedResult;

    for (User u in users) {
      currDist = _euclideanDistance(u.userModel, predictedData);
      // print('u.model ${u.userModel}');
      print('########################### $currDist');
      // print('predicted date ${predictedData}');
      if (currDist <= threshold && currDist < minDist) {
        minDist = currDist;
        predictedResult = u;
      }
    }
    return predictedResult;
  }

  _euclideanDistance(List? e1, List? e2) {
    if (e1 == null || e2 == null) throw Exception("Null argument");

    double sum = 0.0;
    for (int i = 0; i < e1.length; i++) {
      sum += pow((e1[i] - e2[i]), 2);
    }
    return sqrt(sum);
  }

  void setPredictedData(value) {
    this._predictedData = value;
  }
}

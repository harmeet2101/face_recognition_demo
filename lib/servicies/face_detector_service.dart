import 'package:camera/camera.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceDetectorService with ChangeNotifier{
  late FaceDetector _faceDetector;
  FaceDetector get faceDetector => _faceDetector;
  List<Face> _faces = [];
  List<Face> get faces => _faces;
  bool get faceDetected => _faces.isNotEmpty;

  FaceDetectorService(){
    initialize();
  }

  void initialize() {
    _faceDetector = FaceDetector(
        options: FaceDetectorOptions(
            performanceMode: FaceDetectorMode.accurate,));
  }

  Future<List<Face>> processImage(CameraImage image,
      {InputImageRotation? inputImageRotation}) async {
    final WriteBuffer allBytes = WriteBuffer();
    for (Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final imageSize = Size(image.width.toDouble(), image.height.toDouble());

    final inputImage = InputImageData(
        size: imageSize,
        imageRotation: inputImageRotation ?? InputImageRotation.rotation0deg,
        inputImageFormat:
            InputImageFormatValue.fromRawValue(image.format.raw) ??
                InputImageFormat.yuv420,
        planeData: image.planes.map(
          (Plane plane) {
            return InputImagePlaneMetadata(
              bytesPerRow: plane.bytesPerRow,
              height: plane.height,
              width: plane.width,
            );
          },
        ).toList());

    final imageInputFirbase =
        InputImage.fromBytes(bytes: bytes, inputImageData: inputImage);

    _faces =  await _faceDetector.processImage(imageInputFirbase);
    return _faces;
  }

  dispose() {
    _faceDetector.close();
  }
}

import 'package:camera/camera.dart';

class CameraHelper {
  static List<CameraDescription>? cameras;

  static Future<void> init() async {
    cameras = await availableCameras();
  }
}

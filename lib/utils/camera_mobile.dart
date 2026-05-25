import 'package:camera/camera.dart';

Future<List<CameraDescription>> getCameras() async {
  return await availableCameras();
}

Future<CameraController> createController(List<CameraDescription> cameras) async {
  final firstCamera = cameras.firstWhere(
    (camera) => camera.lensDirection == CameraLensDirection.front,
    orElse: () => cameras.first,
  );
  return CameraController(firstCamera, ResolutionPreset.medium);
}
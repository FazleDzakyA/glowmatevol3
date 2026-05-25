import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class CameraHelper {
  CameraController? _controller;

  Future<void> initializeCamera() async {
    if (kIsWeb) return; // Tidak jalan di web

    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );
    _controller = CameraController(frontCamera, ResolutionPreset.medium);
    await _controller!.initialize();
  }

  CameraController? get controller => _controller;

  Future<void> dispose() async {
    await _controller?.dispose();
  }
  
}
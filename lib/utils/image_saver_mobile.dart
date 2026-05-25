// lib/utils/image_saver_mobile.dart
import 'dart:typed_data'; // ✅ Tambahkan ini
import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<String?> saveImageToFile(Uint8List bytes, String userId) async {
  try {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/profile_$userId.jpg');
    await file.writeAsBytes(bytes);
    return file.path;
  } catch (e) {
    print("🔥 Error save image on mobile: $e");
    return null;
  }
}
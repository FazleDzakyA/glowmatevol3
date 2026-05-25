// lib/utils/image_saver_web.dart
import 'dart:convert'; // untuk base64Encode
import 'dart:typed_data'; // ✅ Tambahkan ini

String saveImageToBase64(Uint8List bytes) {
  return base64Encode(bytes);
}
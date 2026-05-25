import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthApi {
  // ⚠️ SESUAIKAN DENGAN DEVICE KAMU!
  static const String baseUrl = 'http://127.0.0.1:8000/api'; 

  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      print(' Response Status: ${response.statusCode}');
      print('📦 Response Body: ${response.body}'); // 🔍 PENTING UNTUK DEBUG

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['status'] == 'success') {
          final token = data['data']['access_token'];
          
          // Simpan token
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('access_token', token);
          
          return {'success': true, 'message': 'Login berhasil'};
        }
      }

      // Kalau 401, 422, atau 500
      final errorBody = jsonDecode(response.body);
      return {'success': false, 'message': errorBody['message'] ?? 'Login gagal'};
      
    } catch (e) {
      print('❌ Error Network: $e');
      return {'success': false, 'message': 'Tidak bisa terhubung ke server. Cek koneksi/IP.'};
    }
  }
}
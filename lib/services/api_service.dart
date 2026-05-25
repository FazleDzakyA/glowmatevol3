import 'dart:convert';
import 'dart:typed_data'; // PENTING: Untuk Uint8List (Upload Web Safe)
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // ⚠️ PASTIKAN URL INI SESUAI DENGAN SERVER LARAVEL KAMU
  static const String baseUrl = 'http://localhost:8000/api'; 

  static Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('access_token');
    } catch (e) {
      return null;
    }
  }

  // ============================================
  // 1. AUTHENTICATION
  // ============================================

  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
         final errorJson = jsonDecode(response.body);
         throw Exception(errorJson['message'] ?? 'Login gagal');
      }
    } catch (e) {
       rethrow;
    }
  }

  static Future<Map<String, dynamic>> register(String name, String email, String password, String confirmPassword) async {
     final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': confirmPassword,
      }),
    ).timeout(const Duration(seconds: 10));
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
    } else {
        final errorJson = jsonDecode(response.body);
        throw Exception(errorJson['message'] ?? 'Register gagal');
    }
  }

  static Future<void> logout() async {
    final token = await getToken();
    if (token == null) return;
    try {
      await http.post(Uri.parse('$baseUrl/logout'), headers: {'Authorization': 'Bearer $token'}).timeout(const Duration(seconds: 5));
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
  }

  // ============================================
  // 2. USER PROFILE
  // ============================================

  static Future<Map<String, dynamic>> updateProfile(String? name, Uint8List? imageBytes, String? fileName) async {
    final token = await getToken();
    if (token == null) throw Exception("Token tidak ditemukan");

    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/update-profile'));
    request.headers['Authorization'] = 'Bearer $token';
    
    if (name != null && name.isNotEmpty) request.fields['name'] = name;
    
    // Gunakan fromBytes agar universal (Web & Mobile)
    if (imageBytes != null && imageBytes.isNotEmpty) {
       request.files.add(http.MultipartFile.fromBytes('profile_image', imageBytes, filename: fileName ?? 'profile.jpg'));
    }

    var streamedResponse = await request.send().timeout(const Duration(seconds: 30));
    var response = await http.Response.fromStream(streamedResponse);
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      final errorJson = jsonDecode(response.body);
      throw Exception(errorJson['message'] ?? 'Gagal update profil');
    }
  }

  // ============================================
  // 3. PREMIUM FEATURES
  // ============================================

  static Future<Map<String, dynamic>> checkPremiumStatus() async {
    final token = await getToken();
    if (token == null) throw Exception("Token tidak ditemukan");
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/premium/status'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Gagal cek status premium");
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> upgradePremium() async {
    final token = await getToken();
    if (token == null) throw Exception("Token tidak ditemukan");

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/premium/upgrade'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Gagal upgrade premium");
      }
    } catch (e) {
      rethrow;
    }
  }

  // ============================================
  // 4. COMMUNITY FEATURES
  // ============================================

  static Future<Map<String, dynamic>> getChannels() async {
    final token = await getToken();
    if (token == null) throw Exception("Token tidak ditemukan");

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/channels'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          return data;
        } else {
           throw Exception(data['message'] ?? 'Format response tidak valid');
        }
      } else {
        final errorJson = jsonDecode(response.body);
        throw Exception(errorJson['message'] ?? "Server Error");
      }
    } catch (e) {
      rethrow;
    }
  }

  // ✅ METHOD BARU: CREATE CHANNEL DENGAN COVER IMAGE (UNIVERSAL)
  static Future<Map<String, dynamic>> createChannelWithCover(String name, String description, Uint8List? coverBytes, String? fileName) async {
    final token = await getToken();
    if (token == null) throw Exception("Token tidak ditemukan");

    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/channels'));
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['name'] = name;
    request.fields['description'] = description;

    // Jika ada bytes cover image, tambahkan ke request
    if (coverBytes != null && coverBytes.isNotEmpty) {
      request.files.add(http.MultipartFile.fromBytes(
        'cover_image', 
        coverBytes,
        filename: fileName ?? 'cover.jpg',
      ));
    }

    try {
      var streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        final errorJson = jsonDecode(response.body);
        throw Exception(errorJson['message'] ?? 'Gagal membuat channel');
      }
    } catch (e) {
      throw Exception("Error creating channel: $e");
    }
  }
  
  static Future<Map<String, dynamic>> toggleFollow(int channelId) async {
    final token = await getToken();
    if (token == null) throw Exception("Token tidak ditemukan");
    
    final response = await http.post(
      Uri.parse('$baseUrl/channels/$channelId/follow'),
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 10));
    
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception("Gagal follow/unfollow");
  }

  // ============================================
  // 5. BADGE FEATURES
  // ============================================

  static Future<Map<String, dynamic>> getBadges() async {
    final token = await getToken();
    if (token == null) throw Exception("Token tidak ditemukan");

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/my-badges'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        final errorJson = jsonDecode(response.body);
        throw Exception(errorJson['message'] ?? 'Gagal mengambil data badge');
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> unlockBadge(String badgeKey) async {
    final token = await getToken();
    if (token == null) throw Exception("Token tidak ditemukan");

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/badges/unlock'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'badge_key': badgeKey}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        final errorJson = jsonDecode(response.body);
        throw Exception(errorJson['message'] ?? 'Gagal membuka badge');
      }
    } catch (e) {
      rethrow;
    }
  }

  // ============================================
  // 6. DAILY PROGRESS TRACKER
  // ============================================

  static Future<List<int>> getTodayProgress() async {
    final token = await getToken();
    if (token == null) throw Exception("Token tidak ditemukan");

    final response = await http.get(
      Uri.parse('$baseUrl/dp-today'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception("Gagal mengambil progress");
    }

    final data = jsonDecode(response.body);
    final rawData = data['data'];
    if (rawData == null) return [];
    return List<int>.from(rawData);
  }

  static Future<Map<String, dynamic>> saveTodayProgress(List<int> completedIds) async {
    final token = await getToken();
    if (token == null) throw Exception("Token tidak ditemukan");

    final response = await http.post(
      Uri.parse('$baseUrl/dp-save'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'completed_steps': completedIds}),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception("Gagal menyimpan progress");
    }

    return jsonDecode(response.body);
  }

  // ============================================
  // 7. CHANNEL CHAT FEATURES
  // ============================================

  static Future<Map<String, dynamic>> getChannelChats(int channelId) async {
    final token = await getToken();
    if (token == null) throw Exception("Token tidak ditemukan");

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/channels/$channelId/chats'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Gagal ambil chat");
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> sendChannelChat(int channelId, String message) async {
    final token = await getToken();
    if (token == null) throw Exception("Token tidak ditemukan");

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/channels/$channelId/chats'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'message': message}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Gagal kirim chat");
      }
    } catch (e) {
      rethrow;
    }
  }

  // ============================================
  // 8. CHANNEL POST FEATURES (UNIVERSAL WEB & MOBILE)
  // ============================================

  static Future<Map<String, dynamic>> uploadPost(int channelId, String caption, Uint8List? imageBytes, String fileName, String type) async {
    final token = await getToken();
    if (token == null) throw Exception("Token tidak ditemukan");

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/channels/$channelId/posts'),
    );
    
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['caption'] = caption;
    request.fields['type'] = type; 

    // Jika ada bytes gambar, tambahkan ke request menggunakan fromBytes (Aman untuk Web)
    if (imageBytes != null && imageBytes.isNotEmpty) {
      request.files.add(http.MultipartFile.fromBytes(
        'media_file', 
        imageBytes,
        filename: fileName, // Nama file penting agar Laravel tahu ekstensinya
      ));
    }

    try {
      var streamedResponse = await request.send().timeout(const Duration(seconds: 60));
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        final errorJson = jsonDecode(response.body);
        throw Exception(errorJson['message'] ?? 'Gagal upload post');
      }
    } catch (e) {
      throw Exception("Error uploading post: $e");
    }
  }

  // ============================================
  // 9. HOME PAGE FEATURES (BARU DITAMBAHKAN)
  // ============================================

  static Future<int> getChannelCount() async {
    final token = await getToken();
    if (token == null) throw Exception("Token tidak ditemukan");

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/channel-count'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          return data['data']['total_channels'];
        } else {
          throw Exception(data['message'] ?? 'Gagal ambil jumlah channel');
        }
      } else {
        throw Exception("Gagal ambil jumlah channel");
      }
    } catch (e) {
      rethrow;
    }
  }
}
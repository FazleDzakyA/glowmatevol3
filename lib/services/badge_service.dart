import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/badge_model.dart';

class BadgeService {
  // ⚠️ PASTIKAN URL INI SESUAI DENGAN SERVER LARAVEL KAMU
  static const String baseUrl = 'http://localhost:8000/api';

  static Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('access_token');
    } catch (e) {
      print("❌ [BadgeService] Error getting token: $e");
      return null;
    }
  }

  /// Mengambil daftar semua badge + status unlock user dari Laravel
  static Future<List<BadgeModel>> fetchBadges() async {
    final token = await getToken();
    
    if (token == null) {
      print("❌ [BadgeService] Token is null. User might not be logged in.");
      throw Exception("Token tidak ditemukan. Silakan login ulang.");
    }

    print("🔍 [BadgeService] Fetching badges from: $baseUrl/my-badges");

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/my-badges'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      print("📡 [BadgeService] Response Status: ${response.statusCode}");
      // print("📡 [BadgeService] Response Body: ${response.body}"); // Uncomment jika perlu debug

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        
        if (data['data'] is List) {
          List<dynamic> badgesJson = data['data'];
          print("✅ [BadgeService] Successfully fetched ${badgesJson.length} badges.");
          return badgesJson.map((json) => BadgeModel.fromJson(json)).toList();
        } else {
          print("❌ [BadgeService] Invalid data format.");
          throw Exception("Format data badge tidak valid.");
        }
      } else {
        final errorJson = jsonDecode(response.body);
        print("❌ [BadgeService] API Error: ${errorJson['message']}");
        throw Exception(errorJson['message'] ?? 'Gagal mengambil data badge');
      }
    } on http.ClientException catch (e) {
      print("❌ [BadgeService] Network Error: $e");
      throw Exception("Tidak dapat terhubung ke server. Pastikan Laravel berjalan.");
    } on FormatException catch (e) {
      print("❌ [BadgeService] JSON Parse Error: $e");
      throw Exception("Response dari server bukan JSON yang valid.");
    } catch (e) {
      print("❌ [BadgeService] Unexpected Error: $e");
      rethrow;
    }
  }

  /// ✅ FUNGSI BARU: Menghitung jumlah badge yang sudah di-unlock
  /// Dipanggil oleh AuthController saat Login dan oleh HomePage
  static Future<int> getMyBadgeCount() async {
    final token = await getToken();
    
    if (token == null) {
      print("❌ [BadgeService] Token is null for badge count.");
      return 0;
    }

    print("🔍 [BadgeService] Fetching badge count from: $baseUrl/my-badge-count");

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/my-badge-count'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        
        // Struktur response: { "status": "success", "data": { "count": 1 } }
        if (data['status'] == 'success' && data['data'] != null) {
          final count = data['data']['count'] ?? 0;
          print("✅ [BadgeService] Badge count: $count");
          return count;
        } else {
          print("❌ [BadgeService] Invalid count response format.");
          return 0;
        }
      } else {
        print("❌ [BadgeService] Failed to fetch count. Status: ${response.statusCode}");
        return 0;
      }
    } catch (e) {
      print("❌ [BadgeService] Error getting badge count: $e");
      return 0; // Return 0 agar UI tidak crash jika error
    }
  }

  /// Opsional: Fungsi untuk mendapatkan hanya key badge yang sudah unlocked
  static Future<List<String>> getUnlockedBadgeKeys() async {
    try {
      final allBadges = await fetchBadges();
      final unlockedKeys = allBadges
          .where((badge) => badge.isUnlocked)
          .map((badge) => badge.key)
          .toList();
      return unlockedKeys;
    } catch (e) {
      print("❌ [BadgeService] Error getting unlocked keys: $e");
      return [];
    }
  }
}
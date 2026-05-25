import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/badge_service.dart'; 

class AuthController with ChangeNotifier {
  // ============================================
  // 1. VARIABEL DATA USER (State Lokal)
  // ============================================
  String _laravelName = '';
  String _laravelEmail = '';
  String _laravelProfileImage = '';
  int? _laravelUserId; 
  
  // ============================================
  // 2. VARIABEL FITUR (Premium & Badges)
  // ============================================
  bool _isPremium = false;       
  int _badgeCount = 0;           
  List<dynamic> _badges = [];    

  // ============================================
  // 3. GETTERS
  // ============================================
  String get displayName => _laravelName.isNotEmpty ? _laravelName : "GlowMate User";
  String get email => _laravelEmail.isNotEmpty ? _laravelEmail : "";
  String get profileImage => _laravelProfileImage;
  int? get userId => _laravelUserId; 
  bool get isPremium => _isPremium;
  int get badgeCount => _badgeCount;
  List<dynamic> get badges => _badges;

  // ============================================
  // 4. INITIALIZATION
  // ============================================
  
  Future<void> init() async {
    await loadUserDataFromPrefs();
    if (_laravelEmail.isNotEmpty) {
      await fetchPremiumStatus();
      await fetchBadges();
    }
  }

  /// Memuat data user dari SharedPreferences saat aplikasi dibuka
  Future<void> loadUserDataFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    
    final name = prefs.getString('laravel_user_name');
    final email = prefs.getString('laravel_user_email');
    final image = prefs.getString('laravel_user_profile_image');
    final idStr = prefs.getString('laravel_user_id');

    print(" [AuthController] Memuat data dari Local Storage...");
    print("   Name Found: ${name != null}");
    print("   Email Found: ${email != null}");
    print("   ID String Found: $idStr");

    if (name != null && email != null) {
      _laravelName = name;
      _laravelEmail = email;
      _laravelProfileImage = image ?? '';
      
      // ✅ PERBAIKAN PARSING ID YANG LEBIH AMAN
      if (idStr != null && idStr.isNotEmpty) {
        try {
          _laravelUserId = int.parse(idStr);
          print("   ✅ ID Berhasil diparse: $_laravelUserId");
        } catch (e) {
          print("   ❌ Gagal parse ID '$idStr': $e");
          _laravelUserId = null;
        }
      } else {
        print("   ⚠️ ID String kosong atau null");
        _laravelUserId = null;
      }
      
      notifyListeners();
    } else {
      print("ℹ️ [AuthController] Tidak ada data user tersimpan lokal.");
    }
  }

  // ============================================
  // 5. SETTERS
  // ============================================

  void setLaravelData(String name, String email, String? imageUrl, {int? id}) {
    _laravelName = name;
    _laravelEmail = email;
    _laravelUserId = id; 
    
    print("💾 [AuthController] Menyimpan data user...");
    print("   Name: $name");
    print("   Email: $email");
    print("   ID: $id");

    if (imageUrl != null && imageUrl.isNotEmpty) {
      if (imageUrl.startsWith('http')) {
        _laravelProfileImage = imageUrl;
      } else {
        _laravelProfileImage = 'http://localhost:8000/storage/$imageUrl'; 
      }
    } else {
      _laravelProfileImage = '';
    }
    
    _saveToPrefs(name, email, _laravelProfileImage, id);
    notifyListeners();
  }

  Future<void> _saveToPrefs(String name, String email, String image, int? id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('laravel_user_name', name);
    await prefs.setString('laravel_user_email', email);
    await prefs.setString('laravel_user_profile_image', image);
    
    if (id != null) {
      await prefs.setString('laravel_user_id', id.toString());
      print("   ✅ ID '$id' berhasil disimpan ke prefs.");
    } else {
      print("   ⚠️ ID null, tidak disimpan ke prefs.");
    }
  }

  void setPremiumStatus(bool status) {
    _isPremium = status;
    notifyListeners();
  }

  void setBadges(List<dynamic> badgesList) {
    _badges = badgesList;
    _badgeCount = badgesList.where((b) => (b['is_unlocked'] == true || b['isUnlocked'] == true)).length;
    notifyListeners();
  }

  void clearUser() async {
    _laravelName = '';
    _laravelEmail = '';
    _laravelProfileImage = '';
    _laravelUserId = null; 
    _isPremium = false;
    _badges = []; 
    _badgeCount = 0;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('laravel_user_name');
    await prefs.remove('laravel_user_email');
    await prefs.remove('laravel_user_profile_image');
    await prefs.remove('laravel_user_id');
    
    notifyListeners();
  }

  // ============================================
  // 6. FUNGSI LOGIC
  // ============================================

  Future<void> fetchPremiumStatus() async {
    try {
      final response = await ApiService.checkPremiumStatus();
      if (response['status'] == 'success') {
        setPremiumStatus(response['data']['is_premium']);
      }
    } catch (e) {
      print("❌ Error fetching premium status: $e");
    }
  }

  Future<void> fetchBadges() async {
    try {
      final badgesList = await BadgeService.fetchBadges();
      final dynamicList = badgesList.map((badge) => {
        'id': badge.id,
        'name': badge.name,
        'is_unlocked': badge.isUnlocked, 
        'isUnlocked': badge.isUnlocked
      }).toList();
      setBadges(dynamicList);
    } catch (e) {
      print("❌ Gagal mengambil badge: $e");
    }
  }

  Future<void> signOut() async {
    try {
      await ApiService.logout();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('access_token');
      clearUser();
      print("✅ Logout berhasil.");
    } catch (e) {
      print("❌ Error during sign out: $e");
    }
  }
}
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../controllers/auth_controller.dart';
import '../../routes/app_routes.dart';

String _cleanUserId(String email) => email.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  String _displayName = 'Loading...';
  String _userEmail = '';
  Uint8List? _localImageBytes;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
    
    _loadProfileData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadProfileData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    if (!mounted) return;

    final authCtrl = context.read<AuthController>();
    String name = authCtrl.displayName;
    String email = authCtrl.email;

    if (name == "GlowMate User" || name.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      name = prefs.getString('laravel_user_name') ?? '';
      email = prefs.getString('laravel_user_email') ?? '';
    }

    if (name.isEmpty) name = email.split('@').first.isNotEmpty ? email.split('@').first : 'GlowMate User';
    if (email.isEmpty) email = 'user@example.com';

    Uint8List? bytes;
    String userId = _cleanUserId(email);
    String key = kIsWeb ? 'profileImageBase64_$userId' : 'profileImagePath_$userId';

    final prefs = await SharedPreferences.getInstance();
    if (kIsWeb) {
      final base64 = prefs.getString(key);
      if (base64 != null) try { bytes = base64Decode(base64); } catch (e) {}
    } else {
      final path = prefs.getString(key);
      if (path != null) try { 
        final file = File(path); 
        if (await file.exists()) bytes = await file.readAsBytes(); 
      } catch (e) {}
    }

    if (mounted) {
      setState(() { 
        _displayName = name; 
        _userEmail = email; 
        _localImageBytes = bytes; 
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFFF6A8B8);
    final secondaryColor = const Color(0xFFE91E63);
    
    final authCtrl = context.watch<AuthController>(); 

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFFFF9FA),
      appBar: AppBar(
        backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFFFF9FA),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: isDarkMode ? Colors.white : Colors.black87),
          onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.home),
        ),
        title: Text(
          "Profile",
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w800,
            fontSize: 24,
          ),
        ),
        centerTitle: false,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              // ✅ HEADER PROFIL YANG RAPI (TIDAK MELAR)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor.withOpacity(0.2), secondaryColor.withOpacity(0.1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: primaryColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    // Foto Profil
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
                      ),
                      child: CircleAvatar(
                        radius: 36,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: _localImageBytes != null 
                            ? MemoryImage(_localImageBytes!) 
                            : (authCtrl.profileImage.isNotEmpty 
                                ? NetworkImage(authCtrl.profileImage) 
                                : null),
                        child: (_localImageBytes == null && authCtrl.profileImage.isEmpty) 
                            ? Icon(Icons.person, size: 40, color: Colors.grey.shade400) 
                            : null,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            authCtrl.displayName,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            authCtrl.email,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // ✅ MENU LIST
              _buildMenuCard(
                context: context,
                icon: Icons.calendar_month_rounded,
                title: "Skincare Tracker",
                subtitle: "Track your daily routine",
                color: const Color(0xFF00BCD4),
                onTap: () => Navigator.pushNamed(context, AppRoutes.tracker),
                isDarkMode: isDarkMode,
              ),
              _buildMenuCard(
                context: context,
                icon: Icons.event_note_rounded,
                title: "Beauty Calendar",
                subtitle: "Schedule appointments",
                color: const Color(0xFFE91E63),
                onTap: () => Navigator.pushNamed(context, AppRoutes.calendar),
                isDarkMode: isDarkMode,
              ),
              _buildMenuCard(
                context: context,
                icon: Icons.groups_rounded,
                title: "Community",
                subtitle: "Join beauty channels",
                color: const Color(0xFF9C27B0),
                onTap: () => Navigator.pushNamed(context, AppRoutes.community),
                isDarkMode: isDarkMode,
              ),
              _buildMenuCard(
                context: context,
                icon: Icons.emoji_events_rounded,
                title: "My Badges",
                subtitle: "View your achievements",
                color: Colors.amber[700]!,
                onTap: () => Navigator.pushNamed(context, AppRoutes.badge),
                isDarkMode: isDarkMode,
              ),
              _buildMenuCard(
                context: context,
                icon: Icons.settings_rounded,
                title: "Settings",
                subtitle: "App preferences & logout",
                color: Colors.grey[600]!,
                onTap: () => Navigator.pushNamed(context, AppRoutes.settings),
                isDarkMode: isDarkMode,
              ),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    required bool isDarkMode,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E1E2E) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05), blurRadius: 10, offset: const Offset(0, 4))],
          border: Border.all(color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.grey.shade100),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(16)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.white70 : Colors.grey.shade500)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 16, color: isDarkMode ? Colors.white54 : Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
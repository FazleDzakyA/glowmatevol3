import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../routes/app_routes.dart';
import 'edit_profile_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    // Animasi Masuk
    _controller = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFFF6A8B8);
    final secondaryColor = const Color(0xFFE91E63);
    
    // Watch AuthController & ThemeController
    final authCtrl = context.watch<AuthController>();
    final themeCtrl = context.watch<ThemeController>();

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context);
        return false;
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFFFF9FA),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: isDarkMode ? Colors.white : Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            "Settings",
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w800,
              fontSize: 24,
            ),
          ),
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 100, 24, 40),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- PROFILE CARD YANG MENONJOL ---
                  GestureDetector(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const EditProfilePage()),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDarkMode ? const Color(0xFF1E1E2E) : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Foto Profil Besar
                          Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: primaryColor.withOpacity(0.3), width: 2),
                            ),
                            child: CircleAvatar(
                              radius: 33,
                              backgroundColor: Colors.grey.shade200,
                              backgroundImage: authCtrl.profileImage.isNotEmpty
                                  ? NetworkImage(authCtrl.profileImage)
                                  : null,
                              child: (authCtrl.profileImage.isEmpty)
                                  ? const Icon(Icons.person, color: Colors.grey, size: 35)
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  authCtrl.displayName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: isDarkMode ? Colors.white : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  authCtrl.email,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Tap to edit profile",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: primaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios_rounded, size: 16, color: isDarkMode ? Colors.white54 : Colors.grey.shade400),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // --- PREFERENCES SECTION ---
                  Text(
                    "Preferences",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white70 : Colors.grey.shade500,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildSettingCard(
                    context: context,
                    icon: Icons.notifications_none_rounded,
                    title: "Notifications",
                    subtitle: "Manage push alerts",
                    color: Colors.blue[400]!,
                    widget: Switch(
                      value: false,
                      activeColor: primaryColor,
                      onChanged: null, // Disabled for now
                    ),
                    isDarkMode: isDarkMode,
                  ),

                  _buildSettingCard(
                    context: context,
                    icon: Icons.dark_mode_outlined,
                    title: "Dark Mode",
                    subtitle: "Toggle app theme",
                    color: Colors.purple[400]!,
                    widget: Switch(
                      value: themeCtrl.themeMode == ThemeMode.dark,
                      activeColor: primaryColor,
                      onChanged: (value) {
                        themeCtrl.toggleTheme();
                      },
                    ),
                    isDarkMode: isDarkMode,
                  ),

                  const SizedBox(height: 32),

                  // --- ACCOUNT & SUPPORT SECTION ---
                  Text(
                    "Account & Support",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white70 : Colors.grey.shade500,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildSettingCard(
                    context: context,
                    icon: Icons.lock_outline_rounded,
                    title: "Privacy & Security",
                    subtitle: "Data policy & safety",
                    color: Colors.teal[400]!,
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacySecurityPage()));
                    },
                    isDarkMode: isDarkMode,
                  ),

                  _buildSettingCard(
                    context: context,
                    icon: Icons.help_outline_rounded,
                    title: "Help & Support",
                    subtitle: "FAQs & Contact us",
                    color: Colors.orange[400]!,
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpSupportPage()));
                    },
                    isDarkMode: isDarkMode,
                  ),

                  const SizedBox(height: 32),

                  // --- LOGOUT BUTTON ---
                  GestureDetector(
                    onTap: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          title: const Text("Logout?"),
                          content: const Text("Are you sure you want to log out?"),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                              child: const Text("Yes, Logout"),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        // Reset theme to light before logout (opsional, sesuai kode lamamu)
                        themeCtrl.setDarkMode(false); 
                        await authCtrl.signOut();
                        
                        if (mounted) {
                          Navigator.pushNamedAndRemoveUntil(
                            context, 
                            AppRoutes.login, 
                            (route) => false
                          );
                        }
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDarkMode ? const Color(0xFF1E1E2E) : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout_rounded, color: Colors.redAccent, size: 24),
                          const SizedBox(width: 10),
                          Text(
                            "Log Out",
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  Center(
                    child: Text(
                      "GlowMate v1.0.0",
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ✅ WIDGET KARTU SETTING YANG ELEGAN
  Widget _buildSettingCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    Widget? widget,
    Function()? onTap,
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.grey.shade100),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.white70 : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            widget ?? Icon(Icons.arrow_forward_ios_rounded, size: 16, color: isDarkMode ? Colors.white54 : Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}

// --- WIDGET-WIDGET LAINNYA (Privacy, Help) ---
// (Biarkan sama seperti kode kamu sebelumnya, sudah bagus)

class PrivacySecurityPage extends StatelessWidget {
  const PrivacySecurityPage({super.key});
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFFFF9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back_ios_new, color: isDarkMode ? Colors.white : Colors.black87), onPressed: () => Navigator.pop(context)),
        title: Text("Privacy & Security", style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
      ),
      body: Padding(padding: const EdgeInsets.all(22), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_CombinedPrivacyCard(isDarkMode: isDarkMode), const SizedBox(height: 20)])),
    );
  }
}

class _CombinedPrivacyCard extends StatelessWidget {
  final bool isDarkMode;
  const _CombinedPrivacyCard({required this.isDarkMode});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E2E) : Colors.white, 
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: ExpansionTile(
        initiallyExpanded: true,
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        title: Text("Privacy Policy & Data Security", style: TextStyle(fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87, fontSize: 15)),
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Privacy Policy", style: TextStyle(fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87, fontSize: 14)),
                const SizedBox(height: 8),
                Text(
                  "We respect your privacy. This policy explains how we collect, use, and protect your information.\n\n"
                  "Info We Collect\n• Personal: Name, email, profile pic.\n• Usage: Pages visited, features used.\n• Device: OS, browser.\n\n"
                  "Use of Info\n• Provide service.\n• Personalize experience.\n• Communicate updates.\n• Improve features.\n\n"
                  "Data Security\nWe protect your data against unauthorized access.\n\n"
                  "Contact Us\ntitaniumakbar4@gmail.com",
                  style: TextStyle(fontSize: 13, height: 1.5, color: isDarkMode ? Colors.white70 : Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFFFF9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back_ios_new, color: isDarkMode ? Colors.white : Colors.black87), onPressed: () => Navigator.pop(context)),
        title: Text("Help & Support", style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle("Frequently Asked Questions (FAQ)", isDarkMode),
            const SizedBox(height: 10),
            _buildTextContent(
              "Q: How do I reset my password?\nA: Go to the login screen and tap on 'Forgot Password'. Follow the instructions sent to your email.\n\nQ: How do I update my profile information?\nA: Navigate to Settings > Edit Profile to modify your details.\n\nQ: What should I do if I encounter an error?\nA: Please report the issue through the 'Report a Problem' section below.",
              isDarkMode
            ),
            const SizedBox(height: 20),
            _buildSectionTitle("Contact Us", isDarkMode),
            const SizedBox(height: 10),
            _buildTextContent(
              "If you need further assistance, feel free to reach out to us:\n\n• Email: titaniumakbar4@gmail.com\n• Phone: +62 882-2691-5729 (Kirei)\n• Phone: +62 896-7013-5228 (Dirda)",
              isDarkMode
            ),
            const SizedBox(height: 20),
            _buildSectionTitle("Report a Problem", isDarkMode),
            const SizedBox(height: 10),
            _buildTextContent(
              "Encountering an issue? Let us know so we can fix it!\n\n• Describe the problem in detail.\n• Include steps to reproduce the issue.\n• Mention your device type and app version.",
              isDarkMode
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDarkMode) {
    return Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87));
  }

  Widget _buildTextContent(String text, bool isDarkMode) {
    return Text(text, style: TextStyle(fontSize: 14, height: 1.5, color: isDarkMode ? Colors.white70 : Colors.grey.shade700));
  }
}
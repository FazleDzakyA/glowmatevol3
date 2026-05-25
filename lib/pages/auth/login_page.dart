import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ✅ PASTIKAN IMPORT INI ADA
import '../../controllers/auth_controller.dart';
import '../../services/api_service.dart';
import '../../routes/app_routes.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  
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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ✅ FUNGSI LOGIN FINAL (DIPERBAIKI DENGAN ID & FIREBASE AUTH)
  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email dan Password wajib diisi!"), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await ApiService.login(
        _emailController.text.trim(), 
        _passwordController.text
      );

      if (response['status'] == 'success') {
        final data = response['data'];
        final token = data['access_token'];
        final user = data['user'];

        final prefs = await SharedPreferences.getInstance();
        
        // 1. Simpan Token Akses Laravel
        await prefs.setString('access_token', token);

        // 2. Ambil Data User
        final safeName = user['name'] ?? 'GlowMate User';
        final safeEmail = user['email'] ?? _emailController.text.trim();
        final safeImage = user['profile_image'];
        final safeId = user['id']; 

        print("🔍 Debug Login - User ID dari Server: $safeId");

        // 3. Update Data User di AuthController DENGAN ID
        context.read<AuthController>().setLaravelData(
          safeName, 
          safeEmail, 
          safeImage,
          id: safeId 
        );

        // ✅ 4. SIGN IN KE FIREBASE SECARA ANONYMOUS (PENTING UNTUK RULES!)
        try {
          // Cek apakah sudah ada sesi firebase auth aktif
          if (FirebaseAuth.instance.currentUser == null) {
            await FirebaseAuth.instance.signInAnonymously();
            print("✅ Firebase Anonymous Auth berhasil. UID: ${FirebaseAuth.instance.currentUser?.uid}");
          } else {
            print("ℹ️ Firebase Auth sudah aktif. UID: ${FirebaseAuth.instance.currentUser?.uid}");
          }
        } catch (e) {
          print("❌ Gagal sign in Firebase Anonymous: $e");
          // Kita biarkan proses login lanjut meskipun firebase auth gagal, 
          // tapi fitur firestore mungkin tidak jalan jika rules ketat.
        }

        // 5. Cek Status Premium & Badges
        await context.read<AuthController>().fetchPremiumStatus();
        await context.read<AuthController>().fetchBadges();

        if (mounted) {
          Navigator.pushReplacementNamed(context, AppRoutes.home);
        }
      } else {
        throw Exception(response['message'] ?? 'Login gagal');
      }

    } catch (e) {
      print("❌ ERROR LOGIN DETAIL: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Login Gagal: ${e.toString()}"), 
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFFF6A8B8);
    final secondaryColor = const Color(0xFFE91E63);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFFFF9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 60),
                  
                  // ✅ LOGO GLOWMATE DENGAN SHADOW
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.4),
                          blurRadius: 20,
                          spreadRadius: 5,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/icons/glowmate_icon.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(Icons.face, size: 60, color: primaryColor),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  Text(
                    "Welcome Back!",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Login to continue your glow journey",
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
                    ),
                  ),
                  
                  const SizedBox(height: 40),

                  // ✅ INPUT FIELDS MODERN
                  _buildTextField(
                    controller: _emailController,
                    label: "Email Address",
                    hint: "Enter your email",
                    icon: Icons.email_outlined,
                    isDarkMode: isDarkMode,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildTextField(
                    controller: _passwordController,
                    label: "Password",
                    hint: "Enter your password",
                    icon: Icons.lock_outline_rounded,
                    isDarkMode: isDarkMode,
                    obscureText: !_isPasswordVisible,
                    suffixIcon: IconButton(
                      icon: Icon(_isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey),
                      onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                    ),
                  ),

                  const SizedBox(height: 10),
                  
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {}, 
                      child: Text(
                        "Forgot Password?",
                        style: TextStyle(color: secondaryColor, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ✅ TOMBOL LOGIN DENGAN GRADASI
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: secondaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 5,
                        shadowColor: secondaryColor.withOpacity(0.4),
                      ),
                      child: _isLoading
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation(Colors.white)))
                          : const Text("Login", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.grey.shade600),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, AppRoutes.register),
                        child: Text(
                          "Register Now",
                          style: TextStyle(color: secondaryColor, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ✅ WIDGET INPUT FIELD YANG RAPI
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDarkMode,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87, fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: isDarkMode ? Colors.white54 : Colors.grey.shade400),
            prefixIcon: Icon(icon, color: isDarkMode ? Colors.white70 : Colors.grey.shade500),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: isDarkMode ? const Color(0xFF1E1E2E) : Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFF6A8B8), width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
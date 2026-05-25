import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Setup Animasi Logo
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _controller.forward();

    _navigateToNext();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _navigateToNext() async {
    try {
      // Tunggu 2.5 detik agar animasi selesai
      await Future.delayed(const Duration(milliseconds: 2500));
      
      // Pastikan widget masih mounted sebelum navigate
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
      }
    } catch (e) {
      print("❌ Error navigating from splash: $e");
      // Fallback jika error
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Background putih bersih
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ✅ LOGO DARI ASSETS
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFF8A9BB).withOpacity(0.1), // Lingkaran pink muda di belakang logo
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF8A9BB).withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Image.asset(
                      "assets/icons/glowmate_icon.png", 
                      width: 80,
                      height: 80,
                      fit: BoxFit.contain,
                      // Penting: Jika gambar transparan (PNG), pastikan file-nya benar
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback jika gambar gagal dimuat
                        return const Icon(Icons.face, size: 60, color: Color(0xFFF8A9BB));
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                const Text(
                  "GlowMate",
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: Colors.black87,
                    fontFamily: 'Poppins', // Opsional: Gunakan font cantik jika ada
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  "Your Beauty Journey Starts Here",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
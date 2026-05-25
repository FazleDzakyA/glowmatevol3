import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../controllers/auth_controller.dart';
import '../../services/api_service.dart';

class UpgradePremiumPage extends StatefulWidget {
  const UpgradePremiumPage({super.key});

  @override
  State<UpgradePremiumPage> createState() => _UpgradePremiumPageState();
}

class _UpgradePremiumPageState extends State<UpgradePremiumPage> with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    // Animasi masuk yang elegan
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleUpgrade() async {
    setState(() => _isLoading = true);

    try {
      final response = await ApiService.upgradePremium();

      if (response['status'] == 'success') {
        final snapToken = response['data']['snap_token'];
        final orderId = response['data']['order_id'];

        print("✅ [UpgradePage] Snap Token Received: $snapToken");
        
        final paymentUrl = 'https://app.sandbox.midtrans.com/snap/v2/vtweb/$snapToken';

        if (mounted) {
          _showPaymentDialog(paymentUrl);
        }
      } else {
        throw Exception(response['message'] ?? 'Gagal upgrade');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString()}"), 
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ✅ DIALOG PEMBAYARAN YANG LEBIH ELEGAN
  void _showPaymentDialog(String paymentUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6), // Background gelap transparan
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: MediaQuery.of(context).size.width > 600 ? 450 : double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF6A8B8).withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Icon Futuristik
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [const Color(0xFFF6A8B8), const Color(0xFFE91E63)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(Icons.diamond, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 20),
              
              const Text(
                "Selesaikan Pembayaran",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
              ),
              const SizedBox(height: 10),
              
              Text(
                "Klik tombol di bawah untuk membuka gateway pembayaran Midtrans yang aman.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              
              const SizedBox(height: 24),
              
              // Tombol Buka Pembayaran
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.open_in_new, size: 20),
                  label: const Text("Buka Halaman Pembayaran", style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF6A8B8),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 5,
                    shadowColor: const Color(0xFFF6A8B8).withOpacity(0.5),
                  ),
                  onPressed: () async {
                    final Uri url = Uri.parse(paymentUrl);
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    }
                  },
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Tombol Saya Sudah Bayar
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text("Saya Sudah Bayar", style: TextStyle(fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF4CAF50), width: 2),
                    foregroundColor: const Color(0xFF4CAF50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await _verifyPayment();
                  },
                ),
              ),
              
              const SizedBox(height: 10),
              
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text("Batal", style: TextStyle(color: Colors.grey[500])),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ FUNGSI VERIFIKASI TERPISAH AGAR KODE RAPI
  Future<void> _verifyPayment() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      if (token == null) throw Exception("Session expired. Please login again.");

      final checkResponse = await http.post(
        Uri.parse('http://localhost:8000/api/premium/check-status'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      );

      final checkData = jsonDecode(checkResponse.body);

      if (checkResponse.statusCode == 200 && checkData['status'] == 'success') {
        context.read<AuthController>().setPremiumStatus(true);
        if (mounted) _showSuccessDialog();
      } else {
        throw Exception(checkData['message'] ?? 'Payment not verified yet.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.celebration, color: Colors.amber[700]),
            const SizedBox(width: 10),
            const Text("Upgrade Berhasil!", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text("Selamat! Anda sekarang adalah member Premium GlowMate. Nikmati fitur eksklusif membuat channel kecantikan sendiri."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text("Mulai Eksplorasi", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF6A8B8))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // Agar background sampai ke atas
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        // Background Gradasi Futuristik
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFE6F0), // Pink sangat muda
              Color(0xFFFFFFFF), // Putih
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Hero Icon dengan Glow Effect
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFF6A8B8).withOpacity(0.4),
                              blurRadius: 30,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: Icon(Icons.diamond_rounded, size: 100, color: const Color(0xFFF6A8B8)),
                      ),
                      
                      const SizedBox(height: 30),
                      
                      Text(
                        "GlowMate Premium",
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF333333),
                          letterSpacing: 1.2,
                        ),
                      ),
                      
                      const SizedBox(height: 10),
                      
                      Text(
                        "Unlock Your Beauty Potential",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Kartu Harga Glassmorphism
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.star, color: Colors.amber[600], size: 20),
                                const SizedBox(width: 8),
                                Text("Best Value", style: TextStyle(color: Colors.amber[700], fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "Rp 50.000",
                              style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: const Color(0xFFF6A8B8)),
                            ),
                            Text(
                              "/ bulan",
                              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                            ),
                            const Divider(height: 30, thickness: 1, color: Colors.grey),
                            
                            // Fitur List
                            _buildFeatureItem("Buat Channel Sendiri"),
                            _buildFeatureItem("Analisis Kulit AI Unlimited"),
                            _buildFeatureItem("Badge Eksklusif"),
                            _buildFeatureItem("Prioritas Support"),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Tombol Utama Futuristik
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleUpgrade,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF6A8B8),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            elevation: 8,
                            shadowColor: const Color(0xFFF6A8B8).withOpacity(0.6),
                          ),
                          child: _isLoading
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                              : const Text("UPGRADE SEKARANG", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      Text(
                        "Secure Payment by Midtrans",
                        style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 18, color: const Color(0xFF4CAF50)),
          const SizedBox(width: 10),
          Text(text, style: const TextStyle(fontSize: 15, color: Color(0xFF444444))),
        ],
      ),
    );
  }
}
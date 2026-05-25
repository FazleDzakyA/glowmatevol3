import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ✅ Import Halaman Lain & Route
import '../tutorials/tutorials_page.dart';
import '../profile/profile_page.dart';
import '../chatbot/chatbot_page.dart';
import '../scan/face_scan_page.dart';
import '../community/community_page.dart'; 
import '../../routes/app_routes.dart';
import '../../services/api_service.dart'; 

// ✅ Import Controller
import '../../controllers/auth_controller.dart';
import 'bottom_nav.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  int index = 0;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final pages = [
    const HomeMainContent(),
    const ChatbotPage(),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (index == 0) return true;
        else {
          setState(() => index = 0);
          return false;
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: IndexedStack(
          index: index,
          children: pages,
        ),
        bottomNavigationBar: BottomNav(
          currentIndex: index,
          onTap: (i) {
            setState(() => index = i);
          },
        ),
      ),
    );
  }
}

class HomeMainContent extends StatefulWidget {
  const HomeMainContent({super.key});

  @override
  State<HomeMainContent> createState() => _HomeMainContentState();
}

class _HomeMainContentState extends State<HomeMainContent> {
  // ✅ STATE UNTUK SKOR KESEHATAN KULIT DARI FIREBASE
  int? _skinHealthScore; 
  bool _isLoadingScore = true;

  // ✅ STATE UNTUK JUMLAH CHANNEL
  int _channelCount = 0;
  bool _isLoadingCount = true;

  @override
  void initState() {
    super.initState();
    _fetchSkinHealthScore(); // Ambil skor kesehatan kulit
    _fetchChannelCount();    // Ambil jumlah channel
  }

  // ✅ METHOD MENGAMBIL SKOR KESEHATAN KULIT TERAKHIR DARI FIREBASE
  Future<void> _fetchSkinHealthScore() async {
    final authCtrl = context.read<AuthController>();
    
    // Cek Login Status via AuthController
    if (authCtrl.userId == null) {
      print("⚠️ WARNING: User belum login (ID Null)! Tidak bisa ambil data scan.");
      setState(() {
        _skinHealthScore = null;
        _isLoadingScore = false;
      });
      return;
    }

    print("🔍 Mencari data scan untuk User ID: ${authCtrl.userId}");

    try {
      // Opsi A: Jika Dokumen User di Firestore menggunakan ID Laravel sebagai Document ID
      // Pastikan saat save di face_scan_page, kamu menggunakan doc(authCtrl.userId.toString())
      final docRef = FirebaseFirestore.instance.collection('users').doc(authCtrl.userId.toString());
      
      // Cek apakah dokumen ada
      final docSnap = await docRef.get();
      
      if (!docSnap.exists) {
        print("⚠️ Dokumen user dengan ID ${authCtrl.userId} TIDAK DITEMUKAN di Firestore.");
        print("💡 Pastikan struktur DB: users/{USER_ID_LARAVEL}/scanHistory/{DOC_ID}");
        setState(() => _isLoadingScore = false);
        return;
      }

      // Ambil sub-collection scanHistory
      final snapshot = await docRef.collection('scanHistory')
          .orderBy('date', descending: true)
          .limit(1)
          .get();

      print("📡 Ditemukan ${snapshot.docs.length} riwayat scan.");

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        print("📄 Data mentah: $data");
        
        if (data.containsKey('healthScore')) {
          final score = data['healthScore'];
          if (mounted) {
            setState(() {
              _skinHealthScore = score is int ? score : (score is double ? score.toInt() : null);
              _isLoadingScore = false;
            });
            print("✅ Skor berhasil dimuat: $_skinHealthScore");
          }
        } else {
          print("❌ Field 'healthScore' tidak ada di dokumen scan.");
          if (mounted) setState(() => _isLoadingScore = false);
        }
      } else {
        print("ℹ️ Belum ada riwayat scan untuk user ini.");
        if (mounted) setState(() {
          _skinHealthScore = null; 
          _isLoadingScore = false;
        });
      }

    } catch (e) {
      print("❌ ERROR FATAL saat ambil data: $e");
      if (mounted) setState(() => _isLoadingScore = false);
    }
  }

  // ✅ METHOD MENGAMBIL JUMLAH CHANNEL DARI API
  Future<void> _fetchChannelCount() async {
    try {
      final count = await ApiService.getChannelCount();
      if (mounted) {
        setState(() {
          _channelCount = count;
          _isLoadingCount = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching channel count: $e");
      if (mounted) {
        setState(() => _isLoadingCount = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final authCtrl = context.watch<AuthController>(); // ✅ WATCH AUTH CONTROLLER
    final primaryColor = const Color(0xFFF6A8B8);
    final secondaryColor = const Color(0xFFE91E63);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          await _fetchSkinHealthScore();
          await _fetchChannelCount();
        },
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ HEADER SAPAAN YANG PERSONAL
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Hello,",
                        style: TextStyle(
                          fontSize: 16,
                          color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        "${authCtrl.displayName} ✨",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      
                      // ✅ PERBAIKAN TAMPILAN UID MENGGUNAKAN CONSUMER
                      Consumer<AuthController>(
                        builder: (context, ctrl, child) {
                          return Text(
                            "UID: ${ctrl.userId ?? 'Not Logged In'}",
                            style: TextStyle(
                              fontSize: 10, 
                              color: ctrl.userId != null ? Colors.green : Colors.redAccent,
                              fontWeight: FontWeight.bold
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  CircleAvatar(
                    backgroundColor: primaryColor.withOpacity(0.1),
                    child: IconButton(
                      icon: Icon(Icons.face_retouching_natural_outlined, color: secondaryColor),
                      onPressed: () => Navigator.pushNamed(context, AppRoutes.faceScan),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),

              // ✅ TIP CARD YANG MENARIK
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor, secondaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: secondaryColor.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.lightbulb, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          "Tip Hari Ini",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Jangan lupa pakai sunscreen sebelum keluar rumah ya! SPF 30+ adalah must untuk melindungi kulit dari UV.",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.95),
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ChatbotPage()),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5)],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.chat_bubble_outline_rounded, color: secondaryColor, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              "Ask GlowBot",
                              style: TextStyle(color: secondaryColor, fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ✅ STATS CARDS YANG RAPI
              Text(
                "Your Progress",
                style: TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold, 
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // ✅ KARTU SKIN HEALTH DENGAN DATA DINAMIS
                  _buildStatCard(
                    icon: Icons.show_chart_rounded,
                    value: _isLoadingScore ? "..." : (_skinHealthScore != null ? "${_skinHealthScore}%" : "-"),
                    label: "Skin Health",
                    color: const Color(0xFF00BCD4), // Cyan
                    isDarkMode: isDarkMode,
                    onTap: () => Navigator.pushNamed(context, AppRoutes.faceScan),
                  ),
                  _buildStatCard(
                    icon: Icons.emoji_events_rounded,
                    value: "${authCtrl.badgeCount}",
                    label: "Badges",
                    color: Colors.amber[700]!, // Gold
                    isDarkMode: isDarkMode,
                    onTap: () => Navigator.pushNamed(context, AppRoutes.badge),
                  ),
                  _buildStatCard(
                    icon: Icons.groups_rounded,
                    value: _isLoadingCount ? "..." : "$_channelCount",
                    label: "Community",
                    color: const Color(0xFF9C27B0), // Purple
                    isDarkMode: isDarkMode,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CommunityPage()),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // ✅ MAIN FEATURES GRID
              Text(
                "Explore Features",
                style: TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold, 
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.1,
                children: [
                  _buildFeatureCard(
                    title: "Scan Skin",
                    icon: Icons.center_focus_strong_rounded,
                    color: const Color(0xFF00BCD4),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FaceScanPage())),
                    isDarkMode: isDarkMode,
                  ),
                  _buildFeatureCard(
                    title: "GlowBot",
                    icon: Icons.smart_toy_outlined,
                    color: const Color(0xFFE91E63),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatbotPage())),
                    isDarkMode: isDarkMode,
                  ),
                  _buildFeatureCard(
                    title: "Tutorial",
                    icon: Icons.menu_book_rounded,
                    color: const Color(0xFF9C27B0),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TutorialsPage())),
                    isDarkMode: isDarkMode,
                  ),
                  _buildFeatureCard(
                    title: "Profile",
                    icon: Icons.person_outline_rounded,
                    color: Colors.grey[600]!,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage())),
                    isDarkMode: isDarkMode,
                  ),
                ],
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ WIDGET STAT CARD YANG MODERN
  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required bool isDarkMode,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1E1E2E) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05), blurRadius: 10, offset: const Offset(0, 4))],
            border: Border.all(color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.grey.shade100),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 24, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                value,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12, 
                  color: isDarkMode ? Colors.white70 : Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ WIDGET FEATURE CARD YANG ELEGAN
  Widget _buildFeatureCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool isDarkMode,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E1E2E) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDarkMode ? 0.4 : 0.08), blurRadius: 12, offset: const Offset(0, 4))],
          border: Border.all(color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.grey.shade100),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 60,
              width: 60,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15, 
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
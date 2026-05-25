import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart'; // ✅ IMPORT PROVIDER
import '../../models/skin_analysis_result.dart';
import '../../controllers/auth_controller.dart'; // ✅ IMPORT AUTH CONTROLLER

class FaceScanPage extends StatefulWidget {
  const FaceScanPage({super.key});

  @override
  State<FaceScanPage> createState() => _FaceScanPageState();
}

class _FaceScanPageState extends State<FaceScanPage> with SingleTickerProviderStateMixin {
  int _currentState = 0; // 0: start, 1: analyzing, 2: result
  late SkinAnalysisResult _result;
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  SkinAnalysisResult? _latestScanResult;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeIn);
    
    _loadLatestScan();
    if (!kIsWeb) {
      _initializeCamera();
    }
  }

  // ✅ LOAD DATA MENGGUNAKAN AUTH CONTROLLER USER ID
  Future<void> _loadLatestScan() async {
    final authCtrl = context.read<AuthController>();
    if (authCtrl.userId == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(authCtrl.userId.toString()) // ✅ GUNAKAN ID LARAVEL
          .collection('scanHistory')
          .orderBy('date', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        final result = SkinAnalysisResult.fromMap(data);
        if (mounted) {
          setState(() {
            _latestScanResult = result;
          });
        }
      }
    } catch (e) {
      print("Error loading scan: $e");
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras[0],
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
      );

      await _cameraController!.initialize();
      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      print("Error initializing camera: $e");
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _confirmStartScan() async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF1E1E2E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('✨ Mulai Analisis?', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.bold)),
        content: Text('AI GlowMate akan memindai kondisi kulit wajahmu secara real-time.', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF6A8B8),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Mulai Scan'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _startScan();
    }
  }

  Future<void> _startScan() async {
    setState(() => _currentState = 1);
    _animationController.reset();
    _animationController.forward();

    if (kIsWeb) {
      await Future.delayed(const Duration(seconds: 3));
      _result = _simulateAIResult();
    } else {
      await _analyzeFace();
    }

    await _saveToFirestore(_result);

    setState(() => _currentState = 2);
  }

  Future<void> _analyzeFace() async {
    if (_cameraController == null || !_isCameraInitialized) return;

    try {
      final XFile image = await _cameraController!.takePicture();
      final inputImage = InputImage.fromFilePath(image.path);
      final faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          enableClassification: true,
          enableLandmarks: true,
          enableContours: true,
          enableTracking: true,
          minFaceSize: 0.1,
        ),
      );

      final faces = await faceDetector.processImage(inputImage);
      _result = _simulateAIResultFromDetection(faces);
      await faceDetector.close();
    } catch (e) {
      print('Error analyzing face: $e');
      _result = _simulateAIResult();
    }
  }

  SkinAnalysisResult _simulateAIResultFromDetection(List<Face> faces) {
    if (faces.isEmpty) {
      return _simulateAIResult();
    }

    final face = faces.first;
    final boundingBox = face.boundingBox;

    return SkinAnalysisResult(
      skinType: boundingBox.width > 200 ? "Oily" : "Combination",
      healthScore: 75 + (faces.length * 5),
      concerns: [
        if (face.smilingProbability != null && face.smilingProbability! > 0.5) "Fine Lines",
        if (face.leftEyeOpenProbability != null && face.leftEyeOpenProbability! < 0.5) "Dark Circles",
        "Enlarged Pores",
        "Mild Acne",
        "Dark Spots",
      ],
    );
  }

  SkinAnalysisResult _simulateAIResult() {
    return SkinAnalysisResult(
      skinType: "Combination",
      healthScore: 78,
      concerns: [
        "Enlarged Pores",
        "Mild Acne",
        "Dark Spots",
      ],
    );
  }

  // ✅ SAVE DATA MENGGUNAKAN AUTH CONTROLLER USER ID (DIPERBAIKI FINAL)
  Future<void> _saveToFirestore(SkinAnalysisResult result) async {
    final authCtrl = context.read<AuthController>();
    
    if (authCtrl.userId == null) {
      print("❌ Error: User ID tidak ditemukan. Tidak bisa simpan data.");
      return;
    }

    final userId = authCtrl.userId.toString(); // Contoh: "1"
    print("💾 Menyimpan data scan ke Firestore untuk User ID: $userId");

    final data = {
      'date': FieldValue.serverTimestamp(),
      'skinType': result.skinType,
      'healthScore': result.healthScore,
      'concerns': result.concerns,
    };

    try {
      // ✅ LANGKAH 1: Pastikan dokumen user ada dengan set field minimal
      final userDocRef = FirebaseFirestore.instance.collection('users').doc(userId);
      
      // Cek apakah dokumen sudah ada
      final docSnap = await userDocRef.get();
      
      if (!docSnap.exists) {
        // Jika belum ada, buat dokumen baru dengan field minimal
        await userDocRef.set({
          'laravel_user_id': int.parse(userId),
          'created_at': FieldValue.serverTimestamp(),
          'last_updated': FieldValue.serverTimestamp(),
        });
        print("   📄 Dokumen user $userId dibuat pertama kali.");
      } else {
        // Jika sudah ada, update last_updated
        await userDocRef.update({
          'last_updated': FieldValue.serverTimestamp(),
        });
        print("   🔄 Dokumen user $userId sudah ada, diupdate last_updated.");
      }

      // ✅ LANGKAH 2: Simpan ke sub-collection scanHistory
      await userDocRef.collection('scanHistory').add(data);
      
      print("✅ Data berhasil disimpan ke users/$userId/scanHistory/");
    } catch (e) {
      print("❌ Gagal menyimpan data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    const primaryPink = Color(0xFFF6A8B8);
    const deepPink = Color(0xFFE91E63);

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFFFF9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("Skin Analyzer", style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: isDarkMode ? Colors.white : Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔥 Card Hasil Scan Terakhir (Jika Ada)
              if (_latestScanResult != null && _currentState == 0) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [primaryPink.withOpacity(0.1), Colors.white]),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: primaryPink.withOpacity(0.3)),
                    boxShadow: [BoxShadow(blurRadius: 10, color: primaryPink.withOpacity(0.1))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Hasil Terakhir", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDarkMode ? Colors.white : Colors.black87)),
                          Icon(Icons.history, color: primaryPink),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: primaryPink,
                            child: Text("${_latestScanResult!.healthScore}%", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Tipe Kulit: ${_latestScanResult!.skinType}", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDarkMode ? Colors.white : Colors.black87)),
                                Text("Masalah: ${_latestScanResult!.concerns.take(2).join(', ')}...", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],

              // --- STATE 0: START SCAN ---
              if (_currentState == 0) ...[
                Center(
                  child: Column(
                    children: [
                      _buildCameraPreview(isDarkMode),
                      const SizedBox(height: 32),
                      _buildTipsCard(isDarkMode),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _confirmStartScan,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryPink,
                            foregroundColor: Colors.white,
                            elevation: 8,
                            shadowColor: primaryPink.withOpacity(0.4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt_rounded, size: 24),
                              SizedBox(width: 12),
                              Text("Start Scan Now", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // --- STATE 1: ANALYZING ---
              if (_currentState == 1) ...[
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildAnalyzingView(isDarkMode),
                ),
              ],

              // --- STATE 2: RESULT ---
              if (_currentState == 2) ...[
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: _buildResultView(_result, isDarkMode, primaryPink, deepPink),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraPreview(bool isDarkMode) {
    if (kIsWeb) {
      return Container(
        height: 320,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(blurRadius: 20, color: Colors.black.withOpacity(0.2))],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Center(child: Text("Webcam Active", style: TextStyle(color: Colors.white54))),
            Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFF6A8B8).withOpacity(0.8), width: 3),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(blurRadius: 15, spreadRadius: 5, color: const Color(0xFFF6A8B8).withOpacity(0.3))],
              ),
            ),
            const Positioned(bottom: 30, child: Text("Posisikan wajah di tengah", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          ],
        ),
      );
    } else {
      if (!_isCameraInitialized) {
        return Container(height: 320, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(24)), child: const Center(child: CircularProgressIndicator()));
      }
      return Container(
        height: 320,
        decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(blurRadius: 20, color: Colors.black.withOpacity(0.2))]),
        child: Stack(alignment: Alignment.center, children: [
          CameraPreview(_cameraController!),
          Container(width: 240, height: 240, decoration: BoxDecoration(border: Border.all(color: const Color(0xFFF6A8B8).withOpacity(0.8), width: 3), shape: BoxShape.circle, boxShadow: [BoxShadow(blurRadius: 15, spreadRadius: 5, color: const Color(0xFFF6A8B8).withOpacity(0.3))])),
          const Positioned(bottom: 30, child: Text("Posisikan wajah di tengah", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
        ]),
      );
    }
  }

  Widget _buildAnalyzingView(bool isDarkMode) {
    return Container(
      height: 400,
      decoration: BoxDecoration(color: isDarkMode ? const Color(0xFF1E1E2E) : Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black.withOpacity(0.05))]),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFF6A8B8).withOpacity(0.1)),
              child: const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF6A8B8)), strokeWidth: 4),
            ),
            const SizedBox(height: 24),
            Text("Menganalisis Wajah...", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87)),
            const SizedBox(height: 8),
            Text("AI sedang mendeteksi pori, jerawat, & tekstur", style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  Widget _buildResultView(SkinAnalysisResult result, bool isDarkMode, Color primaryPink, Color deepPink) {
    return Column(
      children: [
        // Score Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(gradient: LinearGradient(colors: [primaryPink, deepPink]), borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(blurRadius: 15, color: primaryPink.withOpacity(0.4))]),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Skin Health Score", style: TextStyle(color: Colors.white70, fontSize: 14)),
                  Icon(Icons.check_circle, color: Colors.white.withOpacity(0.8)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("${result.healthScore}", style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w800, height: 1)),
                  const SizedBox(width: 8),
                  Text("/ 100", style: const TextStyle(color: Colors.white70, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(value: result.healthScore / 100, backgroundColor: Colors.white.withOpacity(0.2), color: Colors.white, minHeight: 10),
              ),
              const SizedBox(height: 16),
              Text("Tipe Kulit: ${result.skinType}", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        
        const SizedBox(height: 32),
        
        Align(alignment: Alignment.centerLeft, child: Text("Deteksi Masalah Kulit", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87))),
        const SizedBox(height: 16),
        
        ...result.concerns.map((concern) => _buildConcernCard(concern, isDarkMode)).toList(),
        
        const SizedBox(height: 32),
        
        Align(alignment: Alignment.centerLeft, child: Text("Rekomendasi GlowMate", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87))),
        const SizedBox(height: 16),
        
        _buildRecommendationList(isDarkMode, primaryPink),
        
        const SizedBox(height: 32),
        
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/chatbot', arguments: result.toAIPrompt());
                },
                style: OutlinedButton.styleFrom(foregroundColor: primaryPink, side: BorderSide(color: primaryPink), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text("Ask GlowBot"),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  setState(() => _currentState = 0);
                },
                style: ElevatedButton.styleFrom(backgroundColor: primaryPink, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text("Scan Again"),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConcernCard(String concern, bool isDarkMode) {
    final isSerious = concern.contains("Pores") || concern.contains("Dark") || concern.contains("Acne");
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.grey.shade100),
        boxShadow: [BoxShadow(blurRadius: 5, color: Colors.black.withOpacity(0.03))],
      ),
      child: Row(
        children: [
          Icon(isSerious ? Icons.warning_amber_rounded : Icons.info_outline, color: isSerious ? const Color(0xFFFFC107) : const Color(0xFF4CAF50), size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(concern, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isDarkMode ? Colors.white : Colors.black87)),
                const SizedBox(height: 4),
                Text(isSerious ? "Perlu perhatian khusus" : "Kondisi ringan", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: (isSerious ? const Color(0xFFFFC107) : const Color(0xFF4CAF50)).withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text(isSerious ? "Medium" : "Low", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isSerious ? const Color(0xFFFFC107) : const Color(0xFF4CAF50)))),
        ],
      ),
    );
  }

  Widget _buildRecommendationList(bool isDarkMode, Color primaryPink) {
    return Column(
      children: [
        _RecommendationItem(index: 1, text: "Gunakan cleanser dengan salicylic acid", isDarkMode: isDarkMode, color: primaryPink),
        _RecommendationItem(index: 2, text: "Aplikasikan niacinamide serum pagi hari", isDarkMode: isDarkMode, color: primaryPink),
        _RecommendationItem(index: 3, text: "Wajib pakai sunscreen SPF 30+ setiap hari", isDarkMode: isDarkMode, color: primaryPink),
        _RecommendationItem(index: 4, text: "Clay mask 2x seminggu untuk pori-pori", isDarkMode: isDarkMode, color: primaryPink),
      ],
    );
  }

  Widget _buildTipsCard(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: isDarkMode ? const Color(0xFF1E1E2E) : Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.grey.shade100)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(Icons.lightbulb_outline, color: const Color(0xFFFFC107)), const SizedBox(width: 8), Text("Tips Scan Terbaik", style: TextStyle(fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87))]),
          const SizedBox(height: 12),
          _TipItem(icon: Icons.sunny, text: "Pencahayaan terang & natural", isDarkMode: isDarkMode),
          _TipItem(icon: Icons.face_retouching_natural, text: "Wajah bersih tanpa makeup", isDarkMode: isDarkMode),
          _TipItem(icon: Icons.camera_enhance, text: "Jarak kamera ± 30-40 cm", isDarkMode: isDarkMode),
        ],
      ),
    );
  }
}

// ✅ WIDGET KECIL DI LUAR CLASS STATE
class _RecommendationItem extends StatelessWidget {
  final int index;
  final String text;
  final bool isDarkMode;
  final Color color;

  const _RecommendationItem({required this.index, required this.text, required this.isDarkMode, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(width: 28, height: 28, decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Center(child: Text("$index", style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)))),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: TextStyle(fontSize: 14, color: isDarkMode ? Colors.white70 : Colors.black87))),
        ],
      ),
    );
  }
}

class _TipItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isDarkMode;

  const _TipItem({required this.icon, required this.text, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Text(text, style: TextStyle(fontSize: 13, color: isDarkMode ? Colors.white70 : Colors.black87)),
        ],
      ),
    );
  }
}
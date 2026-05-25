import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../controllers/auth_controller.dart';
import 'dart:convert';

class TrackerPage extends StatefulWidget {
  const TrackerPage({super.key});

  @override
  State<TrackerPage> createState() => _TrackerPageState();
}

class _TrackerPageState extends State<TrackerPage> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  // ✅ DATA SKINCARE DENGAN ID UNIK
  List<Map<String, dynamic>> morning = [
    {"id": 1, "name": "Cleanser", "checked": false},
    {"id": 2, "name": "Toner", "checked": false},
    {"id": 3, "name": "Serum", "checked": false},
    {"id": 4, "name": "Moisturizer", "checked": false},
    {"id": 5, "name": "Sunscreen", "checked": false},
  ];

  List<Map<String, dynamic>> evening = [
    {"id": 6, "name": "Cleanser", "checked": false},
    {"id": 7, "name": "Toner", "checked": false},
    {"id": 8, "name": "Night Cream", "checked": false},
  ];

  @override
  void initState() {
    super.initState();
    _loadTodayProgress();
    
    // Animasi untuk progress circle
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 1. LOAD DATA DARI DATABASE
  Future<void> _loadTodayProgress() async {
    setState(() => _isLoading = true);
    try {
      final savedIds = await ApiService.getTodayProgress();
      
      setState(() {
        for (var item in morning) {
          item['checked'] = savedIds.contains(item['id']);
        }
        for (var item in evening) {
          item['checked'] = savedIds.contains(item['id']);
        }
      });
      
      // Start animation after data loaded
      _controller.forward(from: 0.0);
    } catch (e) {
      print("Error loading progress: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal memuat progress: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 2. SAVE DATA & HANDLE BADGE
  Future<void> _saveDataToLaravel() async {
    setState(() => _isLoading = true);

    try {
      List<int> completedIds = [];
      for (var item in morning) {
        if (item['checked']) completedIds.add(item['id']);
      }
      for (var item in evening) {
        if (item['checked']) completedIds.add(item['id']);
      }

      final responseMap = await ApiService.saveTodayProgress(completedIds);
      final newBadges = responseMap['new_badges'] as List<dynamic>?;
      
      if (newBadges != null && newBadges.isNotEmpty) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Icon(Icons.emoji_events, color: Colors.amber[700], size: 30),
                  const SizedBox(width: 10),
                  const Text("🎉 Selamat!", style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Kamu mendapatkan badge baru karena konsistensimu!"),
                  const SizedBox(height: 15),
                  ...newBadges.map((key) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Color(0xFFE91E63), size: 20),
                        const SizedBox(width: 10),
                        Text(_getBadgeName(key.toString()), style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )).toList(),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Keren!", style: TextStyle(color: Color(0xFFE91E63))),
                ),
              ],
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.white),
                  SizedBox(width: 10),
                  Text("Progress harian tersimpan! ✨", style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              backgroundColor: const Color(0xFF4CAF50),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }

      await context.read<AuthController>().fetchBadges();

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal menyimpan: $e"), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getBadgeName(String key) {
    switch (key) {
      case 'newbie_glow': return 'Newbie Glow';
      case 'consistent_cutie': return 'Consistent Cutie';
      case 'spf_warrior': return 'SPF Warrior';
      case 'skincare_scholar': return 'Skincare Scholar';
      case 'hydration_hero': return 'Hydration Hero';
      case 'night_owl': return 'Night Owl';
      case 'glass_skin_master': return 'Glass Skin Master';
      default: return key;
    }
  }

  int get totalItems => morning.length + evening.length;
  int get completedItems => morning.where((e) => e["checked"]).length + evening.where((e) => e["checked"]).length;
  double get progress => totalItems == 0 ? 0.0 : completedItems / totalItems;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFFF8A9BB);
    final secondaryColor = const Color(0xFFE91E63);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFFFF0F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.arrow_back_ios_new, color: isDarkMode ? Colors.white : Colors.black87, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "My Routine",
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w800,
            fontSize: 24,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor: primaryColor.withOpacity(0.2),
              child: IconButton(
                icon: Icon(Icons.save_outlined, color: secondaryColor),
                onPressed: _isLoading ? null : _saveDataToLaravel,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: secondaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 100, 20, 100), // Padding bawah untuk FAB
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ✅ PROGRESS CARD FUTURISTIK
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryColor, secondaryColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: secondaryColor.withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Daily Goal",
                              style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              "$completedItems / $totalItems Steps",
                              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              "${(progress * 100).toInt()}% Completed",
                              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                            ),
                          ],
                        ),
                        ScaleTransition(
                          scale: _scaleAnimation,
                          child: SizedBox(
                            width: 80,
                            height: 80,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                CircularProgressIndicator(
                                  value: progress,
                                  strokeWidth: 8,
                                  backgroundColor: Colors.white.withOpacity(0.3),
                                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                                Icon(
                                  progress == 1.0 ? Icons.check_circle : Icons.spa,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 30),

                  // ✅ MORNING ROUTINE
                  _buildSectionHeader("☀️ Morning Glow", isDarkMode, primaryColor),
                  const SizedBox(height: 15),
                  ..._buildRoutineList(morning, true, isDarkMode, primaryColor),

                  const SizedBox(height: 30),

                  // ✅ EVENING ROUTINE
                  _buildSectionHeader("🌙 Night Repair", isDarkMode, primaryColor),
                  const SizedBox(height: 15),
                  ..._buildRoutineList(evening, false, isDarkMode, primaryColor),
                ],
              ),
            ),
      // ✅ FLOATING ACTION BUTTON UNTUK SAVE
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _saveDataToLaravel,
        backgroundColor: secondaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.cloud_upload_outlined),
        label: const Text("Save Progress", style: TextStyle(fontWeight: FontWeight.bold)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 10,
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDarkMode, Color primaryColor) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildRoutineList(List<Map<String, dynamic>> list, bool isMorning, bool isDarkMode, Color primaryColor) {
    return list.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final isChecked = item["checked"];

      return Dismissible(
        key: Key('${isMorning ? 'm' : 'e'}_${item['id']}'),
        direction: DismissDirection.endToStart,
        confirmDismiss: (direction) async {
          bool? result = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text("Hapus Rutinitas?"),
              content: Text("Yakin hapus '${item['name']}'?"),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Batal")),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                  child: const Text("Hapus"),
                ),
              ],
            ),
          );
          return result == true;
        },
        onDismissed: (direction) {
          setState(() {
            if (isMorning) morning.removeAt(index); else evening.removeAt(index);
          });
        },
        background: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(20)),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: const Icon(Icons.delete_outline, color: Colors.white),
        ),
        child: GestureDetector(
          onTap: () {
            setState(() {
              item["checked"] = !item["checked"];
              if (item["checked"]) _controller.forward(from: 0.0); // Trigger animation
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1E1E2E) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isChecked ? primaryColor : (isDarkMode ? Colors.white.withOpacity(0.05) : Colors.grey.shade200),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: isChecked ? primaryColor.withOpacity(0.2) : Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item["name"],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isChecked ? FontWeight.bold : FontWeight.w500,
                      color: isDarkMode ? Colors.white : Colors.black87,
                      decoration: isChecked ? TextDecoration.lineThrough : null,
                      decorationColor: isDarkMode ? Colors.white70 : Colors.black45,
                    ),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isChecked ? primaryColor : (isDarkMode ? const Color(0xFF2C2C3E) : Colors.grey.shade100),
                    border: Border.all(color: isChecked ? primaryColor : Colors.grey.shade300),
                  ),
                  child: isChecked
                      ? const Icon(Icons.check, size: 18, color: Colors.white)
                      : null,
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }
}
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../controllers/auth_controller.dart';
import '../../services/api_service.dart';

String _cleanUserId(String email) {
  return email.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
}

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  
  String _displayName = ''; 
  String _currentEmail = ''; 
  
  Uint8List? _selectedImageBytes; // Gunakan Bytes untuk Universal Support
  
  bool _isLoading = false; 
  Uint8List? _localImageBytes;
  
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
    
    _loadUserData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    if (!mounted) return;
    
    try {
      final authCtrl = context.read<AuthController>();
      _currentEmail = authCtrl.email;
      _displayName = authCtrl.displayName;

      // Jika ada gambar profil dari AuthController (dari Backend), kita bisa tampilkan langsung
      // Tapi jika ingin load dari local storage sebagai fallback/cache:
      if (_currentEmail.isNotEmpty) {
        await _loadLocalImage(_currentEmail);
      }
    } catch (e) {
      print("❌ ERROR loading user data: $e");
    }
  }

  Future<void> _loadLocalImage(String email) async {
    final prefs = await SharedPreferences.getInstance();
    Uint8List? bytes;
    
    String userId = _cleanUserId(email);
    // Kita hanya cek base64 untuk Web/Mobile consistency jika disimpan sebelumnya
    String key = 'profileImageBase64_$userId'; 

    final base64Str = prefs.getString(key);
    if (base64Str != null) {
      try { bytes = base64Decode(base64Str); } catch (e) {}
    }
    
    if (mounted && bytes != null) {
      setState(() => _localImageBytes = bytes);
    }
  }

  Future<void> _confirmChangeImage() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('✨ Ganti foto profil?'),
        content: const Text('Pilih foto baru dari galeri!'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true), 
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF8A9BB), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), 
            child: const Text('Mauu!', style: TextStyle(color: Colors.white))
          ),
        ],
      ),
    ).then((confirm) { 
      if (confirm == true) _pickImage(); 
    });
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      // Selalu convert ke Bytes agar universal (Web & Mobile)
      final bytes = await picked.readAsBytes();
      
      if (mounted) {
        setState(() {
          _selectedImageBytes = bytes;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_currentEmail.isEmpty) return;

    if (mounted) setState(() => _isLoading = true);

    try {
      String newName = _displayName.trim();
      
      // Cek apakah ada perubahan
      bool hasImageChange = _selectedImageBytes != null;
      bool hasNameChange = newName.isNotEmpty && newName != context.read<AuthController>().displayName;

      if (!hasImageChange && !hasNameChange) {
         throw Exception("Tidak ada perubahan data.");
      }

      // Panggil ApiService.updateProfile yang sudah diupdate untuk menerima Uint8List
      final response = await ApiService.updateProfile(
        hasNameChange ? newName : null, 
        hasImageChange ? _selectedImageBytes : null,
        hasImageChange ? 'profile.jpg' : null
      );

      if (response['status'] == 'success') {
         final user = response['data']['user'];
         
         // Update AuthController
         context.read<AuthController>().setLaravelData(
            user['name'], 
            user['email'], 
            user['profile_image'],
            id: user['id'] // Pastikan ID juga terupdate jika perlu
         );

         // Simpan cache lokal (Base64) agar cepat saat reload
         if (_selectedImageBytes != null) {
            final prefs = await SharedPreferences.getInstance();
            String userId = _cleanUserId(_currentEmail);
            await prefs.setString('profileImageBase64_$userId', base64Encode(_selectedImageBytes!));
         }

         if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(children: [Icon(Icons.check_circle, color: Colors.white), SizedBox(width: 10), Text("Profil berhasil diperbarui! ✨")]),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );
            Navigator.pop(context, true);
         }
      } else {
         throw Exception(response['message'] ?? 'Gagal update profil');
      }

    } catch (e) {
      print("❌ ERROR saving profile: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal menyimpan: ${e.toString()}"), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final authCtrl = context.watch<AuthController>();
    final primaryColor = const Color(0xFFF8A9BB);

    // Tampilan Loading Full Screen
    if (_isLoading && _displayName.isEmpty) {
       return Scaffold(
        backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFFFF9FA),
        body: Center(child: CircularProgressIndicator(color: primaryColor))
      );
    }

    return Scaffold(
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
          "Edit Profile", 
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 20)
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor: primaryColor.withOpacity(0.2),
              child: IconButton(
                icon: Icon(Icons.check, color: primaryColor), 
                onPressed: _isLoading ? null : _saveProfile
              ),
            ),
          )
        ]
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              Container(
                width: double.infinity,
                height: 150,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor.withOpacity(0.3), primaryColor.withOpacity(0.1)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
                ),
              ),
              
              const SizedBox(height: 60),

              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: isDarkMode ? const Color(0xFF121212) : Colors.white, width: 6),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: GestureDetector(
                      onTap: _isLoading ? null : _confirmChangeImage,
                      child: CircleAvatar(
                        radius: 64,
                        backgroundColor: Colors.grey.shade200,
                        // Prioritas Gambar: 1. Yang baru dipilih (_selectedImageBytes), 2. Dari Server (authCtrl.profileImage), 3. Cache Lokal (_localImageBytes)
                        backgroundImage: _selectedImageBytes != null 
                            ? MemoryImage(_selectedImageBytes!) 
                            : (authCtrl.profileImage.isNotEmpty 
                                ? NetworkImage(authCtrl.profileImage) as ImageProvider 
                                : (_localImageBytes != null ? MemoryImage(_localImageBytes!) : null)),
                        child: (_selectedImageBytes == null && authCtrl.profileImage.isEmpty && _localImageBytes == null) 
                            ? const Icon(Icons.person, size: 60, color: Colors.grey) 
                            : null,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _isLoading ? null : _confirmChangeImage,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: isDarkMode ? const Color(0xFF121212) : Colors.white, width: 3),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 5)],
                        ),
                        child: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Display Name",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDarkMode ? Colors.white70 : Colors.grey.shade600),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue: _displayName,
                        style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87, fontSize: 16),
                        decoration: InputDecoration(
                          hintText: "Enter your name",
                          filled: true,
                          fillColor: isDarkMode ? const Color(0xFF1E1E2E) : Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: primaryColor, width: 2),
                          ),
                        ),
                        validator: (v) => v!.trim().isEmpty ? "Nama wajib diisi" : null,
                        onChanged: (v) => _displayName = v,
                      ),
                      
                      const SizedBox(height: 24),
                      
                      Text(
                        "Email Address",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDarkMode ? Colors.white70 : Colors.grey.shade600),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue: _currentEmail,
                        enabled: false,
                        style: TextStyle(color: isDarkMode ? Colors.white54 : Colors.grey.shade500, fontSize: 16),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: isDarkMode ? const Color(0xFF1E1E2E).withOpacity(0.5) : Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: Icon(Icons.email_outlined, color: isDarkMode ? Colors.white54 : Colors.grey.shade400),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
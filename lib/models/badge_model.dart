class BadgeModel {
  final int id;
  final String name;
  final String description;
  final String icon;
  final String key;       // ✅ WAJIB: Untuk identifikasi badge di backend
  final String rarity;    // ✅ WAJIB: Untuk warna UI (gold/silver/bronze)
  final bool isUnlocked;
  final DateTime? unlockedAt;
  
  // ✅ Tambahan untuk UI yang lebih kaya & informatif
  final String requirement; // Contoh: "Catat skincare 3 hari berturut-turut"
  final double progress;    // 0.0 sampai 1.0 (untuk progress bar)

  BadgeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.key,
    required this.rarity,
    required this.isUnlocked,
    this.unlockedAt,
    this.requirement = '', 
    this.progress = 0.0,
  });

  factory BadgeModel.fromJson(Map<String, dynamic> json) {
    // Handle kemungkinan field 'is_unlocked' atau 'isUnlocked' dari backend
    final bool isUnlockedValue = json['is_unlocked'] ?? json['isUnlocked'] ?? false;
    
    // Handle kemungkinan field 'unlocked_at' atau 'unlockedAt'
    final String? unlockedAtStr = json['unlocked_at'] ?? json['unlockedAt'];

    return BadgeModel(
      id: json['id'],
      name: json['name'] ?? json['title'] ?? 'Badge',
      description: json['description'] ?? 'Tidak ada deskripsi.',
      icon: json['icon'] ?? '🏆',
      key: json['key'] ?? '',           
      rarity: json['rarity'] ?? 'bronze', 
      isUnlocked: isUnlockedValue,
      unlockedAt: unlockedAtStr != null
          ? DateTime.tryParse(unlockedAtStr) // Gunakan tryParse agar tidak crash jika format salah
          : null,
      // Ambil requirement dari API, jika kosong pakai default berdasarkan key
      requirement: json['requirement'] ?? _getDefaultRequirement(json['key']),
      // Ambil progress dari API, default 0.0
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
    );
  }

  // Helper untuk mensimulasikan teks syarat jika backend belum kirim data requirement
  static String _getDefaultRequirement(String key) {
    switch (key) {
      case 'newbie_glow': return 'Mencatat produk skincare pertama kali.';
      case 'consistent_cutie': return 'Mencatat skincare 3 hari berturut-turut.';
      case 'spf_warrior': return 'Pakai sunscreen selama 5 hari berturut-turut.';
      case 'glass_skin_master': return 'Rutin skincare lengkap selama 7 hari penuh.';
      case 'skincare_scholar': return 'Streak skincare selama 7 hari.';
      case 'hydration_hero': return 'Centang Moisturizer & Sunscreen selama 5 hari.';
      case 'night_owl': return 'Centang semua item Evening Routine selama 5 hari.';
      default: return 'Lakukan aksi khusus untuk membuka badge ini.';
    }
  }
}
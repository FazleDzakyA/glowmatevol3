// lib/models/skin_analysis_result.dart
class SkinAnalysisResult {
  final String skinType;
  final int healthScore;
  final List<String> concerns;
  final DateTime scanDate;

  SkinAnalysisResult({
    required this.skinType,
    required this.healthScore,
    required this.concerns,
    DateTime? scanDate,
  }) : scanDate = scanDate ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'skinType': skinType,
      'healthScore': healthScore,
      'concerns': concerns,
      'scanDate': scanDate.millisecondsSinceEpoch,
    };
  }

  factory SkinAnalysisResult.fromMap(Map<String, dynamic> map) {
    return SkinAnalysisResult(
      skinType: map['skinType'] ?? '',
      healthScore: map['healthScore']?.toInt() ?? 0,
      concerns: List<String>.from(map['concerns'] ?? []),
      scanDate: DateTime.fromMillisecondsSinceEpoch(map['scanDate']?.toInt() ?? 0),
    );
  }

  // 🔥 Method baru: Generate prompt untuk AI berdasarkan hasil scan
  String toAIPrompt() {
    return '''
      Berikut adalah hasil analisis wajahku:
      - Jenis kulit: $skinType
      - Skor kesehatan kulit: $healthScore%
      - Masalah kulit yang terdeteksi: ${concerns.join(', ')}

      Bantu aku buatkan rutinitas skincare harian yang sesuai dengan kondisi ini.
      Berikan rekomendasi produk dan tips praktis untuk mengatasi masalahku.
      Jawab dalam bahasa Indonesia hangat & empatik, maksimal 100 kata.
    ''';
  }
}
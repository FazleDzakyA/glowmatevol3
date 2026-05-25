class SkinAnalysisResult {
  final String skinType;
  final int healthScore;
  final List<String> concerns;

  SkinAnalysisResult({
    required this.skinType,
    required this.healthScore,
    required this.concerns,
  });
}

// Simulasi AI (untuk web & mobile)
SkinAnalysisResult simulateSkinAnalysis() {
  // Hasil acak tapi realistis
  return SkinAnalysisResult(
    skinType: "Combination",
    healthScore: 78,
    concerns: ["Enlarged Pores", "Mild Acne", "Dark Spots"],
  );
}
import 'dart:convert';
import 'package:flutter/services.dart';

class KnowledgeService {
  static List<Map<String, dynamic>> _knowledge = [];
  static List<String> _quickQuestions = [];
  static List<Map<String, dynamic>> _welcomeMessages = [];

  static Future<void> initialize() async {
    final String response = await rootBundle.loadString('assets/data/chatbot_knowledge.json');
    final data = json.decode(response);

    _knowledge = List<Map<String, dynamic>>.from(data['responses']);
    _quickQuestions = List<String>.from(data['quick_questions']);
    _welcomeMessages = List<Map<String, dynamic>>.from(data['welcome_messages']);
  }

  static Future<String> getResponse(String message) async {
    if (_knowledge.isEmpty) await initialize();

    for (var item in _knowledge) {
      final keywords = List<String>.from(item['keywords']);
      for (String keyword in keywords) {
        if (message.toLowerCase().contains(keyword.toLowerCase())) {
          return _formatResponse(item);
        }
      }
    }

    return "Ups! Aku belum bisa jawab itu.\nCoba pilih dari pertanyaan berikut:\n\n${_quickQuestions.join('\n')}";
  }

  static String _formatResponse(Map<String, dynamic> item) {
    final title = item['title'];
    final response = item['response'];
    final source = item['source'];
    final tips = List<String>.from(item['tips']);
    final tipsFormatted = tips.map((e) => "• $e").join('\n');
    final link = item['youtube_link'];

    return '''
$title

$response

💡 Tips Praktis:
$tipsFormatted

📖 Sumber: $source

📺 Ingin lihat tutorialnya? Klik link berikut:
$link
    '''.trim();
  }

  static List<String> getQuickQuestions() {
    return _quickQuestions;
  }

  static String getWelcomeMessage() {
    if (_welcomeMessages.isEmpty) return "Hai! Aku GlowBot ✨\nApa pertanyaanmu tentang skincare hari ini?";
    
    final now = DateTime.now();
    final hour = now.hour;

    for (var item in _welcomeMessages) {
      final start = item['time_range']['start'];
      final end = item['time_range']['end'];
      if (hour >= start && hour < end) {
        return item['message'];
      }
    }

    return "Hai! Aku GlowBot ✨\nApa pertanyaanmu tentang skincare hari ini?";
  }

  // 🔥 Fungsi Baru: Ambil semua knowledge untuk dijadikan tutorial
  static Future<List<Map<String, dynamic>>> getAllKnowledge() async {
    if (_knowledge.isEmpty) await initialize();
    return List.from(_knowledge);
  }
}
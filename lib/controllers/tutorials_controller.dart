import 'package:flutter/material.dart';
import '../models/tutorial_item.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/knowledge_service.dart';

class TutorialsController extends ChangeNotifier {
  int _selectedTab = 0;
  String _selectedCategory = "All";
  List<String> _savedVideoIds = [];

  int get selectedTab => _selectedTab;
  String get selectedCategory => _selectedCategory;
  List<String> get savedVideoIds => List.from(_savedVideoIds);

  late List<TutorialItem> _allTutorials = [];

  TutorialsController() {
    _loadTutorials();
  }

  Future<void> _loadTutorials() async {
    await KnowledgeService.initialize();
    final knowledgeList = await KnowledgeService.getAllKnowledge();

    final List<TutorialItem> knowledgeTutorials = knowledgeList.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final link = item['youtube_link'] as String;
      final videoId = _extractVideoId(link);

      return TutorialItem(
        id: "kb_$index",
        title: item['title'],
        creator: item['source'],
        views: "1k+ views",
        duration: "Video",
        tag: "Skincare",
        category: "Knowledge",
        imagePath: "", // Thumbnail akan diambil dari videoId
        videoId: videoId,
        isSaved: false,
        articleContent: item['response'],
        source: item['source'],
        tips: List<String>.from(item['tips']),
        keywords: List<String>.from(item['keywords']),
      );
    }).toList();

    _allTutorials = knowledgeTutorials;
    _loadSavedFromPrefs();
    notifyListeners();
  }

  static String _extractVideoId(String url) {
    final regExp = RegExp(r'(?:v=|\/)([0-9A-Za-z_-]{11})');
    final match = regExp.firstMatch(url);
    return match?.group(1) ?? "dQw4w9WgXcQ";
  }

  List<TutorialItem> get allTutorials => List.unmodifiable(_allTutorials);

  List<TutorialItem> get filteredTutorials {
    List<TutorialItem> result = List.from(_allTutorials);

    if (_selectedCategory != "All") {
      result = result.where((t) => t.category == _selectedCategory).toList();
    }

    switch (_selectedTab) {
      case 0: // Trending
        result.sort((a, b) => b.id.compareTo(a.id));
        break;
      case 1: // New
        result.sort((a, b) => a.id.compareTo(b.id));
        break;
      case 2: // Saved
        result = result.where((t) => _savedVideoIds.contains(t.id)).toList();
        break;
    }

    return result;
  }

  // 🔥 Fungsi baru: Cari tutorial berdasarkan keyword
  List<TutorialItem> searchTutorials(String query) {
    if (query.isEmpty) return List.from(_allTutorials);

    final lowerQuery = query.toLowerCase();
    return _allTutorials.where((t) {
      if (t.keywords != null) {
        for (String keyword in t.keywords!) {
          if (keyword.toLowerCase().contains(lowerQuery)) {
            return true;
          }
        }
      }
      if (t.title.toLowerCase().contains(lowerQuery)) return true;
      if (t.creator.toLowerCase().contains(lowerQuery)) return true;
      return false;
    }).toList();
  }

  void changeTab(int index) {
    _selectedTab = index;
    notifyListeners();
  }

  void changeCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void toggleSaveVideo(String videoId) {
    if (_savedVideoIds.contains(videoId)) {
      _savedVideoIds.remove(videoId);
    } else {
      _savedVideoIds.add(videoId);
    }
    notifyListeners();
    _saveToPrefs();
  }

  bool isVideoSaved(String videoId) {
    return _savedVideoIds.contains(videoId);
  }

  void _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('saved_video_ids', _savedVideoIds);
  }

  void _loadSavedFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _savedVideoIds = prefs.getStringList('saved_video_ids') ?? [];
    notifyListeners();
  }

  @override
  void addListener(VoidCallback listener) {
    super.addListener(listener);
    _loadSavedFromPrefs();
  }
}
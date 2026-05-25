class TutorialItem {
  final String id;
  final String title;
  final String creator;
  final String views;
  final String duration;
  final String tag;
  final String category;
  final String imagePath;
  final String videoId;
  bool isSaved;

  // 🔥 Tambahkan field dari knowledge
  final String? articleContent;
  final String? source;
  final List<String>? tips;
  final List<String>? keywords;

  TutorialItem({
    required this.id,
    required this.title,
    required this.creator,
    required this.views,
    required this.duration,
    required this.tag,
    required this.category,
    required this.imagePath,
    required this.videoId,
    this.isSaved = false,
    this.articleContent, // Bisa null jika hanya video
    this.source,
    this.tips,
    this.keywords,
  });

  TutorialItem copyWith({bool? isSaved}) {
    return TutorialItem(
      id: id,
      title: title,
      creator: creator,
      views: views,
      duration: duration,
      tag: tag,
      category: category,
      imagePath: imagePath,
      videoId: videoId,
      isSaved: isSaved ?? this.isSaved,
      articleContent: articleContent,
      source: source,
      tips: tips,
      keywords: keywords,
    );
  }
}
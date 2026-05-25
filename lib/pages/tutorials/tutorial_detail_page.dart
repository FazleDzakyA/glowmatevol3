import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../models/tutorial_item.dart';

class TutorialDetailPage extends StatefulWidget {
  final TutorialItem tutorial;

  const TutorialDetailPage({super.key, required this.tutorial});

  @override
  State<TutorialDetailPage> createState() => _TutorialDetailPageState();
}

class _TutorialDetailPageState extends State<TutorialDetailPage> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    _controller = YoutubePlayerController(
      initialVideoId: widget.tutorial.videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
        controlsVisibleAtStart: true,
      ),
    );
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFFF6A8B8);
    final secondaryColor = const Color(0xFFE91E63);

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFFFF9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: isDarkMode ? Colors.white : Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Tutorial",
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ VIDEO PLAYER FULL WIDTH
            Container(
              width: double.infinity,
              color: Colors.black,
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: YoutubePlayer(
                  controller: _controller,
                  showVideoProgressIndicator: true,
                  progressIndicatorColor: secondaryColor,
                  onReady: () {
                    print('Player is ready.');
                  },
                  onEnded: (data) {
                    print('Video ended: ${data.title}');
                  },
                ),
              ),
            ),

            // ✅ INFO HEADER CARD
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1E1E2E) : Colors.white,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05), blurRadius: 10)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.tutorial.title,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black87,
                            height: 1.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Tag Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: secondaryColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.tutorial.tag,
                          style: TextStyle(
                            fontSize: 12,
                            color: secondaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.grey.shade300,
                        child: Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.tutorial.creator,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDarkMode ? Colors.white70 : Colors.black87,
                        ),
                      ),
                      Text(
                        " • ",
                        style: TextStyle(color: isDarkMode ? Colors.white54 : Colors.grey.shade400),
                      ),
                      Text(
                        widget.tutorial.views,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDarkMode ? Colors.white54 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ✅ SECTION: DESKRIPSI / ARTIKEL
                  if (widget.tutorial.articleContent != null && widget.tutorial.articleContent!.isNotEmpty) ...[
                    _buildSectionTitle("Deskripsi", isDarkMode),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDarkMode ? const Color(0xFF1E1E2E) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05), blurRadius: 10)],
                      ),
                      child: Text(
                        widget.tutorial.articleContent!,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.6,
                          color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],

                  // ✅ SECTION: TIPS PRAKTIS
                  if (widget.tutorial.tips != null && widget.tutorial.tips!.isNotEmpty) ...[
                    _buildSectionTitle("💡 Tips Praktis", isDarkMode),
                    const SizedBox(height: 12),
                    ...widget.tutorial.tips!.map((tip) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 6),
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: secondaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              tip,
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.5,
                                color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )).toList(),
                    const SizedBox(height: 32),
                  ],

                  // ✅ SECTION: SUMBER
                  if (widget.tutorial.source != null && widget.tutorial.source!.isNotEmpty) ...[
                    _buildSectionTitle("📖 Sumber", isDarkMode),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: primaryColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.link_rounded, color: secondaryColor, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              widget.tutorial.source!,
                              style: TextStyle(
                                fontSize: 14,
                                color: secondaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ HELPER WIDGET UNTUK JUDUL SECTION
  Widget _buildSectionTitle(String title, bool isDarkMode) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: isDarkMode ? Colors.white : Colors.black87,
      ),
    );
  }
}
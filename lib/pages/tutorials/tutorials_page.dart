import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/tutorial_item.dart';
import '../../controllers/tutorials_controller.dart';
import 'tutorial_detail_page.dart';

class TutorialsPage extends StatefulWidget {
  const TutorialsPage({super.key});

  @override
  State<TutorialsPage> createState() => _TutorialsPageState();
}

class _TutorialsPageState extends State<TutorialsPage> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    // Animasi Masuk
    _controller = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final ctrl = Provider.of<TutorialsController>(context);
    final primaryColor = const Color(0xFFF6A8B8);
    final secondaryColor = const Color(0xFFE91E63);

    final String query = _searchController.text;
    List<TutorialItem> tutorials = query.isEmpty
        ? ctrl.filteredTutorials
        : ctrl.searchTutorials(query);

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
          "Tutorials",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 100, 24, 40),
          children: [
            // ✅ SEARCH BAR MODERN
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1E1E2E) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05), blurRadius: 10)],
              ),
              child: Row(
                children: [
                  Icon(Icons.search_rounded, color: isDarkMode ? Colors.white70 : Colors.grey.shade500),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
                      decoration: InputDecoration(
                        hintText: "Search skincare tips...",
                        hintStyle: TextStyle(color: isDarkMode ? Colors.white54 : Colors.grey.shade400),
                        border: InputBorder.none,
                      ),
                      onChanged: (value) {
                        if (mounted) setState(() {});
                      },
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: Icon(Icons.clear, size: 18, color: isDarkMode ? Colors.white70 : Colors.grey.shade500),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),

            // ✅ CATEGORY CHIPS HORIZONTAL
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildCategoryChip(ctrl, "All", Icons.auto_awesome_rounded, primaryColor, isDarkMode),
                  _buildCategoryChip(ctrl, "Knowledge", Icons.article_rounded, primaryColor, isDarkMode),
                  _buildCategoryChip(ctrl, "Routine", Icons.loop_rounded, primaryColor, isDarkMode),
                  _buildCategoryChip(ctrl, "Tips", Icons.lightbulb_rounded, primaryColor, isDarkMode),
                ],
              ),
            ),
            
            const SizedBox(height: 24),

            // ✅ TAB BUTTONS MINIMALIS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildTabButton(ctrl, 0, "Trending", secondaryColor, isDarkMode),
                _buildTabButton(ctrl, 1, "New", secondaryColor, isDarkMode),
                _buildTabButton(ctrl, 2, "Saved", secondaryColor, isDarkMode),
              ],
            ),
            
            const SizedBox(height: 24),

            // ✅ VIDEO LIST
            ...tutorials.map((tutorial) => Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: _buildVideoCard(
                context: context,
                tutorial: tutorial,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TutorialDetailPage(tutorial: tutorial),
                    ),
                  );
                },
                primaryColor: primaryColor,
                secondaryColor: secondaryColor,
                isDarkMode: isDarkMode,
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  // ✅ WIDGET CATEGORY CHIP
  Widget _buildCategoryChip(TutorialsController ctrl, String label, IconData icon, Color activeColor, bool isDarkMode) {
    final bool isActive = ctrl.selectedCategory == label;
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () => ctrl.changeCategory(label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? activeColor : (isDarkMode ? const Color(0xFF1E1E2E) : Colors.white),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isActive ? activeColor : (isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey.shade200),
            ),
            boxShadow: isActive ? [BoxShadow(color: activeColor.withOpacity(0.3), blurRadius: 8)] : [],
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: isActive ? Colors.white : (isDarkMode ? Colors.white70 : Colors.grey.shade600)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.white : (isDarkMode ? Colors.white : Colors.black87),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ WIDGET TAB BUTTON
  Widget _buildTabButton(TutorialsController ctrl, int index, String label, Color activeColor, bool isDarkMode) {
    final bool active = ctrl.selectedTab == index;
    return GestureDetector(
      onTap: () => ctrl.changeTab(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: active ? activeColor : (isDarkMode ? Colors.white70 : Colors.grey.shade600),
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 20,
            height: 3,
            decoration: BoxDecoration(
              color: active ? activeColor : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ WIDGET VIDEO CARD PREMIUM
  Widget _buildVideoCard({
    required BuildContext context,
    required TutorialItem tutorial,
    required VoidCallback onTap,
    required Color primaryColor,
    required Color secondaryColor,
    required bool isDarkMode,
  }) {
    String thumbnailUrl = 'https://img.youtube.com/vi/${tutorial.videoId}/0.jpg';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E1E2E) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(blurRadius: 15, color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05), offset: const Offset(0, 5))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl: thumbnailUrl,
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 220,
                      width: double.infinity,
                      color: Colors.grey.shade200,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 220,
                      width: double.infinity,
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.error_outline, size: 40, color: Colors.grey),
                    ),
                  ),
                  // Overlay Gradasi Halus di Bawah Thumbnail
                  Positioned.fill(
                    bottom: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
                        ),
                      ),
                    ),
                  ),
                  // Tombol Play Tengah
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10)],
                        ),
                        child: Icon(Icons.play_arrow_rounded, size: 40, color: secondaryColor),
                      ),
                    ),
                  ),
                  // Durasi Video
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        tutorial.duration,
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                  // Tombol Save
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Consumer<TutorialsController>(
                      builder: (context, ctrl, child) {
                        bool isSaved = ctrl.isVideoSaved(tutorial.id);
                        return GestureDetector(
                          onTap: () => ctrl.toggleSaveVideo(tutorial.id),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5)],
                            ),
                            child: Icon(
                              isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                              color: isSaved ? secondaryColor : Colors.grey.shade700,
                              size: 22,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tutorial.title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.grey.shade300,
                        child: Icon(Icons.person, size: 14, color: Colors.grey.shade600),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "${tutorial.creator} · ${tutorial.views}",
                          style: TextStyle(
                            fontSize: 13,
                            color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      tutorial.tag,
                      style: TextStyle(
                        fontSize: 12,
                        color: secondaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
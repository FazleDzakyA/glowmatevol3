import 'package:flutter/material.dart';
import '../../models/badge_model.dart';
import '../../services/badge_service.dart';

class BadgeScreen extends StatefulWidget {
  const BadgeScreen({super.key});

  @override
  State<BadgeScreen> createState() => _BadgeScreenState();
}

class _BadgeScreenState extends State<BadgeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    // Background Gradasi Halus
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFFFF5F7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: isDarkMode ? Colors.white : Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'My Badge',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 24,
            color: isDarkMode ? Colors.white : Colors.black87,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: false,
      ),
      body: FutureBuilder<List<BadgeModel>>(
        future: BadgeService.fetchBadges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: const Color(0xFFE91E63)));
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.redAccent.withOpacity(0.7)),
                  const SizedBox(height: 16),
                  Text('Gagal memuat data', style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.grey.shade600)),
                ],
              ),
            );
          }

          final badges = snapshot.data ?? [];
          
          // Hitung Statistik
          int unlockedCount = badges.where((b) => b.isUnlocked).length;
          int totalCount = badges.length;
          double percentage = totalCount == 0 ? 0 : (unlockedCount / totalCount);

          if (_animationController.status != AnimationStatus.completed) {
             _animationController.reset();
             _animationController.forward();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 100, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ HEADER STATISTIK FUTURISTIK
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [const Color(0xFFE91E63), const Color(0xFFFF80AB)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE91E63).withOpacity(0.4),
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
                            "Collection",
                            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            "$unlockedCount / $totalCount",
                            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            "${(percentage * 100).toInt()}% Unlocked",
                            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.emoji_events, color: Colors.white, size: 30),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 30),
                
                Text(
                  "All Badges",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 15),

                // ✅ LIST BADGE DENGAN ANIMASI
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: badges.length,
                  itemBuilder: (context, index) {
                    return FadeTransition(
                      opacity: CurvedAnimation(
                        parent: _animationController,
                        curve: Interval(
                          (index / badges.length).clamp(0.0, 1.0),
                          ((index + 1) / badges.length).clamp(0.0, 1.0),
                          curve: Curves.easeInOut,
                        ),
                      ),
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.2),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: _animationController,
                          curve: Interval(
                            (index / badges.length).clamp(0.0, 1.0),
                            ((index + 1) / badges.length).clamp(0.0, 1.0),
                            curve: Curves.easeOutCubic,
                          ),
                        )),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: ElegantBadgeCard(badge: badges[index]),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ============================================
// WIDGET CARD BADGE YANG MEWAH & INTERAKTIF
// ============================================
class ElegantBadgeCard extends StatefulWidget {
  final BadgeModel badge;
  const ElegantBadgeCard({super.key, required this.badge});

  @override
  State<ElegantBadgeCard> createState() => _ElegantBadgeCardState();
}

class _ElegantBadgeCardState extends State<ElegantBadgeCard> with SingleTickerProviderStateMixin {
  late AnimationController _tapController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _tapController = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(CurvedAnimation(parent: _tapController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _tapController.dispose();
    super.dispose();
  }

  Color _getRarityColor(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'gold': return const Color(0xFFFFD700);
      case 'silver': return const Color(0xFFC0C0C0);
      case 'diamond': return const Color(0xFFB9F2FF);
      case 'bronze': default: return const Color(0xFFCD7F32);
    }
  }

  String _formatDate(DateTime date) {
    const months = ["Jan", "Feb", "Mar", "Apr", "Mei", "Jun", "Jul", "Ags", "Sep", "Okt", "Nov", "Des"];
    return "${date.day} ${months[date.month - 1]} ${date.year}";
  }

  void _showDetail() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final color = _getRarityColor(widget.badge.rarity);
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final subTextColor = isDarkMode ? Colors.white70 : Colors.grey.shade600;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E1E2E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, -5))],
        ),
        child: Column(
          children: [
            Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // Hero Image dengan Glow Efek
                    Hero(
                      tag: 'badge-${widget.badge.id}',
                      child: Container(
                        padding: const EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.badge.isUnlocked ? color.withOpacity(0.1) : (isDarkMode ? const Color(0xFF2C2C3E) : Colors.grey.shade100),
                          border: Border.all(color: widget.badge.isUnlocked ? color : Colors.transparent, width: 4),
                          boxShadow: widget.badge.isUnlocked ? [
                            BoxShadow(color: color.withOpacity(0.5), blurRadius: 30, spreadRadius: 5, offset: const Offset(0, 10))
                          ] : [],
                        ),
                        child: Text(widget.badge.icon ?? '🏆', style: TextStyle(fontSize: 80, color: textColor)),
                      ),
                    ),
                    const SizedBox(height: 25),
                    
                    Text(widget.badge.name ?? 'Badge', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textColor), textAlign: TextAlign.center),
                    const SizedBox(height: 10),
                    
                    // Rarity Tag
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: color.withOpacity(0.5)),
                      ),
                      child: Text(
                        widget.badge.rarity.toUpperCase(),
                        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    Text(widget.badge.description ?? 'Tidak ada deskripsi.', style: TextStyle(color: subTextColor, fontSize: 16, height: 1.5), textAlign: TextAlign.center),
                    const SizedBox(height: 30),
                    
                    if (!widget.badge.isUnlocked && widget.badge.progress > 0) ...[
                      _buildProgressCard(isDarkMode, color),
                    ] else if (!widget.badge.isUnlocked) ...[
                      _buildRequirementCard(isDarkMode, color),
                    ],

                    const SizedBox(height: 30),
                    
                    // Status Footer
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        color: widget.badge.isUnlocked ? color.withOpacity(0.1) : (isDarkMode ? const Color(0xFF2C2C3E) : Colors.grey.shade100),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(widget.badge.isUnlocked ? Icons.check_circle_rounded : Icons.lock_rounded, 
                               color: widget.badge.isUnlocked ? color : (isDarkMode ? Colors.white54 : Colors.grey.shade500), size: 24),
                          const SizedBox(width: 10),
                          Text(
                            widget.badge.isUnlocked ? 'Sudah Terbuka!' : 'Terkunci',
                            style: TextStyle(color: widget.badge.isUnlocked ? color : (isDarkMode ? Colors.white54 : Colors.grey.shade700), fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    
                    if (widget.badge.isUnlocked && widget.badge.unlockedAt != null) ...[
                      const SizedBox(height: 15),
                      Text('Diperoleh pada ${_formatDate(widget.badge.unlockedAt!)}', style: TextStyle(color: isDarkMode ? Colors.white54 : Colors.grey.shade500, fontSize: 13, fontStyle: FontStyle.italic)),
                    ],
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard(bool isDarkMode, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2C2C3E) : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.blue.shade100, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Progress:', style: TextStyle(fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.blue.shade700)),
              Text('${(widget.badge.progress * 100).toInt()}%', style: TextStyle(fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.blue.shade700)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: widget.badge.progress,
              backgroundColor: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.blue.shade100,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 10),
          Text(widget.badge.requirement, style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.white70 : Colors.grey.shade700)),
        ],
      ),
    );
  }

  Widget _buildRequirementCard(bool isDarkMode, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2C2C3E) : Colors.pink.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.pink.shade100, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: isDarkMode ? Colors.white : Colors.pink.shade700, size: 20),
              const SizedBox(width: 8),
              Text('Cara Membuka:', style: TextStyle(fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.pink.shade700, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 10),
          Text(widget.badge.requirement ?? 'Lakukan aksi khusus.', style: TextStyle(fontSize: 14, color: isDarkMode ? Colors.white70 : Colors.grey.shade800, height: 1.5)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isUnlocked = widget.badge.isUnlocked;
    final neonColor = _getRarityColor(widget.badge.rarity);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    return GestureDetector(
      onTapDown: (_) => _tapController.forward(),
      onTapUp: (_) {
        _tapController.reverse();
        Future.delayed(const Duration(milliseconds: 150), () {
          _showDetail();
        });
      },
      onTapCancel: () => _tapController.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1E1E2E) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: isUnlocked 
                ? Border.all(color: neonColor.withOpacity(0.3), width: 1.5)
                : Border.all(color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.grey.shade200, width: 1),
            boxShadow: isUnlocked
                ? [
                    BoxShadow(
                      color: neonColor.withOpacity(0.2),
                      blurRadius: 15,
                      spreadRadius: 1,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            children: [
              // Icon Badge dengan Glow
              Hero(
                tag: 'badge-${widget.badge.id}',
                child: Container(
                  width: 65,
                  height: 65,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isUnlocked ? neonColor.withOpacity(0.1) : (isDarkMode ? const Color(0xFF2C2C3E) : Colors.grey.shade100),
                    border: isUnlocked ? Border.all(color: neonColor.withOpacity(0.5), width: 2) : null,
                    boxShadow: isUnlocked ? [
                      BoxShadow(color: neonColor.withOpacity(0.3), blurRadius: 10, spreadRadius: 2)
                    ] : [],
                  ),
                  child: Center(
                    child: Opacity(
                      opacity: isUnlocked ? 1.0 : 0.4,
                      child: Text(widget.badge.icon ?? '🏆', style: const TextStyle(fontSize: 35)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Info Badge
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.badge.name ?? 'Badge',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.badge.rarity.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: neonColor,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Status Icon
              Icon(
                isUnlocked ? Icons.check_circle_rounded : Icons.lock_rounded,
                color: isUnlocked ? neonColor : (isDarkMode ? Colors.white30 : Colors.grey.shade400),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
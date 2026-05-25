import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../controllers/auth_controller.dart';
import '../../services/api_service.dart';
import '../../routes/app_routes.dart';
import 'channel_detail_page.dart'; 

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> with SingleTickerProviderStateMixin {
  List<dynamic> _allChannels = []; 
  List<dynamic> _myChannels = [];  
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.getChannels();
      if (response['status'] == 'success') {
        setState(() {
          _allChannels = response['data'];
          
          // Filter channel milik saya secara lokal
          final authCtrl = context.read<AuthController>();
          _myChannels = _allChannels.where((channel) {
            final ownerId = channel['owner']?['id'];
            final ownerEmail = channel['owner']?['email'];
            
            if (authCtrl.userId != null && ownerId != null) {
              return ownerId.toString() == authCtrl.userId.toString();
            }
            if (ownerEmail != null && authCtrl.email.isNotEmpty) {
              return ownerEmail.toLowerCase() == authCtrl.email.toLowerCase();
            }
            return false;
          }).toList();
        });
      }
    } catch (e) {
      debugPrint("Error fetching channels: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal memuat data: $e"), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _goToUpgrade() {
    Navigator.pushNamed(context, AppRoutes.upgradePremium).then((_) {
      _fetchData(); 
    });
  }

  // ✅ DIALOG BUAT CHANNEL DENGAN UPLOAD COVER IMAGE (UNIVERSAL WEB & MOBILE)
  void _showCreateChannelDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController descController = TextEditingController();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    bool isCreating = false;
    XFile? _selectedCoverImage;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: isDarkMode ? const Color(0xFF1E1E2E) : Colors.white,
          title: Text("Buat Channel Baru", style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Preview Cover Image
                GestureDetector(
                  onTap: () async {
                    final ImagePicker picker = ImagePicker();
                    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                    if (image != null) {
                      setDialogState(() {
                        _selectedCoverImage = image;
                      });
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: _selectedCoverImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: kIsWeb
                                ? FutureBuilder<Uint8List>(
                                    future: _selectedCoverImage!.readAsBytes(),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData) return Image.memory(snapshot.data!, fit: BoxFit.cover);
                                      return const Center(child: CircularProgressIndicator());
                                    },
                                  )
                                : Image.file(File(_selectedCoverImage!.path), fit: BoxFit.cover),
                          )
                        : const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey),
                                SizedBox(height: 8),
                                Text("Tap untuk pilih Cover", style: TextStyle(color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                
                TextField(controller: nameController, enabled: !isCreating, style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87), decoration: InputDecoration(labelText: "Nama Channel", labelStyle: TextStyle(color: isDarkMode ? Colors.white70 : Colors.grey.shade600), filled: true, fillColor: isDarkMode ? const Color(0xFF2C2C3E) : Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
                const SizedBox(height: 16),
                TextField(controller: descController, enabled: !isCreating, style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87), decoration: InputDecoration(labelText: "Deskripsi", labelStyle: TextStyle(color: isDarkMode ? Colors.white70 : Colors.grey.shade600), filled: true, fillColor: isDarkMode ? const Color(0xFF2C2C3E) : Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)), maxLines: 3),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: isCreating ? null : () => Navigator.pop(ctx), child: const Text("Batal")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF6A8B8), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              onPressed: isCreating ? null : () async {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nama channel tidak boleh kosong!"), backgroundColor: Colors.redAccent));
                  return;
                }
                setDialogState(() => isCreating = true);
                try {
                  // Baca cover image menjadi bytes jika ada
                  Uint8List? coverBytes;
                  String? coverFileName;
                  if (_selectedCoverImage != null) {
                    coverBytes = await _selectedCoverImage!.readAsBytes();
                    coverFileName = _selectedCoverImage!.name;
                  }

                  // Panggil API Create Channel dengan cover image
                  final response = await ApiService.createChannelWithCover(
                    nameController.text.trim(), 
                    descController.text.trim(),
                    coverBytes,
                    coverFileName
                  );

                  if (response['status'] == 'success') {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Channel '${nameController.text}' berhasil dibuat!"), backgroundColor: Colors.green));
                    _fetchData(); 
                  } else { throw Exception(response['message'] ?? 'Gagal'); }
                } catch (e) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}"), backgroundColor: Colors.redAccent));
                }
              },
              child: isCreating ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white))) : const Text("Buat", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authCtrl = context.watch<AuthController>();
    final isPremium = authCtrl.isPremium;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFFF6A8B8);
    final secondaryColor = const Color(0xFFE91E63);

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
        title: Text("Community", style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87, fontWeight: FontWeight.w800, fontSize: 24)),
        actions: [
          if (isPremium)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: CircleAvatar(
                backgroundColor: primaryColor.withOpacity(0.2),
                child: IconButton(icon: const Icon(Icons.add, color: Color(0xFFE91E63)), onPressed: () => _showCreateChannelDialog(context)),
              ),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: secondaryColor,
          unselectedLabelColor: isDarkMode ? Colors.white70 : Colors.grey.shade600,
          indicatorColor: secondaryColor,
          tabs: const [
            Tab(text: "For You"), 
            Tab(text: "My Channels"), 
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFF6A8B8)))
          : TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: FOR YOU (Semua Channel Publik)
                _allChannels.isEmpty 
                  ? _buildEmptyState(isPremium, secondaryColor, isDarkMode, "Belum ada channel publik.")
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(24, 100, 24, 100),
                      itemCount: _allChannels.length,
                      itemBuilder: (context, index) => _buildChannelCard(_allChannels[index], isDarkMode, primaryColor, secondaryColor),
                    ),
                
                // TAB 2: MY CHANNELS
                _myChannels.isEmpty
                  ? _buildEmptyState(isPremium, secondaryColor, isDarkMode, isPremium ? "Kamu belum membuat channel." : "Upgrade Premium untuk buat channel.")
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(24, 100, 24, 100),
                      itemCount: _myChannels.length,
                      itemBuilder: (context, index) => _buildChannelCard(_myChannels[index], isDarkMode, primaryColor, secondaryColor),
                    ),
              ],
            ),
      floatingActionButton: !isPremium
          ? FloatingActionButton.extended(
              onPressed: _goToUpgrade,
              label: const Text("Upgrade Premium"),
              icon: const Icon(Icons.diamond_outlined),
              backgroundColor: secondaryColor,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  Widget _buildEmptyState(bool isPremium, Color accentColor, bool isDarkMode, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: accentColor.withOpacity(0.1), shape: BoxShape.circle), child: Icon(Icons.group_off, size: 60, color: accentColor)),
            const SizedBox(height: 24),
            Text(message, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87), textAlign: TextAlign.center),
            if (!isPremium) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(icon: const Icon(Icons.diamond_outlined), label: const Text("Upgrade Premium"), style: ElevatedButton.styleFrom(backgroundColor: accentColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), onPressed: _goToUpgrade)
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildChannelCard(dynamic channel, bool isDarkMode, Color primaryColor, Color secondaryColor) {
    final channelId = channel['id'];
    final channelName = channel['name'] ?? 'Tanpa Nama';
    final channelDesc = channel['description'] ?? "No description";
    final coverImage = channel['cover_image'];
    final ownerName = channel['owner']?['name'] ?? 'Unknown';
    final ownerImage = channel['owner']?['profile_image'];
    final memberCount = channel['followers_count'] ?? 0;
    bool isFollowing = channel['is_following'] ?? false; 

    String imageUrl = '';
    if (coverImage != null && coverImage.toString().isNotEmpty) {
      imageUrl = coverImage.startsWith('http') ? coverImage : 'http://localhost:8000/storage/$coverImage';
    }

    String avatarUrl = '';
    if (ownerImage != null && ownerImage.toString().isNotEmpty) {
      avatarUrl = ownerImage.startsWith('http') ? ownerImage : 'http://localhost:8000/storage/$ownerImage';
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => ChannelDetailPage(channel: channel)));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(color: isDarkMode ? const Color(0xFF1E1E2E) : Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05), blurRadius: 15, offset: const Offset(0, 5))]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: imageUrl.isNotEmpty ? Image.network(imageUrl, height: 160, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(height: 160, color: Colors.grey.shade200, child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)))) : Container(height: 160, color: Colors.grey.shade200, child: const Center(child: Icon(Icons.image_not_supported, color: Colors.grey))),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(radius: 24, backgroundColor: primaryColor.withOpacity(0.2), backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null, child: avatarUrl.isEmpty ? const Icon(Icons.person, color: Color(0xFFE91E63)) : null),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(channelName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isDarkMode ? Colors.white : Colors.black87)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text("by $ownerName", style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.grey.shade600, fontSize: 13)),
                            const SizedBox(width: 8),
                            Icon(Icons.people_outline, size: 14, color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Text("$memberCount Members", style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () async {
                      try {
                        final response = await ApiService.toggleFollow(channelId);
                        if (response['status'] == 'success') {
                          if (mounted) {
                            await _fetchData(); 
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response['message'] ?? "Berhasil Update Follow!"), backgroundColor: Colors.green));
                          }
                        }
                      } catch (e) {
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal: ${e.toString()}"), backgroundColor: Colors.redAccent));
                      }
                    },
                    style: OutlinedButton.styleFrom(side: BorderSide(color: isFollowing ? Colors.transparent : secondaryColor, width: 1.5), backgroundColor: isFollowing ? secondaryColor : Colors.transparent, foregroundColor: isFollowing ? Colors.white : secondaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
                    child: Text(isFollowing ? "Following" : "Follow", style: const TextStyle(fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            ),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: Text(channelDesc, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.grey.shade600, fontSize: 14, height: 1.4))),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
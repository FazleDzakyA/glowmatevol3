import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../../controllers/auth_controller.dart';
import '../../services/api_service.dart';

class ChannelDetailPage extends StatefulWidget {
  final dynamic channel;

  const ChannelDetailPage({super.key, required this.channel});

  @override
  State<ChannelDetailPage> createState() => _ChannelDetailPageState();
}

class _ChannelDetailPageState extends State<ChannelDetailPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Data Posts (Awalnya Mock Data, nanti akan diisi dari API jika sudah ada endpoint getPosts)
  List<dynamic> _posts = [
    {
      'id': 1,
      'type': 'image',
      'content_url': 'https://images.unsplash.com/photo-1596462502278-27bfdd403cc2?auto=format&fit=crop&w=800&q=80',
      'caption': 'Tips skincare pagi hari! ✨ Jangan lupa pakai sunscreen.',
      'created_at': '2 Jam yang lalu',
      'likes_count': 120,
      'is_liked_by_me': false,
      'user': {'name': 'Admin GlowMate', 'profile_image': null}
    },
  ];

  final TextEditingController _chatController = TextEditingController();
  List<dynamic> _chats = [];
  bool _isChatLoading = false;
  final ScrollController _chatScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchChats();
    _tabController.addListener(() {
      if (_tabController.index == 1 && _chats.isEmpty) _fetchChats();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _chatController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchChats() async {
    if (!mounted) return;
    setState(() => _isChatLoading = true);
    try {
      final response = await ApiService.getChannelChats(widget.channel['id']);
      if (response['status'] == 'success') {
        setState(() {
          _chats = response['data'];
          _isChatLoading = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_chatScrollController.hasClients) {
            _chatScrollController.jumpTo(_chatScrollController.position.maxScrollExtent);
          }
        });
      }
    } catch (e) {
      debugPrint("Error fetching chats: $e");
      setState(() => _isChatLoading = false);
    }
  }

  Future<void> _sendMessage() async {
    if (_chatController.text.trim().isEmpty) return;
    final message = _chatController.text.trim();
    _chatController.clear();
    try {
      final response = await ApiService.sendChannelChat(widget.channel['id'], message);
      if (response['status'] == 'success') {
        setState(() { _chats.add(response['data']); });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_chatScrollController.hasClients) {
            _chatScrollController.animateTo(
              _chatScrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal mengirim pesan: $e"), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authCtrl = context.watch<AuthController>();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    final ownerId = widget.channel['owner']?['id'];
    final ownerEmail = widget.channel['owner']?['email'];
    bool isOwner = false;

    if (authCtrl.userId != null && ownerId != null) {
      isOwner = ownerId.toString() == authCtrl.userId.toString();
    } 
    if (!isOwner && ownerEmail != null && authCtrl.email.isNotEmpty) {
      isOwner = ownerEmail.toLowerCase() == authCtrl.email.toLowerCase();
    }

    final channelName = widget.channel['name'] ?? 'Channel';
    final channelDesc = widget.channel['description'] ?? 'No description';
    final coverImage = widget.channel['cover_image'];
    final memberCount = widget.channel['followers_count'] ?? 0;
    
    String imageUrl = '';
    if (coverImage != null && coverImage.toString().isNotEmpty) {
      imageUrl = coverImage.startsWith('http') ? coverImage : 'http://localhost:8000/storage/$coverImage';
    }

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFFFF9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: isDarkMode ? Colors.white : Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(channelName, style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 20)),
        actions: [
          if (isOwner)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: CircleAvatar(
                backgroundColor: const Color(0xFFF6A8B8).withOpacity(0.2),
                child: IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: Color(0xFFE91E63)),
                  onPressed: () { _showUploadPostDialog(context); },
                ),
              ),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFE91E63),
          unselectedLabelColor: isDarkMode ? Colors.white70 : Colors.grey.shade600,
          indicatorColor: const Color(0xFFE91E63),
          indicatorWeight: 3,
          tabs: const [Tab(text: "Posts"), Tab(text: "Discussion")],
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: isDarkMode ? const Color(0xFF1E1E2E) : Colors.white,
            child: Row(
              children: [
                Container(
                  width: 70, height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFF6A8B8).withOpacity(0.3), width: 2),
                    image: DecorationImage(
                      image: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : const AssetImage('assets/icons/glowmate_icon.png') as ImageProvider,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(channelName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87)),
                      const SizedBox(height: 4),
                      Text("$memberCount Members", style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.grey.shade600, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(channelDesc, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.grey.shade600, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                ListView.builder(padding: const EdgeInsets.all(16), itemCount: _posts.length, itemBuilder: (context, index) => _buildPostItem(_posts[index], isDarkMode)),
                _buildChatTab(isDarkMode, authCtrl),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatTab(bool isDarkMode, AuthController authCtrl) {
    return Column(
      children: [
        Expanded(
          child: _isChatLoading && _chats.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  controller: _chatScrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _chats.length,
                  itemBuilder: (context, index) {
                    final chat = _chats[index];
                    final isMe = chat['user_id'] == authCtrl.userId; 
                    return _buildChatBubble(chat, isMe, isDarkMode);
                  },
                ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: isDarkMode ? const Color(0xFF1E1E2E) : Colors.white,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chatController,
                  style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    hintText: "Ketik pesan...",
                    hintStyle: TextStyle(color: isDarkMode ? Colors.white54 : Colors.grey.shade500),
                    filled: true,
                    fillColor: isDarkMode ? const Color(0xFF2C2C3E) : Colors.grey.shade100,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 10),
              CircleAvatar(
                backgroundColor: const Color(0xFFE91E63),
                child: IconButton(icon: const Icon(Icons.send, color: Colors.white, size: 20), onPressed: _sendMessage),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChatBubble(dynamic chat, bool isMe, bool isDarkMode) {
    final message = chat['message'];
    final userName = chat['user']?['name'] ?? 'User';
    final userImage = chat['user']?['profile_image'];
    String avatarUrl = '';
    if (userImage != null && userImage.toString().isNotEmpty) {
      avatarUrl = userImage.startsWith('http') ? userImage : 'http://localhost:8000/storage/$userImage';
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(radius: 16, backgroundColor: Colors.grey.shade300, backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null, child: avatarUrl.isEmpty ? const Icon(Icons.person, size: 16, color: Colors.grey) : null),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFFE91E63) : (isDarkMode ? const Color(0xFF2C2C3E) : Colors.white),
                borderRadius: BorderRadius.only(topLeft: const Radius.circular(16), topRight: const Radius.circular(16), bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4), bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe) Text(userName, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isMe ? Colors.white70 : const Color(0xFFE91E63))),
                  if (!isMe) const SizedBox(height: 4),
                  Text(message, style: TextStyle(color: isMe ? Colors.white : (isDarkMode ? Colors.white : Colors.black87), fontSize: 14, height: 1.4)),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildPostItem(Map<String, dynamic> post, bool isDarkMode) {
    // Handle URL Gambar Post
    String postImageUrl = '';
    if (post['content_url'] != null && post['content_url'].toString().isNotEmpty) {
       postImageUrl = post['content_url'].startsWith('http') 
           ? post['content_url'] 
           : 'http://localhost:8000/storage/${post['content_url']}';
    } else if (post['url'] != null) {
       // Fallback untuk mock data lama
       postImageUrl = post['url'];
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(color: isDarkMode ? const Color(0xFF1E1E2E) : Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05), blurRadius: 15, offset: const Offset(0, 5))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (post['type'] == 'image' && postImageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: CachedNetworkImage(
                imageUrl: postImageUrl, 
                width: double.infinity, 
                fit: BoxFit.cover, 
                placeholder: (context, url) => Container(height: 250, color: Colors.grey.shade200, child: const Center(child: CircularProgressIndicator())), 
                errorWidget: (context, url, error) => Container(height: 250, color: Colors.grey.shade200, child: const Icon(Icons.broken_image, color: Colors.grey))
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (post['user'] != null)
                  Row(
                    children: [
                      CircleAvatar(radius: 12, backgroundImage: post['user']['profile_image'] != null ? NetworkImage(post['user']['profile_image'].startsWith('http') ? post['user']['profile_image'] : 'http://localhost:8000/storage/${post['user']['profile_image']}') : null, child: post['user']['profile_image'] == null ? const Icon(Icons.person, size: 12) : null),
                      const SizedBox(width: 8),
                      Text(post['user']['name'] ?? 'Unknown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDarkMode ? Colors.white : Colors.black87)),
                    ],
                  ),
                if (post['user'] != null) const SizedBox(height: 8),
                Text(post['caption'], style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87, fontSize: 15, height: 1.5)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(post['created_at'] ?? 'Baru saja', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                    Row(children: [
                      Icon(Icons.favorite_border_rounded, size: 18, color: Colors.grey.shade500), 
                      const SizedBox(width: 4), 
                      Text('${post['likes_count'] ?? post['likes'] ?? 0}', style: TextStyle(color: Colors.grey.shade500, fontSize: 12))
                    ]),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showUploadPostDialog(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final TextEditingController captionController = TextEditingController();
    XFile? _selectedImageFile; 
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: isDarkMode ? const Color(0xFF1E1E2E) : Colors.white,
          title: Text("Upload Post Baru", style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: isUploading ? null : () async {
                    final ImagePicker picker = ImagePicker();
                    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                    if (image != null) {
                      setDialogState(() { _selectedImageFile = image; });
                    }
                  },
                  child: Container(
                    width: double.infinity, height: 200,
                    decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade300)),
                    child: _selectedImageFile != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: kIsWeb
                                ? FutureBuilder<Uint8List>(
                                    future: _selectedImageFile!.readAsBytes(),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData) return Image.memory(snapshot.data!, fit: BoxFit.cover);
                                      return const Center(child: CircularProgressIndicator());
                                    },
                                  )
                                : Image.file(File(_selectedImageFile!.path), fit: BoxFit.cover),
                          )
                        : const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_photo_alternate, size: 50, color: Colors.grey), SizedBox(height: 8), Text("Tap untuk pilih gambar", style: TextStyle(color: Colors.grey))])),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(controller: captionController, enabled: !isUploading, maxLines: 3, style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87), decoration: InputDecoration(labelText: "Caption", labelStyle: TextStyle(color: isDarkMode ? Colors.white70 : Colors.grey.shade600), filled: true, fillColor: isDarkMode ? const Color(0xFF2C2C3E) : Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none))),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: isUploading ? null : () => Navigator.pop(ctx), child: const Text("Batal")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF6A8B8), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              onPressed: isUploading ? null : () async {
                if (captionController.text.trim().isEmpty && _selectedImageFile == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Minimal isi caption atau pilih gambar!"), backgroundColor: Colors.redAccent));
                  return;
                }
                setDialogState(() => isUploading = true);
                try {
                  final Uint8List? imageBytes = await _selectedImageFile?.readAsBytes();
                  final String fileName = _selectedImageFile?.name ?? 'image.jpg';

                  final response = await ApiService.uploadPost(widget.channel['id'], captionController.text.trim(), imageBytes, fileName, 'image');

                  if (response['status'] == 'success') {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Post berhasil diupload!"), backgroundColor: Colors.green));
                    
                    // ✅ OPTIMASI: Pastikan URL gambar dari backend diproses dengan benar sebelum masuk ke list
                    var newPost = response['data'];
                    // Jika backend mengembalikan path relatif, kita bisa prepending di sini jika perlu, 
                    // tapi biasanya _buildPostItem sudah menanganinya.
                    
                    setState(() { 
                      _posts.insert(0, newPost); 
                    });
                  } else {
                    throw Exception(response['message']);
                  }
                } catch (e) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal: ${e.toString()}"), backgroundColor: Colors.redAccent));
                }
              },
              child: isUploading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white))) : const Text("Upload", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
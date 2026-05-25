import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import '../../services/knowledge_service.dart';

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> messages = [];
  bool _isTyping = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    KnowledgeService.initialize();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is String) {
        _handleScanPrompt(args);
      } else {
        setState(() {
          messages.add({
            "sender": "bot",
            "text": KnowledgeService.getWelcomeMessage(),
          });
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleScanPrompt(String scanPrompt) {
    setState(() {
      messages.add({
        "sender": "user",
        "text": "Bantu aku berdasarkan hasil scan wajahku",
      });
    });
    _getAIResponse(scanPrompt);
  }

  void _getAIResponse(String message) async {
    setState(() {
      _isTyping = true;
    });

    try {
      final botReply = await KnowledgeService.getResponse(message);
      _simulateTyping(botReply);
    } catch (e) {
      if (mounted) {
        setState(() {
          messages.add({"sender": "bot", "text": "Ups! Ada sedikit gangguan teknis.\nCoba tanyakan lagi ya! 🌸"});
          _isTyping = false;
        });
      }
    }
  }

  void sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    final userMessage = _controller.text;
    _controller.clear();

    setState(() {
      messages.add({"sender": "user", "text": userMessage});
    });

    final salamResponse = _checkSalam(userMessage);
    if (salamResponse != null) {
      _simulateTyping(salamResponse);
      return;
    }

    _getAIResponse(userMessage);
  }

  String? _checkSalam(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('halo') || lower.contains('hai') || lower.contains('hi')) {
      return "Hai juga! ✨ Aku GlowBot, siap bantu kamu dengan informasi skincare lengkap dan tips praktis!";
    }
    if (lower.contains('pagi')) {
      return "Selamat pagi! 🌞 Semangat ya hari ini! Aku GlowBot, siap bantu perawatan kulit kamu.";
    }
    if (lower.contains('siang')) {
      return "Selamat siang! 🌤 Aku GlowBot, ada pertanyaan seputar skincare yang bisa aku bantu?";
    }
    if (lower.contains('sore')) {
      return "Selamat sore! 🌅 Aku GlowBot, waktunya perawatan kulit nih!";
    }
    if (lower.contains('malam')) {
      return "Selamat malam! 🌙 Aku GlowBot, jangan lupa perawatan kulit sebelum tidur ya!";
    }
    if (lower.contains('assalamualaikum') || lower.contains('salam')) {
      return "Wa'alaikumsalam! ✨ Aku GlowBot, semoga harimu penuh berkah! Mau tanya apa soal skincare?";
    }
    if (lower.contains('terima kasih') || lower.contains('makasih')) {
      return "Sama-sama! 💖 Aku GlowBot selalu siap bantu kamu. Mau tanya apa lagi?";
    }
    return null;
  }

  void _simulateTyping(String fullText) {
    if (!mounted) return;

    final botMessage = {"sender": "bot", "text": "", "isTyping": true};
    messages.add(botMessage);

    int index = 0;
    const duration = Duration(milliseconds: 10);

    Timer.periodic(duration, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (index < fullText.length) {
          botMessage["text"] = fullText.substring(0, index + 1);
          index++;
        } else {
          botMessage["isTyping"] = false;
          _isTyping = false;
          timer.cancel();
        }
      });
    });
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
        // ✅ HAPUS PROPETI 'leading' INI AGAR TIDAK ADA TOMBOL BACK
        /*
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: isDarkMode ? Colors.white : Colors.black87),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        */
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: primaryColor.withOpacity(0.2),
              child: Image.asset(
                'assets/icons/glowmate_icon.png',
                width: 20,
                height: 20,
                color: secondaryColor,
                errorBuilder: (_, __, ___) => Icon(Icons.smart_toy, color: secondaryColor, size: 20),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              "GlowBot",
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              reverse: true,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[messages.length - 1 - index];
                return _buildMessageBubble(msg, isDarkMode, primaryColor, secondaryColor);
              },
            ),
          ),
          
          if (!_isTyping) _buildQuickQuestions(isDarkMode, primaryColor),
          
          _buildChatInput(isDarkMode, primaryColor, secondaryColor),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg, bool isDarkMode, Color primaryColor, Color secondaryColor) {
    final text = msg["text"];
    final isUser = msg["sender"] == "user";
    
    final RegExp youtubeLinkRegex = RegExp(r'https?://www\.youtube\.com/watch\?v=[^\s]+');
    final Match? match = youtubeLinkRegex.firstMatch(text);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: primaryColor.withOpacity(0.2),
              child: Image.asset(
                'assets/icons/glowmate_icon.png',
                width: 20,
                height: 20,
                color: secondaryColor,
                errorBuilder: (_, __, ___) => Icon(Icons.smart_toy, color: secondaryColor, size: 20),
              ),
            ),
            const SizedBox(width: 10),
          ],
          
          Flexible(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isUser 
                    ? secondaryColor 
                    : (isDarkMode ? const Color(0xFF1E1E2E) : Colors.white),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: isUser ? const Radius.circular(20) : const Radius.circular(4),
                  bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    match != null ? text.replaceAll(youtubeLinkRegex, '').trim() : text,
                    style: TextStyle(
                      color: isUser ? Colors.white : (isDarkMode ? Colors.white : Colors.black87),
                      height: 1.5,
                      fontSize: 15,
                    ),
                  ),
                  
                  if (match != null) ...[
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () async {
                        final link = match.group(0)!;
                        if (await canLaunchUrl(Uri.parse(link))) {
                          await launchUrl(Uri.parse(link));
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isUser ? Colors.white.withOpacity(0.2) : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.play_circle_fill, color: isUser ? Colors.white : Colors.redAccent, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              "Tonton Tutorial",
                              style: TextStyle(
                                color: isUser ? Colors.white : Colors.redAccent,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          if (isUser) const SizedBox(width: 10),
        ],
      ),
    );
  }

  Widget _buildQuickQuestions(bool isDarkMode, Color primaryColor) {
    final questions = KnowledgeService.getQuickQuestions();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: questions.take(4).map((q) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              label: Text(q, style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500)),
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              onPressed: () {
                _controller.text = q;
                sendMessage();
              },
            ),
          )).toList(),
        ),
      ),
    );
  }

  Widget _buildChatInput(bool isDarkMode, Color primaryColor, Color secondaryColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF121212) : const Color(0xFFFFF9FA),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              onSubmitted: (_) => sendMessage(),
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                hintText: "Tulis pertanyaan skincare...",
                hintStyle: TextStyle(color: isDarkMode ? Colors.white54 : Colors.grey.shade500),
                filled: true,
                fillColor: isDarkMode ? const Color(0xFF1E1E2E) : Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: primaryColor, width: 2),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: sendMessage,
            child: CircleAvatar(
              radius: 24,
              backgroundColor: secondaryColor,
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}
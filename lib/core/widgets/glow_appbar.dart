// lib/core/widgets/glow_appbar.dart
import 'package:flutter/material.dart';

class GlowAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const GlowAppBar({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
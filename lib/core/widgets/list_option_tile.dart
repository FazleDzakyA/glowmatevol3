// lib/core/widgets/list_option_tile.dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ListOptionTile extends StatelessWidget {
  const ListOptionTile({super.key, 
    required this.icon,
    required this.title,
    required this.route,
  });

  final IconData icon;
  final String title;
  final String route;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.pink500),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF2E2E2E), // Ganti dengan kode di bawah
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 18),
      onTap: () => Navigator.pushNamed(context, route),
    );
  }
}

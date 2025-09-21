import 'package:flutter/material.dart';
import '../core/app_config.dart';

class GradientIconCircle extends StatelessWidget {
  final bool isDarkMode;
  final IconData icon;
  final double size;
  const GradientIconCircle({super.key, required this.isDarkMode, required this.icon, this.size = 56});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: isDarkMode ? AppGradients.badgeDark : AppGradients.badgeLight),
      ),
      child: Icon(icon, color: Colors.white, size: size * 0.5),
    );
  }
}



import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';

class KPICard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final bool isDark;
  final String badgeText;

  const KPICard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    this.isDark = false,
    required this.badgeText,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? AppColors.primaryDark : AppColors.primaryYellow;
    final textColor = isDark ? Colors.white : AppColors.textDark;

    return Expanded(
      child: Container(
        height: 140,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: textColor, size: 28),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(badgeText, style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.bold)),
                )
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(color: textColor, fontSize: 32, fontWeight: FontWeight.bold)),
                Text(subtitle, style: TextStyle(color: textColor.withOpacity(0.8), fontSize: 14)),
              ],
            )
          ],
        ),
      ),
    );
  }
}
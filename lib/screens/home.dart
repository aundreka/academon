import 'package:flutter/material.dart';

import '../core/theme/colors.dart';
import '../core/theme/spacing.dart';
import '../core/theme/textstyles.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ScreenPlaceholder(
      title: 'Home',
      subtitle: 'Jump back into the adventure from the central hub.',
      icon: Icons.home_outlined,
    );
  }
}

class _ScreenPlaceholder extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _ScreenPlaceholder({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.lg),
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.primary.withOpacity(0.18)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 42, color: AppColors.accent),
            const SizedBox(height: AppSpacing.md),
            Text(title, style: AppTextStyles.title),
            const SizedBox(height: AppSpacing.sm),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}

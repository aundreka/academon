import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/textstyles.dart';
import '../../core/widgets/ui/bottomnav.dart';
import '../../core/widgets/ui/topnav.dart';
import '../../app_shell.dart';

class FocusScreen extends StatelessWidget {
  const FocusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _StudyNavScreen(
      currentIndex: 3,
      title: 'Focus',
      subtitle: 'Set up distraction-free study sessions with a steady pace.',
      icon: Icons.center_focus_strong_outlined,
    );
  }
}

class _StudyNavScreen extends StatelessWidget {
  final int currentIndex;
  final String title;
  final String subtitle;
  final IconData icon;

  const _StudyNavScreen({
    required this.currentIndex,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const AppTopNav(),
          Expanded(
            child: Center(
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
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: currentIndex,
        onTap: (index) => _goToRootTab(context, index),
      ),
    );
  }

  void _goToRootTab(BuildContext context, int index) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => MainScreen(initialIndex: index),
      ),
      (route) => false,
    );
  }
}

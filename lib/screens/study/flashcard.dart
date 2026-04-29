import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/textstyles.dart';
import '../../core/widgets/ui/topnav.dart';
class FlashcardsScreen extends StatelessWidget {
  const FlashcardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        AppTopNav(),
        Expanded(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: FlashcardsTabPanel(),
          ),
        ),
      ],
    );
  }
}

class FlashcardsTabPanel extends StatelessWidget {
  const FlashcardsTabPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.card.withOpacity(0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.35),
          width: 1.2,
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(),
            const SizedBox(height: AppSpacing.md),
            _actionCard(
              title: '1. Upload PDF',
              subtitle: 'Choose your source file for flashcard generation.',
              buttonText: 'Choose PDF',
              icon: Icons.upload_file_rounded,
            ),
            const SizedBox(height: AppSpacing.md),
            _actionCard(
              title: '2. Generate Flashcards',
              subtitle: 'Create a study deck from the uploaded document.',
              buttonText: 'Generate Flashcards',
              icon: Icons.auto_awesome_rounded,
              emphasize: true,
            ),
            const SizedBox(height: AppSpacing.md),
            _generatedSection(),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.16),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.style_rounded, color: AppColors.accent),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            'Flashcards',
            style: AppTextStyles.title.copyWith(fontSize: 18),
          ),
        ),
      ],
    );
  }

  Widget _actionCard({
    required String title,
    required String subtitle,
    required String buttonText,
    required IconData icon,
    bool emphasize = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: emphasize
            ? AppColors.primary.withOpacity(0.14)
            : AppColors.background.withOpacity(0.3),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: emphasize
              ? AppColors.accent.withOpacity(0.35)
              : AppColors.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.button.copyWith(fontSize: 14)),
          const SizedBox(height: AppSpacing.xs),
          Text(subtitle, style: AppTextStyles.body.copyWith(fontSize: 12)),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.9),
                  AppColors.accent.withOpacity(0.75),
                ],
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: AppColors.textPrimary, size: 18),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  buttonText,
                  style: AppTextStyles.button.copyWith(fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _generatedSection() {
    Widget card(int index, String q, String a) => Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.card.withOpacity(0.78),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Card $index',
                style: AppTextStyles.body.copyWith(
                  fontSize: 11,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(q, style: AppTextStyles.button.copyWith(fontSize: 13)),
              const SizedBox(height: AppSpacing.xs),
              Text(a, style: AppTextStyles.body.copyWith(fontSize: 12)),
            ],
          ),
        );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.34),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Generated Flashcards',
            style: AppTextStyles.button.copyWith(fontSize: 14),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Preview only. Generated cards will appear here.',
            style: AppTextStyles.body.copyWith(fontSize: 12),
          ),
          const SizedBox(height: AppSpacing.sm),
          card(
            1,
            'What is the main concept from the uploaded PDF?',
            'A short answer preview appears here after generation.',
          ),
          const SizedBox(height: AppSpacing.sm),
          card(
            2,
            'How is this concept applied in practice?',
            'Another answer preview appears in this section.',
          ),
        ],
      ),
    );
  }
}

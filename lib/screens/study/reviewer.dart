import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/textstyles.dart';
import '../../core/widgets/ui/topnav.dart';
class ReviewerScreen extends StatelessWidget {
  const ReviewerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        AppTopNav(),
        Expanded(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: ReviewerTabPanel(),
          ),
        ),
      ],
    );
  }
}

class ReviewerTabPanel extends StatelessWidget {
  const ReviewerTabPanel({super.key});

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
          children: [_header(), const SizedBox(height: AppSpacing.md), ..._content()],
        ),
      ),
    );
  }

  Widget _header() => Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.fact_check_outlined, color: AppColors.accent),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Reviewer',
              style: AppTextStyles.title.copyWith(fontSize: 18),
            ),
          ),
        ],
      );

  List<Widget> _content() => [
        _actionCard(
          title: '1. Upload PDF',
          subtitle: 'Choose the document you want to review.',
          buttonText: 'Choose PDF',
          icon: Icons.upload_file_rounded,
        ),
        const SizedBox(height: AppSpacing.md),
        _actionCard(
          title: '2. Generate Reviewer',
          subtitle: 'Create section-by-section reviewer notes from your PDF.',
          buttonText: 'Generate Reviewer',
          icon: Icons.auto_awesome_rounded,
          emphasize: true,
        ),
        const SizedBox(height: AppSpacing.md),
        _generatedSection(),
      ];

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
    Widget section(
      int index,
      String title,
      String summary,
      List<String> points,
    ) =>
        Container(
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
                'Section $index',
                style: AppTextStyles.body.copyWith(
                  fontSize: 11,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(title, style: AppTextStyles.button.copyWith(fontSize: 13)),
              const SizedBox(height: AppSpacing.xs),
              Text(summary, style: AppTextStyles.body.copyWith(fontSize: 12)),
              const SizedBox(height: AppSpacing.xs),
              ...points.map(
                (p) => Text('- $p', style: AppTextStyles.body.copyWith(fontSize: 12)),
              ),
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
            'Generated Reviewer Sections',
            style: AppTextStyles.button.copyWith(fontSize: 14),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Preview only. Generated reviewer content appears here.',
            style: AppTextStyles.body.copyWith(fontSize: 12),
          ),
          const SizedBox(height: AppSpacing.sm),
          section(
            1,
            'Core Concepts',
            'A concise summary of the section appears here after generation.',
            ['Key point one from this section.', 'Key point two from this section.'],
          ),
          const SizedBox(height: AppSpacing.sm),
          section(
            2,
            'Applications',
            'Another section summary card to preview reviewer layout.',
            ['First practical takeaway.', 'Second practical takeaway.'],
          ),
        ],
      ),
    );
  }
}

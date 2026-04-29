import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/textstyles.dart';
import '../../core/widgets/ui/topnav.dart';
class FocusScreen extends StatelessWidget {
  const FocusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        AppTopNav(),
        Expanded(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: FocusTabPanel(),
          ),
        ),
      ],
    );
  }
}

class FocusTabPanel extends StatelessWidget {
  const FocusTabPanel({super.key});

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
            _durationCard(),
            const SizedBox(height: AppSpacing.md),
            _timerCard(),
            const SizedBox(height: AppSpacing.md),
            _encouragementCard(),
            const SizedBox(height: AppSpacing.md),
            _controlsCard(),
          ],
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
            child: const Icon(
              Icons.center_focus_strong_outlined,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Focus',
              style: AppTextStyles.title.copyWith(fontSize: 18),
            ),
          ),
        ],
      );

  Widget _durationCard() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.14),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.accent.withOpacity(0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Set Duration',
              style: AppTextStyles.button.copyWith(fontSize: 14),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Preview only. Choose your focus length before starting.',
              style: AppTextStyles.body.copyWith(fontSize: 12),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                _MiniPill('-5'),
                _MiniPill('-1'),
                _MiniPill('25m'),
                _MiniPill('+1'),
                _MiniPill('+5'),
              ],
            ),
          ],
        ),
      );

  Widget _timerCard() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.background.withOpacity(0.34),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(
              'Ready to Focus',
              style: AppTextStyles.body.copyWith(fontSize: 11, color: AppColors.accent),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text('25:00', style: AppTextStyles.title.copyWith(fontSize: 36)),
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: 0.36,
                minHeight: 10,
                backgroundColor: AppColors.card.withOpacity(0.8),
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.primary.withOpacity(0.9),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '36% of current session',
              style: AppTextStyles.body.copyWith(fontSize: 12),
            ),
          ],
        ),
      );

  Widget _encouragementCard() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.card.withOpacity(0.78),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text('🐾', style: AppTextStyles.title.copyWith(fontSize: 24)),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Biscuit is sitting beside you. You got this.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(fontSize: 13),
            ),
          ],
        ),
      );

  Widget _controlsCard() => Column(
        children: const [
          _ActionButton(label: 'Start Session', icon: Icons.play_arrow_rounded),
          SizedBox(height: AppSpacing.sm),
          _ActionButton(
            label: 'Reset Timer',
            icon: Icons.restart_alt_rounded,
            muted: true,
          ),
        ],
      );
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    this.muted = false,
  });

  final String label;
  final IconData icon;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.sm,
        horizontal: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: muted
            ? null
            : LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.9),
                  AppColors.accent.withOpacity(0.75),
                ],
              ),
        color: muted ? AppColors.background.withOpacity(0.35) : null,
        border: Border.all(
          color: muted
              ? AppColors.primary.withOpacity(0.2)
              : AppColors.accent.withOpacity(0.35),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.textPrimary, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: AppTextStyles.button.copyWith(fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  const _MiniPill(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Text(
        text,
        style: AppTextStyles.button.copyWith(fontSize: 12),
      ),
    );
  }
}

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/reward.dart';
import '../../theme/spacing.dart';
import '../../theme/textstyles.dart';
import 'reward.dart';

class DailyRewardsCard extends StatelessWidget {
  final int daysPlayed;
  final int claimedDayIndex;
  final List<Reward> rewards;
  final Future<void> Function(int dayIndex, Reward reward) onClaim;

  const DailyRewardsCard({
    super.key,
    required this.daysPlayed,
    required this.claimedDayIndex,
    required this.rewards,
    required this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    final unlockedCount = math.min(math.max(daysPlayed, 1), rewards.length);
    final availableDayIndex = unlockedCount - 1;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF44276F),
            Color(0xFF6A45A5),
            Color(0xFFFF9FD6),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF321A57).withOpacity(0.28),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily Claims',
            style: AppTextStyles.title.copyWith(fontSize: 20),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Log in each day to unlock the next reward in this seven-day streak.',
            style: AppTextStyles.body.copyWith(
              color: const Color(0xFFFFF0FB),
              fontWeight: FontWeight.w700,
              height: 1.45,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = math.max(96.0, (constraints.maxWidth - (AppSpacing.sm * 3)) / 4);

              return Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (var i = 0; i < rewards.length; i++)
                    SizedBox(
                      width: cardWidth,
                      child: _DailyRewardTile(
                        dayNumber: i + 1,
                        reward: rewards[i],
                        isUnlocked: i <= availableDayIndex,
                        isClaimed: i <= claimedDayIndex,
                        isToday: i == availableDayIndex && i > claimedDayIndex,
                        onTap: i == availableDayIndex && i > claimedDayIndex
                            ? () => onClaim(i, rewards[i])
                            : null,
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class DailyRewardsDialog extends StatelessWidget {
  final int daysPlayed;
  final int claimedDayIndex;
  final List<Reward> rewards;
  final Future<void> Function(int dayIndex, Reward reward) onClaim;

  const DailyRewardsDialog({
    super.key,
    required this.daysPlayed,
    required this.claimedDayIndex,
    required this.rewards,
    required this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(AppSpacing.lg),
      child: SingleChildScrollView(
        child: DailyRewardsCard(
          daysPlayed: daysPlayed,
          claimedDayIndex: claimedDayIndex,
          rewards: rewards,
          onClaim: onClaim,
        ),
      ),
    );
  }
}

class _DailyRewardTile extends StatelessWidget {
  final int dayNumber;
  final Reward reward;
  final bool isUnlocked;
  final bool isClaimed;
  final bool isToday;
  final VoidCallback? onTap;

  const _DailyRewardTile({
    required this.dayNumber,
    required this.reward,
    required this.isUnlocked,
    required this.isClaimed,
    required this.isToday,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isClaimed
        ? const Color(0xFFB6FFD8)
        : isToday
            ? const Color(0xFFFFE68A)
            : isUnlocked
                ? Colors.white.withOpacity(0.16)
                : Colors.white.withOpacity(0.08);
    final textColor = isClaimed
        ? const Color(0xFF1C5A35)
        : isToday
            ? const Color(0xFF624A00)
            : Colors.white;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: backgroundColor,
            border: Border.all(
              color: isToday
                  ? const Color(0xFFFFF2BC)
                  : Colors.white.withOpacity(isUnlocked ? 0.2 : 0.08),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Day $dayNumber',
                style: AppTextStyles.button.copyWith(
                  fontSize: 14,
                  color: textColor,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              RewardSummaryChips(
                reward: reward,
                lightMode: isClaimed || isToday,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                isClaimed
                    ? 'Claimed'
                    : isToday
                        ? 'Tap to claim'
                        : isUnlocked
                            ? 'Ready soon'
                            : 'Locked',
                style: AppTextStyles.body.copyWith(
                  color: textColor.withOpacity(0.9),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

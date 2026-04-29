import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/reward.dart';
import '../../theme/spacing.dart';
import '../../theme/textstyles.dart';

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
              final columnCount = math.max(
                2,
                math.min(4, (constraints.maxWidth / 120).floor()),
              );
              final rowCount = (rewards.length / columnCount).ceil();
              final gridHeight =
                  (rowCount * _DailyRewardTile.tileHeight) +
                  (math.max(0, rowCount - 1) * AppSpacing.sm);

              return SizedBox(
                height: gridHeight,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columnCount,
                    crossAxisSpacing: AppSpacing.sm,
                    mainAxisSpacing: AppSpacing.sm,
                    mainAxisExtent: _DailyRewardTile.tileHeight,
                  ),
                  itemCount: rewards.length,
                  itemBuilder: (context, index) {
                    return _DailyRewardTile(
                      dayNumber: index + 1,
                      reward: rewards[index],
                      isUnlocked: index <= availableDayIndex,
                      isClaimed: index <= claimedDayIndex,
                      isToday: index == availableDayIndex && index > claimedDayIndex,
                      onTap: index == availableDayIndex && index > claimedDayIndex
                          ? () => onClaim(index, rewards[index])
                          : null,
                    );
                  },
                ),
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
  static const double tileHeight = 170;

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
              _DailyRewardDetails(
                reward: reward,
                lightMode: isClaimed || isToday,
              ),
              const Spacer(),
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

class _DailyRewardDetails extends StatelessWidget {
  final Reward reward;
  final bool lightMode;

  const _DailyRewardDetails({
    required this.reward,
    required this.lightMode,
  });

  @override
  Widget build(BuildContext context) {
    final rewards = <Widget>[
      if (reward.coins > 0)
        _DailyRewardValue(
          icon: Icons.monetization_on_rounded,
          value: '${reward.coins}',
          color: lightMode ? const Color(0xFF8C6500) : const Color(0xFFFFD15C),
        ),
      if (reward.xp > 0)
        _DailyRewardValue(
          icon: Icons.bolt_rounded,
          value: '${reward.xp}',
          color: lightMode ? const Color(0xFF0F5868) : const Color(0xFF7CEBFF),
        ),
      if (reward.diamonds > 0)
        _DailyRewardValue(
          icon: Icons.diamond_rounded,
          value: '${reward.diamonds}',
          color: lightMode ? const Color(0xFF623D8E) : const Color(0xFFFFA0F4),
        ),
      if (reward.items.isNotEmpty)
        _DailyRewardValue(
          icon: Icons.inventory_2_rounded,
          value: '${reward.items.length}',
          color: lightMode ? const Color(0xFF1F6A45) : const Color(0xFFA5FFCA),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < rewards.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.xs),
          rewards[i],
        ],
      ],
    );
  }
}

class _DailyRewardValue extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;

  const _DailyRewardValue({
    required this.icon,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.body.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

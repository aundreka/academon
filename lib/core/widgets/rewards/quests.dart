import 'package:flutter/material.dart';

import '../../models/quest.dart';
import '../../theme/spacing.dart';
import '../../theme/textstyles.dart';
import 'reward.dart';

class QuestsDialog extends StatelessWidget {
  final List<Quest> quests;
  final Set<String> claimedQuestIds;
  final Future<void> Function(Quest quest) onClaim;
  final Future<void> Function()? onRefresh;

  const QuestsDialog({
    super.key,
    required this.quests,
    required this.claimedQuestIds,
    required this.onClaim,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(AppSpacing.lg),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 620),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: const Color(0xFF102039).withOpacity(0.96),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF07111F).withOpacity(0.28),
              blurRadius: 24,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Daily Quests',
                      style: AppTextStyles.title.copyWith(fontSize: 20),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Fresh goals pulled from the quest catalog. Open this anytime to claim your next win.',
                style: AppTextStyles.body.copyWith(
                  color: const Color(0xFFD6E6FF),
                  height: 1.45,
                ),
              ),
              if (_canRefresh) ...[
                const SizedBox(height: AppSpacing.md),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: onRefresh,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(
                      'Refresh quests',
                      style: AppTextStyles.button.copyWith(fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFD6E6FF),
                      side: const BorderSide(color: Color(0xFF5C8DFF)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              for (final quest in quests) ...[
                _QuestTile(
                  quest: quest,
                  claimed: claimedQuestIds.contains(quest.id),
                  onClaim: () => onClaim(quest),
                ),
                if (quest != quests.last) const SizedBox(height: AppSpacing.md),
              ],
            ],
          ),
        ),
      ),
    );
  }

  bool get _canRefresh =>
      onRefresh != null &&
      quests.isNotEmpty &&
      quests.every((quest) => claimedQuestIds.contains(quest.id));
}

class _QuestTile extends StatelessWidget {
  final Quest quest;
  final bool claimed;
  final VoidCallback onClaim;

  const _QuestTile({
    required this.quest,
    required this.claimed,
    required this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    final accent = _rarityColor(quest.rarity);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white.withOpacity(0.05),
        border: Border.all(
          color: accent.withOpacity(0.38),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              color: accent,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      quest.title,
                      style: AppTextStyles.button.copyWith(fontSize: 16),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        quest.rarity.label,
                        style: AppTextStyles.body.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  quest.description,
                  style: AppTextStyles.body.copyWith(
                    color: const Color(0xFFD7E8FF),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                RewardSummaryChips(reward: quest.reward),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          FilledButton(
            onPressed: claimed ? null : onClaim,
            style: FilledButton.styleFrom(
              backgroundColor: claimed ? Colors.white24 : accent,
              foregroundColor: claimed ? Colors.white70 : const Color(0xFF102039),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              claimed ? 'Claimed' : 'Claim',
              style: AppTextStyles.button.copyWith(
                fontSize: 13,
                color: claimed ? Colors.white70 : const Color(0xFF102039),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _rarityColor(QuestRarity rarity) {
    switch (rarity) {
      case QuestRarity.common:
        return const Color(0xFF8DE3FF);
      case QuestRarity.uncommon:
        return const Color(0xFF95F59B);
      case QuestRarity.rare:
        return const Color(0xFFFFD166);
      case QuestRarity.epic:
        return const Color(0xFFFF97D2);
      case QuestRarity.legendary:
        return const Color(0xFFFFA86B);
    }
  }
}

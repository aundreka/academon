import 'package:flutter/material.dart';

import '../core/theme/colors.dart';
import '../core/theme/spacing.dart';
import '../core/theme/textstyles.dart';
import '../core/widgets/ui/topnav.dart';
import 'study/flashcard.dart';
import 'study/focus.dart';
import 'study/reviewer.dart';

class StudyScreen extends StatefulWidget {
  const StudyScreen({super.key});

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> {
  int? _selectedTabIndex;
  final int _level = 7;
  final int _xp = 1280;
  final int _xpToNext = 1600;
  final int _streakDays = 4;
  final int _todayQuestsDone = 1;

  static const List<_StudyTabItem> _tabs = [
    _StudyTabItem(
      label: 'Reviewer Quest',
      subtitle: 'Summarize lessons and test recall.',
      reward: '+8 XP',
      objective: 'Finish 2 lesson modules',
      progressLabel: '1/2 Done',
      difficulty: 'Medium',
      icon: Icons.fact_check_outlined,
      glowColor: Color(0xFF8A6DFF),
    ),
    _StudyTabItem(
      label: 'Flashcards Duel',
      subtitle: 'Flip cards and train fast memory.',
      reward: '+12 XP',
      objective: 'Master 20 cards',
      progressLabel: '8/20 Done',
      difficulty: 'Easy',
      icon: Icons.style_outlined,
      glowColor: Color(0xFF3BA6FF),
    ),
    _StudyTabItem(
      label: 'Focus Sprint',
      subtitle: 'Run timed sessions and build streaks.',
      reward: '+15 XP',
      objective: 'Complete 1 full pomodoro',
      progressLabel: '0/1 Done',
      difficulty: 'Hard',
      icon: Icons.center_focus_strong_outlined,
      glowColor: Color(0xFF00E5FF),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const AppTopNav(),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.card.withOpacity(0.72),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: _selectedTabIndex == null
                    ? _buildTabLauncher()
                    : _buildSelectedView(),
              ),
            ),
          ),
        ),
      ],
    );
  }
  Widget _buildTabLauncher() {
    final levelProgress = _xp / _xpToNext;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withOpacity(0.26),
                AppColors.background.withOpacity(0.48),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: AppColors.primary.withOpacity(0.42)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.background.withOpacity(0.45),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.primary.withOpacity(0.6)),
                    ),
                    child: Center(
                      child: Text(
                        'Lv$_level',
                        style: AppTextStyles.button.copyWith(fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Scholar Campaign',
                          style: AppTextStyles.title.copyWith(fontSize: 16),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Stack XP by finishing missions today.',
                          style: AppTextStyles.body.copyWith(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: levelProgress.clamp(0.0, 1.0),
                  minHeight: 7,
                  backgroundColor: AppColors.background.withOpacity(0.45),
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$_xp / $_xpToNext XP to next level',
                style: AppTextStyles.body.copyWith(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            _buildBadgeChip(
              icon: Icons.local_fire_department_outlined,
              label: '$_streakDays day streak',
            ),
            const SizedBox(width: AppSpacing.xs),
            _buildBadgeChip(
              icon: Icons.workspace_premium_outlined,
              label: '$_todayQuestsDone/3 quests',
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Daily Mission Board',
          style: AppTextStyles.button.copyWith(fontSize: 13),
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: Column(
            children: List.generate(_tabs.length, (index) {
              final tab = _tabs[index];
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: index == _tabs.length - 1 ? 0 : AppSpacing.sm,
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      setState(() => _selectedTabIndex = index);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.md,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            tab.glowColor.withOpacity(0.22),
                            AppColors.background.withOpacity(0.45),
                          ],
                        ),
                        border: Border.all(
                          color: tab.glowColor.withOpacity(0.55),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: tab.glowColor.withOpacity(0.22),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: tab.glowColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              tab.icon,
                              color: AppColors.textPrimary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  tab.label,
                                  style: AppTextStyles.button.copyWith(
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  tab.subtitle,
                                  style: AppTextStyles.body.copyWith(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.xs,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.background.withOpacity(0.35),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        tab.difficulty,
                                        style: AppTextStyles.body.copyWith(
                                          fontSize: 9,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        tab.objective,
                                        style: AppTextStyles.body.copyWith(
                                          fontSize: 10,
                                          color: AppColors.textSecondary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.background.withOpacity(0.45),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: tab.glowColor.withOpacity(0.45),
                                  ),
                                ),
                                child: Text(
                                  tab.reward,
                                  style: AppTextStyles.body.copyWith(
                                    fontSize: 10,
                                    color: AppColors.accent,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                tab.progressLabel,
                                style: AppTextStyles.body.copyWith(
                                  fontSize: 9,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 14,
                                color: AppColors.textSecondary,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildBadgeChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.primary.withOpacity(0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.accent),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.body.copyWith(
              fontSize: 10,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedView() {
    final index = _selectedTabIndex ?? 0;
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => setState(() => _selectedTabIndex = null),
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.accent),
            label: Text(
              'Back to Study Tabs',
              style: AppTextStyles.button.copyWith(fontSize: 13),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: switch (index) {
            0 => const ReviewerTabPanel(),
            1 => const FlashcardsTabPanel(),
            _ => const FocusTabPanel(),
          },
        ),
      ],
    );
  }
}

class _StudyTabItem {
  const _StudyTabItem({
    required this.label,
    required this.subtitle,
    required this.reward,
    required this.objective,
    required this.progressLabel,
    required this.difficulty,
    required this.icon,
    required this.glowColor,
  });

  final String label;
  final String subtitle;
  final String reward;
  final String objective;
  final String progressLabel;
  final String difficulty;
  final IconData icon;
  final Color glowColor;
}

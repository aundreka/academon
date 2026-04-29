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

  static const List<_StudyTabItem> _tabs = [
    _StudyTabItem(label: 'Reviewer', icon: Icons.fact_check_outlined),
    _StudyTabItem(label: 'Flashcards', icon: Icons.style_outlined),
    _StudyTabItem(label: 'Focus', icon: Icons.center_focus_strong_outlined),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Study Modes',
          style: AppTextStyles.title.copyWith(fontSize: 16),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Choose a mode to start your session.',
          style: AppTextStyles.body.copyWith(fontSize: 12),
        ),
        const SizedBox(height: AppSpacing.md),
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
                        color: AppColors.background.withOpacity(0.42),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.22),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.14),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              tab.icon,
                              color: AppColors.accent,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              tab.label,
                              style: AppTextStyles.button.copyWith(fontSize: 14),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: AppColors.textSecondary,
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
  const _StudyTabItem({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

import 'package:flutter/material.dart';

import '../../models/study_topic.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/textstyles.dart';

class StudyTopicCard extends StatelessWidget {
  final StudyTopic topic;
  final String badgeLabel;
  final VoidCallback? onTap;

  const StudyTopicCard({
    super.key,
    required this.topic,
    required this.badgeLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.primary.withOpacity(0.18)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.08),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                SizedBox(
                  width: 110,
                  height: 110,
                  child: StudyTopicHero(topic: topic),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          badgeLabel,
                          style: AppTextStyles.body.copyWith(
                            fontSize: 10,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        topic.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.button.copyWith(fontSize: 15),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        topic.description,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body.copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class StudyTopicHero extends StatelessWidget {
  final StudyTopic topic;
  final double? height;

  const StudyTopicHero({
    super.key,
    required this.topic,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final imageBytes = topic.imageBytes;

    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.26),
            AppColors.accent.withOpacity(0.2),
            AppColors.background.withOpacity(0.94),
          ],
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageBytes != null)
            Image.memory(imageBytes, fit: BoxFit.cover)
          else if (topic.imageUrl.startsWith('http'))
            Image.network(
              topic.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  AppColors.background.withOpacity(0.16),
                  AppColors.background.withOpacity(0.9),
                ],
              ),
            ),
          ),
          Positioned(
            left: AppSpacing.md,
            right: AppSpacing.md,
            bottom: AppSpacing.md,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    topic.topic,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.button.copyWith(fontSize: 14),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    topic.difficulty.toUpperCase(),
                    style: AppTextStyles.body.copyWith(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

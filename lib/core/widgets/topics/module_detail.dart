import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/study_topic.dart';
import '../../services/study_topic_service.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/textstyles.dart';
import 'topic_views.dart';

class ModuleDetailScreen extends StatefulWidget {
  final String moduleId;
  final StudyTopic? initialModule;

  const ModuleDetailScreen({
    super.key,
    required this.moduleId,
    this.initialModule,
  });

  @override
  State<ModuleDetailScreen> createState() => _ModuleDetailScreenState();
}

class _ModuleDetailScreenState extends State<ModuleDetailScreen> {
  late final StudyTopicService _topicService;
  late Future<StudyTopic> _moduleFuture;

  @override
  void initState() {
    super.initState();
    _topicService = StudyTopicService(Supabase.instance.client);
    _moduleFuture = _topicService.fetchModuleDetail(widget.moduleId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        title: Text('Module Details', style: AppTextStyles.button),
      ),
      body: FutureBuilder<StudyTopic>(
        future: _moduleFuture,
        initialData: widget.initialModule,
        builder: (context, snapshot) {
          if (!snapshot.hasData && snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (snapshot.hasError && !snapshot.hasData) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  snapshot.error.toString().replaceFirst('Exception: ', ''),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(fontSize: 13),
                ),
              ),
            );
          }

          final module = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.xl,
            ),
            children: [
              StudyTopicHero(topic: module, height: 240),
              const SizedBox(height: AppSpacing.md),
              Text(module.title, style: AppTextStyles.title.copyWith(fontSize: 18)),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  _MetaChip(label: module.topic),
                  _MetaChip(label: module.category),
                  _MetaChip(label: module.difficulty.toUpperCase()),
                  _MetaChip(label: module.sourceType.toUpperCase()),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _SectionCard(
                title: 'Description',
                child: Text(
                  module.description,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 14,
                    color: Colors.white,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _SectionCard(
                title: 'Lessons Included',
                child: module.lessons.isEmpty
                    ? Text(
                        'No subtopics were added to this module yet.',
                        style: AppTextStyles.body.copyWith(fontSize: 13),
                      )
                    : Column(
                        children: module.lessons
                            .map(
                              (lesson) => Padding(
                                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                                child: _LessonTile(lesson: lesson),
                              ),
                            )
                            .toList(),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.primary.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.button.copyWith(fontSize: 14)),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}

class _LessonTile extends StatelessWidget {
  final StudyLesson lesson;

  const _LessonTile({required this.lesson});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.55),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.18),
              borderRadius: BorderRadius.circular(999),
            ),
            alignment: Alignment.center,
            child: Text(
              '${lesson.orderIndex + 1}',
              style: AppTextStyles.button.copyWith(fontSize: 12),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lesson.title,
                  style: AppTextStyles.button.copyWith(fontSize: 13),
                ),
                if (lesson.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    lesson.description,
                    style: AppTextStyles.body.copyWith(fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;

  const _MetaChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: AppTextStyles.body.copyWith(
          fontSize: 11,
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

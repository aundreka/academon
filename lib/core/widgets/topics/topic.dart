import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/study_topic.dart';
import '../../services/study_topic_service.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/textstyles.dart';
import 'chatbot.dart';
import 'module_detail.dart';
import 'topic_views.dart';

class TopicCatalogScreen extends StatefulWidget {
  const TopicCatalogScreen({super.key});

  @override
  State<TopicCatalogScreen> createState() => _TopicCatalogScreenState();
}

class _TopicCatalogScreenState extends State<TopicCatalogScreen> {
  late final StudyTopicService _topicService;
  late Future<List<StudyTopic>> _topicsFuture;

  @override
  void initState() {
    super.initState();
    _topicService = StudyTopicService(Supabase.instance.client);
    _topicsFuture = _topicService.fetchAvailableTopics();
  }

  Future<void> _refreshTopics() async {
    final future = _topicService.fetchAvailableTopics();
    setState(() => _topicsFuture = future);
    await future;
  }

  Future<void> _openChatbot() async {
    final created = await Navigator.of(context).push<StudyTopic>(
      MaterialPageRoute(builder: (_) => const ChatbotScreen()),
    );
    if (created == null || !mounted) return;
    await _refreshTopics();
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ModuleDetailScreen(
          moduleId: created.id,
          initialModule: created,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        title: Text('Topics', style: AppTextStyles.button),
        actions: [
          IconButton(
            onPressed: _openChatbot,
            icon: const Icon(Icons.smart_toy_outlined, color: AppColors.primary),
            tooltip: 'Generate a topic',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshTopics,
        child: FutureBuilder<List<StudyTopic>>(
          future: _topicsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            if (snapshot.hasError) {
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

            final topics = snapshot.data ?? const <StudyTopic>[];
            if (topics.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Text(
                    'No public topics are available yet.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body,
                  ),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: topics.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final topic = topics[index];
                return StudyTopicCard(
                  topic: topic,
                  badgeLabel: '${topic.popularityCount} learners',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => TopicDetailPreviewScreen(topic: topic),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class TopicDetailPreviewScreen extends StatelessWidget {
  final StudyTopic topic;

  const TopicDetailPreviewScreen({
    super.key,
    required this.topic,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        title: Text('Topic Preview', style: AppTextStyles.button),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          StudyTopicHero(topic: topic, height: 220),
          const SizedBox(height: AppSpacing.md),
          Text(topic.title, style: AppTextStyles.title.copyWith(fontSize: 18)),
          const SizedBox(height: AppSpacing.sm),
          Text(
            topic.description,
            style: AppTextStyles.body.copyWith(fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Included Lessons', style: AppTextStyles.button.copyWith(fontSize: 14)),
          const SizedBox(height: AppSpacing.sm),
          ...topic.lessons.map(
            (lesson) => Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                lesson.title,
                style: AppTextStyles.body.copyWith(fontSize: 13, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

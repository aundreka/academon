import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/study_topic.dart';
import '../../services/study_topic_service.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../theme/textstyles.dart';
import 'module_detail.dart';
import 'topic_views.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final _promptController = TextEditingController();
  late final StudyTopicService _topicService;
  final List<_ChatMessage> _messages = <_ChatMessage>[
    const _ChatMessage(
      sender: _ChatSender.bot,
      text:
          'Tell me what you want to learn. I can turn it into a study topic with lessons and add it to your modules.',
    ),
  ];
  bool _generating = false;
  StudyTopic? _generatedModule;

  @override
  void initState() {
    super.initState();
    _topicService = StudyTopicService(Supabase.instance.client);
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _generateTopic() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty || _generating) return;

    setState(() {
      _generating = true;
      _messages.add(_ChatMessage(sender: _ChatSender.user, text: prompt));
      _messages.add(
        const _ChatMessage(
          sender: _ChatSender.bot,
          text: 'Building your topic now. I\'m drafting lessons and saving it to your module list.',
          pending: true,
        ),
      );
    });
    _promptController.clear();

    try {
      final module = await _topicService.createGeneratedTopicModule(prompt);
      if (!mounted) return;

      setState(() {
        _generatedModule = module;
        _messages.removeWhere((message) => message.pending);
        _messages.add(
          _ChatMessage(
            sender: _ChatSender.bot,
            text:
                'Your new module is ready: ${module.title}. It now appears in your module list with ${module.lessons.length} lesson(s).',
          ),
        );
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _messages.removeWhere((message) => message.pending);
        _messages.add(
          _ChatMessage(
            sender: _ChatSender.bot,
            text: error.toString().replaceFirst('Exception: ', ''),
          ),
        );
      });
    } finally {
      if (mounted) {
        setState(() => _generating = false);
      }
    }
  }

  void _openModule() {
    final module = _generatedModule;
    if (module == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ModuleDetailScreen(
          moduleId: module.id,
          initialModule: module,
        ),
      ),
    );
  }

  void _finish() {
    Navigator.of(context).pop(_generatedModule);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        title: Text('Topic Chatbot', style: AppTextStyles.button),
        actions: [
          if (_generatedModule != null)
            TextButton(
              onPressed: _finish,
              child: Text(
                'Done',
                style: AppTextStyles.button.copyWith(
                  fontSize: 13,
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: _messages.length + (_generatedModule == null ? 0 : 1),
              itemBuilder: (context, index) {
                if (_generatedModule != null && index == _messages.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.md),
                    child: Column(
                      children: [
                        StudyTopicCard(
                          topic: _generatedModule!,
                          badgeLabel: 'Generated module',
                          onTap: _openModule,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton.icon(
                            onPressed: _finish,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.background,
                            ),
                            icon: const Icon(Icons.library_add_check_rounded),
                            label: Text(
                              'Use This Module',
                              style: AppTextStyles.button.copyWith(
                                fontSize: 13,
                                color: AppColors.background,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final message = _messages[index];
                final isUser = message.sender == _ChatSender.user;
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    constraints: const BoxConstraints(maxWidth: 320),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: isUser
                          ? AppColors.primary.withOpacity(0.18)
                          : AppColors.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isUser
                            ? AppColors.primary.withOpacity(0.35)
                            : Colors.white10,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isUser) ...[
                          const Icon(
                            Icons.smart_toy_outlined,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                        ],
                        Flexible(
                          child: Text(
                            message.text,
                            style: AppTextStyles.body.copyWith(
                              fontSize: 13,
                              color: Colors.white,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.primary.withOpacity(0.16)),
                      ),
                      child: TextField(
                        controller: _promptController,
                        minLines: 1,
                        maxLines: 4,
                        style: AppTextStyles.body.copyWith(color: Colors.white),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Example: I want to learn introduction to calculus',
                          hintStyle: AppTextStyles.body.copyWith(color: Colors.white38),
                        ),
                        onSubmitted: (_) => _generateTopic(),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  FilledButton(
                    onPressed: _generating ? null : _generateTopic,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.background,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: _generating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final _ChatSender sender;
  final String text;
  final bool pending;

  const _ChatMessage({
    required this.sender,
    required this.text,
    this.pending = false,
  });
}

enum _ChatSender {
  user,
  bot,
}

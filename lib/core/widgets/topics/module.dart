import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
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

class ModuleLibraryScreen extends StatefulWidget {
  const ModuleLibraryScreen({super.key});

  @override
  State<ModuleLibraryScreen> createState() => _ModuleLibraryScreenState();
}

class _ModuleLibraryScreenState extends State<ModuleLibraryScreen> {
  late final StudyTopicService _topicService;
  late Future<List<StudyTopic>> _modulesFuture;

  @override
  void initState() {
    super.initState();
    _topicService = StudyTopicService(Supabase.instance.client);
    _modulesFuture = _topicService.fetchUserModules();
  }

  Future<void> _refreshModules() async {
    final future = _topicService.fetchUserModules();
    setState(() {
      _modulesFuture = future;
    });
    await future;
  }

  Future<void> _openCreateModuleSheet() async {
    final created = await showModalBottomSheet<StudyTopic>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateModuleSheet(topicService: _topicService),
    );

    if (created == null || !mounted) return;
    await _refreshModules();
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ModuleDetailScreen(
          moduleId: created.id,
          initialModule: created,
        ),
      ),
    );
  }

  Future<void> _openChatbot() async {
    final created = await Navigator.of(context).push<StudyTopic>(
      MaterialPageRoute(builder: (_) => const ChatbotScreen()),
    );

    if (created == null) return;
    await _refreshModules();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        title: Text('My Modules', style: AppTextStyles.button),
        actions: [
          IconButton(
            onPressed: _openChatbot,
            icon: const Icon(Icons.auto_awesome_rounded, color: AppColors.accent),
            tooltip: 'Generate with chatbot',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateModuleSheet,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.background,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'New Module',
          style: AppTextStyles.button.copyWith(color: AppColors.background),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshModules,
        child: FutureBuilder<List<StudyTopic>>(
          future: _modulesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            if (snapshot.hasError) {
              return _ModuleStateMessage(
                icon: Icons.warning_amber_rounded,
                title: 'Unable to load modules',
                message: snapshot.error.toString().replaceFirst('Exception: ', ''),
              );
            }

            final modules = snapshot.data ?? const <StudyTopic>[];
            if (modules.isEmpty) {
              return const _ModuleStateMessage(
                icon: Icons.menu_book_rounded,
                title: 'No modules yet',
                message:
                    'Create one from scratch or ask the chatbot to generate a topic you want to learn.',
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                100,
              ),
              itemBuilder: (context, index) {
                final module = modules[index];
                return StudyTopicCard(
                  topic: module,
                  badgeLabel: module.sourceType == 'generated' ? 'AI module' : 'My module',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ModuleDetailScreen(
                          moduleId: module.id,
                          initialModule: module,
                        ),
                      ),
                    );
                  },
                );
              },
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
              itemCount: modules.length,
            );
          },
        ),
      ),
    );
  }
}

class _CreateModuleSheet extends StatefulWidget {
  final StudyTopicService topicService;

  const _CreateModuleSheet({
    required this.topicService,
  });

  @override
  State<_CreateModuleSheet> createState() => _CreateModuleSheetState();
}

class _CreateModuleSheetState extends State<_CreateModuleSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _topicController = TextEditingController();
  final _categoryController = TextEditingController();
  final _summaryController = TextEditingController();
  final _lessonsController = TextEditingController();
  String _difficulty = 'normal';
  Uint8List? _imageBytes;
  String? _imageExtension;
  bool _submitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _topicController.dispose();
    _categoryController.dispose();
    _summaryController.dispose();
    _lessonsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    final file = result?.files.single;
    if (file?.bytes == null) return;
    setState(() {
      _imageBytes = file!.bytes;
      _imageExtension = file.extension;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    try {
      final lessonLines = _lessonsController.text
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();

      final created = await widget.topicService.createModule(
        title: _titleController.text,
        topic: _topicController.text,
        summary: _summaryController.text,
        difficulty: _difficulty,
        category: _categoryController.text.trim().isEmpty
            ? _topicController.text
            : _categoryController.text,
        lessons: lessonLines
            .asMap()
            .entries
            .map(
              (entry) => StudyLesson(
                id: '',
                title: entry.value,
                description: '',
                orderIndex: entry.key,
              ),
            )
            .toList(),
        imageBytes: _imageBytes,
        imageExtension: _imageExtension,
      );

      if (!mounted) return;
      Navigator.of(context).pop(created);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(top: 48, bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 54,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text('Create Module', style: AppTextStyles.title.copyWith(fontSize: 16)),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Add a topic, summary, image, and the lessons included in this module.',
                  style: AppTextStyles.body.copyWith(fontSize: 13),
                ),
                const SizedBox(height: AppSpacing.md),
                _FieldShell(
                  child: TextFormField(
                    controller: _titleController,
                    style: AppTextStyles.body.copyWith(color: Colors.white),
                    decoration: _inputDecoration('Title'),
                    validator: (value) =>
                        value == null || value.trim().isEmpty ? 'Title is required.' : null,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _FieldShell(
                  child: TextFormField(
                    controller: _topicController,
                    style: AppTextStyles.body.copyWith(color: Colors.white),
                    decoration: _inputDecoration('Topic'),
                    validator: (value) =>
                        value == null || value.trim().isEmpty ? 'Topic is required.' : null,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _FieldShell(
                  child: TextFormField(
                    controller: _categoryController,
                    style: AppTextStyles.body.copyWith(color: Colors.white),
                    decoration: _inputDecoration('Category'),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _FieldShell(
                  child: DropdownButtonFormField<String>(
                    value: _difficulty,
                    dropdownColor: AppColors.card,
                    style: AppTextStyles.body.copyWith(color: Colors.white),
                    decoration: _inputDecoration('Difficulty'),
                    items: const ['easy', 'normal', 'hard', 'exam']
                        .map(
                          (value) => DropdownMenuItem<String>(
                            value: value,
                            child: Text(value.toUpperCase()),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _difficulty = value);
                      }
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _FieldShell(
                  child: TextFormField(
                    controller: _summaryController,
                    maxLines: 3,
                    style: AppTextStyles.body.copyWith(color: Colors.white),
                    decoration: _inputDecoration('Description'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Description is required.'
                        : null,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _FieldShell(
                  child: TextFormField(
                    controller: _lessonsController,
                    maxLines: 6,
                    style: AppTextStyles.body.copyWith(color: Colors.white),
                    decoration: _inputDecoration(
                      'Subtopics / Lessons',
                      hint: 'One lesson per line',
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Add at least one lesson.'
                        : null,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed: _pickImage,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.primary.withOpacity(0.55)),
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                  ),
                  icon: const Icon(Icons.image_outlined),
                  label: Text(
                    _imageBytes == null ? 'Upload Image' : 'Replace Image',
                    style: AppTextStyles.button.copyWith(fontSize: 13),
                  ),
                ),
                if (_imageBytes != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.memory(
                      _imageBytes!,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _submitting ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.background,
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            'Save Module',
                            style: AppTextStyles.button.copyWith(
                              color: AppColors.background,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
      hintStyle: AppTextStyles.body.copyWith(color: Colors.white38),
      border: InputBorder.none,
    );
  }
}

class _FieldShell extends StatelessWidget {
  final Widget child;

  const _FieldShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.75),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: child,
    );
  }
}

class _ModuleStateMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _ModuleStateMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.18),
        Icon(icon, color: AppColors.primary, size: 46),
        const SizedBox(height: AppSpacing.md),
        Text(
          title,
          textAlign: TextAlign.center,
          style: AppTextStyles.title.copyWith(fontSize: 16),
        ),
        const SizedBox(height: AppSpacing.sm),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(fontSize: 13),
          ),
        ),
      ],
    );
  }
}

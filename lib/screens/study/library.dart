import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/textstyles.dart';
import '../../core/widgets/ui/topnav.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        AppTopNav(),
        Expanded(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: LibraryTabPanel(),
          ),
        ),
      ],
    );
  }
}

class LibraryTabPanel extends StatefulWidget {
  const LibraryTabPanel({super.key});

  @override
  State<LibraryTabPanel> createState() => _LibraryTabPanelState();
}

class _LibraryTabPanelState extends State<LibraryTabPanel> {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const List<String> _difficultyOptions = ['easy', 'normal', 'hard', 'exam'];
  static const List<String> _statusOptions = ['processing', 'ready', 'failed', 'completed'];

  bool _isLoading = true;
  String? _error;
  List<_LibraryModuleItem> _modules = const [];

  @override
  void initState() {
    super.initState();
    _loadModules();
  }

  Future<void> _loadModules() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      setState(() {
        _isLoading = false;
        _error = 'Please sign in to view your study library.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final rawModules = await _supabase
          .from('modules')
          .select('id, title, topic, summary, difficulty, status, updated_at, created_at')
          .eq('user_id', userId)
          .order('updated_at', ascending: false);

      final modules = (rawModules as List)
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();

      if (modules.isEmpty) {
        setState(() {
          _modules = const [];
          _isLoading = false;
        });
        return;
      }

      final moduleIds = modules
          .map((item) => item['id'])
          .whereType<String>()
          .where((id) => id.isNotEmpty)
          .toList();

      final flashcardsByModule = <String, int>{};
      final reviewersByModule = <String, int>{};

      if (moduleIds.isNotEmpty) {
        try {
          final flashRows =
              await _supabase.from('flashcards').select('module_id').inFilter('module_id', moduleIds);
          for (final row in flashRows as List) {
            if (row is Map && row['module_id'] is String) {
              final moduleId = row['module_id'] as String;
              flashcardsByModule[moduleId] = (flashcardsByModule[moduleId] ?? 0) + 1;
            }
          }
        } catch (_) {
          // Keep rendering modules even if related table is not migrated yet.
        }

        try {
          final reviewerRows =
              await _supabase.from('reviewers').select('module_id').inFilter('module_id', moduleIds);
          for (final row in reviewerRows as List) {
            if (row is Map && row['module_id'] is String) {
              final moduleId = row['module_id'] as String;
              reviewersByModule[moduleId] = (reviewersByModule[moduleId] ?? 0) + 1;
            }
          }
        } catch (_) {
          // Keep rendering modules even if related table is not migrated yet.
        }
      }

      final parsed = modules.map((row) {
        final id = '${row['id'] ?? ''}';
        return _LibraryModuleItem(
          id: id,
          title: '${row['title'] ?? 'Untitled Module'}',
          topic: '${row['topic'] ?? 'General Study'}',
          difficulty: '${row['difficulty'] ?? 'normal'}',
          status: '${row['status'] ?? 'ready'}',
          updatedAt: '${row['updated_at'] ?? row['created_at'] ?? ''}',
          flashcards: flashcardsByModule[id] ?? 0,
          reviewers: reviewersByModule[id] ?? 0,
          summary: '${row['summary'] ?? ''}',
        );
      }).toList();

      if (!mounted) return;
      setState(() {
        _modules = parsed;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load library right now.\n$e';
        _isLoading = false;
      });
    }
  }

  Future<void> _createModule() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    final payload = await _openModuleEditor();
    if (payload == null) return;

    try {
      final now = DateTime.now().toUtc().toIso8601String();
      await _supabase.from('modules').insert({
        'user_id': userId,
        'title': payload.title,
        'topic': payload.topic,
        'difficulty': payload.difficulty,
        'status': payload.status,
        'source_type': 'topic',
        'summary': payload.summary,
        'last_used_at': now,
        'updated_at': now,
      });
      await _loadModules();
    } catch (e) {
      if (!mounted) return;
      _showToast('Failed to create module: $e');
    }
  }

  Future<void> _editModule(_LibraryModuleItem module) async {
    final payload = await _openModuleEditor(initial: module);
    if (payload == null) return;
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      await _supabase
          .from('modules')
          .update({
            'title': payload.title,
            'topic': payload.topic,
            'difficulty': payload.difficulty,
            'status': payload.status,
            'summary': payload.summary,
            'updated_at': now,
          })
          .eq('id', module.id);
      await _loadModules();
    } catch (e) {
      if (!mounted) return;
      _showToast('Failed to update module: $e');
    }
  }

  Future<void> _deleteModule(_LibraryModuleItem module) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.card,
            title: Text('Delete Module', style: AppTextStyles.button.copyWith(fontSize: 16)),
            content: Text(
              'Delete "${module.title}"?\nThis will also remove linked flashcards/reviewer data.',
              style: AppTextStyles.body.copyWith(fontSize: 12),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Cancel', style: AppTextStyles.body),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('Delete', style: AppTextStyles.button.copyWith(fontSize: 12)),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;
    try {
      await _supabase.from('modules').delete().eq('id', module.id);
      await _loadModules();
    } catch (e) {
      if (!mounted) return;
      _showToast('Failed to delete module: $e');
    }
  }

  Future<void> _openModuleDetails(_LibraryModuleItem module) async {
    List<Map<String, String>> flashcards = const [];
    List<Map<String, String>> reviewerSections = const [];

    try {
      final rows =
          await _supabase.from('flashcards').select('question, answer').eq('module_id', module.id).order('order_index');
      flashcards = (rows as List)
          .whereType<Map>()
          .map(
            (row) => {
              'question': '${row['question'] ?? '-'}',
              'answer': '${row['answer'] ?? '-'}',
            },
          )
          .toList();
    } catch (_) {
      flashcards = const [];
    }

    try {
      final rows = await _supabase.from('reviewers').select('title, content').eq('module_id', module.id);
      reviewerSections = (rows as List)
          .whereType<Map>()
          .map(
            (row) => {
              'title': '${row['title'] ?? 'Section'}',
              'content': '${row['content'] ?? ''}',
            },
          )
          .toList();
    } catch (_) {
      reviewerSections = const [];
    }

    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: AppColors.primary.withOpacity(0.28)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(module.title, style: AppTextStyles.title.copyWith(fontSize: 18)),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: AppColors.accent),
                  ),
                ],
              ),
              Text(
                '${module.topic} • ${module.difficulty} • ${module.status}',
                style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: ListView(
                  children: [
                    Text('Flashcards', style: AppTextStyles.button.copyWith(fontSize: 14)),
                    const SizedBox(height: AppSpacing.xs),
                    if (flashcards.isEmpty)
                      Text('No flashcards in this module.', style: AppTextStyles.body.copyWith(fontSize: 12))
                    else
                      ...flashcards.take(8).toList().asMap().entries.map(
                            (entry) => Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                              child: Container(
                                padding: const EdgeInsets.all(AppSpacing.sm),
                                decoration: BoxDecoration(
                                  color: AppColors.background.withOpacity(0.35),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.primary.withOpacity(0.25)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Card ${entry.key + 1}',
                                      style: AppTextStyles.body.copyWith(
                                        fontSize: 10,
                                        color: AppColors.accent,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Q: ${entry.value['question'] ?? '-'}',
                                      style: AppTextStyles.button.copyWith(fontSize: 12),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'A: ${entry.value['answer'] ?? '-'}',
                                      style: AppTextStyles.body.copyWith(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                    const SizedBox(height: AppSpacing.md),
                    Text('Reviewer Sections', style: AppTextStyles.button.copyWith(fontSize: 14)),
                    const SizedBox(height: AppSpacing.xs),
                    if (reviewerSections.isEmpty)
                      Text('No reviewer sections in this module.', style: AppTextStyles.body.copyWith(fontSize: 12))
                    else
                      ...reviewerSections.take(8).toList().asMap().entries.map(
                            (entry) => Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                              child: Container(
                                padding: const EdgeInsets.all(AppSpacing.sm),
                                decoration: BoxDecoration(
                                  color: AppColors.background.withOpacity(0.35),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.primary.withOpacity(0.25)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Section ${entry.key + 1}',
                                      style: AppTextStyles.body.copyWith(
                                        fontSize: 10,
                                        color: AppColors.accent,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${entry.value['title'] ?? 'Section'}',
                                      style: AppTextStyles.button.copyWith(fontSize: 12),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${entry.value['content'] ?? ''}',
                                      style: AppTextStyles.body.copyWith(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                      maxLines: 6,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<_ModuleFormPayload?> _openModuleEditor({_LibraryModuleItem? initial}) async {
    final titleController = TextEditingController(text: initial?.title ?? '');
    final topicController = TextEditingController(text: initial?.topic ?? '');
    final summaryController = TextEditingController(text: initial?.summary ?? '');

    String selectedDifficulty = _difficultyOptions.contains(initial?.difficulty)
        ? initial!.difficulty
        : 'normal';
    String selectedStatus = _statusOptions.contains(initial?.status) ? initial!.status : 'ready';

    final result = await showDialog<_ModuleFormPayload>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) => AlertDialog(
            backgroundColor: AppColors.card,
            title: Text(
              initial == null ? 'Add Module' : 'Edit Module',
              style: AppTextStyles.button.copyWith(fontSize: 16),
            ),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: topicController,
                      decoration: const InputDecoration(labelText: 'Topic'),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: summaryController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Summary (optional)',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    DropdownButtonFormField<String>(
                      value: selectedDifficulty,
                      items: _difficultyOptions
                          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setLocalState(() => selectedDifficulty = value);
                        }
                      },
                      decoration: const InputDecoration(labelText: 'Difficulty'),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      items: _statusOptions
                          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setLocalState(() => selectedStatus = value);
                        }
                      },
                      decoration: const InputDecoration(labelText: 'Status'),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Cancel', style: AppTextStyles.body.copyWith(color: AppColors.textSecondary)),
              ),
              FilledButton(
                onPressed: () {
                  final title = titleController.text.trim();
                  final topic = topicController.text.trim();
                  if (title.isEmpty || topic.isEmpty) return;
                  Navigator.of(context).pop(
                    _ModuleFormPayload(
                      title: title,
                      topic: topic,
                      summary: summaryController.text.trim(),
                      difficulty: selectedDifficulty,
                      status: selectedStatus,
                    ),
                  );
                },
                child: Text(initial == null ? 'Create' : 'Save', style: AppTextStyles.button.copyWith(fontSize: 12)),
              ),
            ],
          ),
        );
      },
    );

    titleController.dispose();
    topicController.dispose();
    summaryController.dispose();
    return result;
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFB53C2D),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final readyCount = _modules.where((m) => m.status == 'ready').length;
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF37D7A5).withOpacity(0.12),
                  Colors.transparent,
                  AppColors.primary.withOpacity(0.1),
                ],
              ),
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.card.withOpacity(0.95),
                AppColors.background.withOpacity(0.9),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.primary.withOpacity(0.4), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.18),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
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
                      color: AppColors.primary.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.auto_stories_rounded, color: AppColors.accent),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Study Library',
                      style: AppTextStyles.title.copyWith(fontSize: 18),
                    ),
                  ),
                  IconButton(
                    onPressed: _createModule,
                    icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.accent),
                    tooltip: 'Create module',
                  ),
                  IconButton(
                    onPressed: _loadModules,
                    icon: const Icon(Icons.refresh_rounded, color: AppColors.accent),
                    tooltip: 'Refresh library',
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  _statChip(Icons.folder_copy_outlined, '${_modules.length} modules'),
                  _statChip(Icons.fact_check_outlined, '$readyCount ready'),
                  _statChip(
                    Icons.style_outlined,
                    '${_modules.fold<int>(0, (sum, m) => sum + m.flashcards)} cards',
                  ),
                  _statChip(
                    Icons.notes_rounded,
                    '${_modules.fold<int>(0, (sum, m) => sum + m.reviewers)} reviewer sections',
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Text(
          _error!,
          textAlign: TextAlign.center,
          style: AppTextStyles.body.copyWith(color: Colors.redAccent, fontSize: 12),
        ),
      );
    }

    if (_modules.isEmpty) {
      return Center(
        child: Text(
          'No modules yet.\nGenerate Reviewer or Flashcards to fill your library.',
          textAlign: TextAlign.center,
          style: AppTextStyles.body.copyWith(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: _modules.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final module = _modules[index];
        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openModuleDetails(module),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withOpacity(0.16),
                  AppColors.background.withOpacity(0.35),
                ],
              ),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        module.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.button.copyWith(fontSize: 14),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    _pill(module.status.toUpperCase(), AppColors.accent),
                    const SizedBox(width: AppSpacing.xs),
                    _tinyIconButton(
                      icon: Icons.edit_outlined,
                      onTap: () => _editModule(module),
                    ),
                    const SizedBox(width: 6),
                    _tinyIconButton(
                      icon: Icons.delete_outline_rounded,
                      onTap: () => _deleteModule(module),
                      danger: true,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  module.topic,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (module.summary.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    module.summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body.copyWith(
                      fontSize: 11,
                      color: AppColors.textSecondary.withOpacity(0.95),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: 6,
                  children: [
                    _pill('Difficulty: ${module.difficulty}', AppColors.primary),
                    _pill('${module.flashcards} cards', const Color(0xFF3BA6FF)),
                    _pill('${module.reviewers} reviewer', const Color(0xFF8A6DFF)),
                    _pill('Tap to open', const Color(0xFF37D7A5)),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Updated: ${_prettyDate(module.updatedAt)}',
                  style: AppTextStyles.body.copyWith(
                    fontSize: 10,
                    color: AppColors.textSecondary.withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _tinyIconButton({
    required IconData icon,
    required VoidCallback onTap,
    bool danger = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: (danger ? Colors.redAccent : AppColors.primary).withOpacity(0.2),
            border: Border.all(
              color: (danger ? Colors.redAccent : AppColors.primary).withOpacity(0.45),
            ),
          ),
          child: Icon(
            icon,
            size: 13,
            color: danger ? Colors.redAccent : AppColors.accent,
          ),
        ),
      ),
    );
  }

  Widget _statChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.accent),
          const SizedBox(width: 4),
          Text(label, style: AppTextStyles.body.copyWith(fontSize: 10)),
        ],
      ),
    );
  }

  Widget _pill(String text, Color tone) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 3),
      decoration: BoxDecoration(
        color: tone.withOpacity(0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tone.withOpacity(0.35)),
      ),
      child: Text(
        text,
        style: AppTextStyles.body.copyWith(fontSize: 10, color: AppColors.textPrimary),
      ),
    );
  }

  String _prettyDate(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return '-';
    final local = parsed.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.year}-$month-$day $hour:$minute';
  }
}

class _LibraryModuleItem {
  const _LibraryModuleItem({
    required this.id,
    required this.title,
    required this.topic,
    required this.difficulty,
    required this.status,
    required this.updatedAt,
    required this.flashcards,
    required this.reviewers,
    required this.summary,
  });

  final String id;
  final String title;
  final String topic;
  final String difficulty;
  final String status;
  final String updatedAt;
  final int flashcards;
  final int reviewers;
  final String summary;
}

class _ModuleFormPayload {
  const _ModuleFormPayload({
    required this.title,
    required this.topic,
    required this.summary,
    required this.difficulty,
    required this.status,
  });

  final String title;
  final String topic;
  final String summary;
  final String difficulty;
  final String status;
}

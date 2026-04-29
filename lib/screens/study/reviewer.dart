import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/services/study_persistence_service.dart';
import '../../core/services/study_generation_service.dart';
import '../../core/services/xp_service.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/textstyles.dart';
import '../../core/widgets/ui/topnav.dart';
class ReviewerScreen extends StatelessWidget {
  const ReviewerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        AppTopNav(),
        Expanded(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: ReviewerTabPanel(),
          ),
        ),
      ],
    );
  }
}

class ReviewerTabPanel extends StatefulWidget {
  const ReviewerTabPanel({super.key});

  @override
  State<ReviewerTabPanel> createState() => _ReviewerTabPanelState();
}

class _ReviewerTabPanelState extends State<ReviewerTabPanel> {
  final XpService _xpService = const XpService();
  final StudyPersistenceService _studyPersistenceService =
      const StudyPersistenceService();
  final StudyGenerationService _studyGenerationService =
      const StudyGenerationService();

  Uint8List? _pdfBytes;
  String? _pdfName;
  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _modules = [];
  int _activeSectionIndex = 0;

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      withData: true,
    );

    if (result == null || result.files.isEmpty || result.files.single.bytes == null) {
      return;
    }

    setState(() {
      _pdfBytes = result.files.single.bytes;
      _pdfName = result.files.single.name;
      _modules = [];
      _activeSectionIndex = 0;
      _error = null;
    });
  }

  Future<void> _generateReviewer() async {
    if (_pdfBytes == null || _pdfName == null) {
      setState(() => _error = 'Please upload a PDF first.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final modules = await _studyGenerationService.generateReviewer(
        _pdfBytes!,
        _pdfName!,
      );
      await _xpService.addXp(XpService.reviewerXp);
      try {
        await _studyPersistenceService.saveReviewerFromUpload(
          sourceName: _pdfName!,
          modules: modules,
        );
      } catch (_) {
        // Keep generated data usable even if DB migration is not applied yet.
      }
      setState(() {
        _modules = modules;
        _activeSectionIndex = 0;
      });
    } catch (e) {
      setState(() => _error = _friendlyError(e.toString()));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addSection() async {
    final section = await _openSectionEditor();
    if (section == null || !mounted) return;
    setState(() {
      _modules = [..._modules, section];
      _activeSectionIndex = _modules.length - 1;
    });
  }

  Future<void> _editSection(int index) async {
    if (index < 0 || index >= _modules.length) return;
    final updated = await _openSectionEditor(initial: _modules[index]);
    if (updated == null || !mounted) return;
    setState(() {
      final next = List<Map<String, dynamic>>.from(_modules);
      next[index] = updated;
      _modules = next;
    });
  }

  void _deleteSection(int index) {
    if (index < 0 || index >= _modules.length) return;
    setState(() {
      final next = List<Map<String, dynamic>>.from(_modules);
      next.removeAt(index);
      _modules = next;
      if (_activeSectionIndex >= next.length) {
        _activeSectionIndex = next.isEmpty ? 0 : next.length - 1;
      }
    });
  }

  void _goToPrevSection() {
    if (_activeSectionIndex <= 0) return;
    setState(() => _activeSectionIndex--);
  }

  void _goToNextSection() {
    if (_activeSectionIndex >= _modules.length - 1) return;
    setState(() => _activeSectionIndex++);
  }

  Future<Map<String, dynamic>?> _openSectionEditor({
    Map<String, dynamic>? initial,
  }) async {
    final titleController = TextEditingController(
      text: '${initial?['title'] ?? ''}'.trim(),
    );
    final materialController = TextEditingController(
      text: '${initial?['material'] ?? initial?['summary'] ?? ''}'.trim(),
    );
    final quizSeed = initial?['quiz'];
    final quizController = TextEditingController(
      text: quizSeed is List
          ? quizSeed.map((q) => '$q').join('\n')
          : quizSeed is Map
              ? quizSeed.values.map((q) => '$q').join('\n')
              : '',
    );

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          title: Text(
            initial == null ? 'Add Section' : 'Edit Section',
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
                    decoration: const InputDecoration(labelText: 'Section title'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: materialController,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Reviewer content',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: quizController,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Quiz questions (one per line)',
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
              ),
            ),
            FilledButton(
              onPressed: () {
                final title = titleController.text.trim();
                final material = materialController.text.trim();
                final quiz = quizController.text
                    .split('\n')
                    .map((line) => line.trim())
                    .where((line) => line.isNotEmpty)
                    .toList();
                if (title.isEmpty || material.isEmpty) {
                  return;
                }
                Navigator.of(context).pop({
                  'title': title,
                  'material': material,
                  'quiz': quiz,
                });
              },
              child: Text(
                initial == null ? 'Add' : 'Save',
                style: AppTextStyles.button.copyWith(fontSize: 12),
              ),
            ),
          ],
        );
      },
    );

    titleController.dispose();
    materialController.dispose();
    quizController.dispose();
    return result;
  }

  String _friendlyError(String raw) {
    final message = raw.replaceFirst('Exception: ', '').trim();
    if (message.contains('Both generation paths failed')) {
      return 'Generation failed on both n8n and AI fallback. '
          'Please try another PDF or retry in a moment.\n\nDetails:\n$message';
    }
    return message;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.card.withOpacity(0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.35),
          width: 1.2,
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [_header(), const SizedBox(height: AppSpacing.md), ..._content()],
        ),
      ),
    );
  }

  Widget _header() => Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.fact_check_outlined, color: AppColors.accent),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Reviewer',
              style: AppTextStyles.title.copyWith(fontSize: 18),
            ),
          ),
        ],
      );

  List<Widget> _content() => [
        _actionCard(
          title: '1. Upload PDF',
          subtitle: _pdfName == null
              ? 'Choose the document you want to review.'
              : 'Selected: $_pdfName',
          buttonText: 'Choose PDF',
          icon: Icons.upload_file_rounded,
          onTap: _isLoading ? null : _pickPdf,
        ),
        const SizedBox(height: AppSpacing.md),
        _actionCard(
          title: '2. Generate Reviewer',
          subtitle: 'Create section-by-section reviewer notes from your PDF.',
          buttonText: _isLoading ? 'Generating...' : 'Generate Reviewer',
          icon: Icons.auto_awesome_rounded,
          emphasize: true,
          onTap: _isLoading ? null : _generateReviewer,
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            _error!,
            style: AppTextStyles.body.copyWith(
              color: Colors.redAccent,
              fontSize: 12,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        _generatedSection(),
      ];

  Widget _actionCard({
    required String title,
    required String subtitle,
    required String buttonText,
    required IconData icon,
    required VoidCallback? onTap,
    bool emphasize = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: emphasize
            ? AppColors.primary.withOpacity(0.14)
            : AppColors.background.withOpacity(0.3),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: emphasize
              ? AppColors.accent.withOpacity(0.35)
              : AppColors.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.button.copyWith(fontSize: 14)),
          const SizedBox(height: AppSpacing.xs),
          Text(subtitle, style: AppTextStyles.body.copyWith(fontSize: 12)),
          const SizedBox(height: AppSpacing.sm),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Opacity(
              opacity: onTap == null ? 0.6 : 1,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.9),
                      AppColors.accent.withOpacity(0.75),
                    ],
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: AppColors.textPrimary, size: 18),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      buttonText,
                      style: AppTextStyles.button.copyWith(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _generatedSection() {
    Widget section(
      int index,
      String title,
      String summary,
      List<String> points,
    ) =>
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.card.withOpacity(0.78),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Section $index',
                style: AppTextStyles.body.copyWith(
                  fontSize: 11,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(title, style: AppTextStyles.button.copyWith(fontSize: 13)),
              const SizedBox(height: AppSpacing.xs),
              Text(summary, style: AppTextStyles.body.copyWith(fontSize: 12)),
              if (points.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                ...points.map(
                  (p) => Text('- $p', style: AppTextStyles.body.copyWith(fontSize: 12)),
                ),
              ],
            ],
          ),
        );

    final hasData = _modules.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.background.withOpacity(0.34),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Generated Reviewer Sections',
            style: AppTextStyles.button.copyWith(fontSize: 14),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Text(
                  hasData
                      ? '${_modules.length} section(s) generated.'
                      : 'Generated reviewer content appears here.',
                  style: AppTextStyles.body.copyWith(fontSize: 12),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: _addSection,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.primary.withOpacity(0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add_rounded, size: 14, color: AppColors.accent),
                      const SizedBox(width: 4),
                      Text(
                        'Add',
                        style: AppTextStyles.button.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Text(
            'Tip: Use arrows to browse sections.',
            style: AppTextStyles.body.copyWith(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (!hasData)
            section(
              1,
              'No reviewer yet',
              'Upload a PDF and tap Generate Reviewer to get modules.',
              const [],
            )
          else ...[
            Builder(
              builder: (context) {
                final index = _activeSectionIndex.clamp(0, _modules.length - 1);
                final item = _modules[index];
                final title = '${item['title'] ?? 'Module ${index + 1}'}';
                final material = '${item['material'] ?? item['summary'] ?? ''}';
                final quiz = item['quiz'];
                final points = quiz is List
                    ? quiz.map((q) => '$q').toList()
                    : quiz is Map
                        ? quiz.values.map((q) => '$q').toList()
                        : <String>[];
                return Stack(
                  children: [
                    section(index + 1, title, material, points),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Row(
                        children: [
                          _tinyActionButton(
                            icon: Icons.edit_outlined,
                            onTap: () => _editSection(index),
                          ),
                          const SizedBox(width: 6),
                          _tinyActionButton(
                            icon: Icons.delete_outline_rounded,
                            onTap: () => _deleteSection(index),
                            danger: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),
            _buildArrowRow(),
          ],
        ],
      ),
    );
  }

  Widget _buildArrowRow() {
    final canGoBack = _activeSectionIndex > 0;
    final canGoForward = _activeSectionIndex < _modules.length - 1;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _navArrowButton(
          icon: Icons.arrow_back_ios_new_rounded,
          enabled: canGoBack,
          onTap: canGoBack ? _goToPrevSection : null,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Text(
            '${_activeSectionIndex + 1} / ${_modules.length}',
            style: AppTextStyles.button.copyWith(fontSize: 13),
          ),
        ),
        _navArrowButton(
          icon: Icons.arrow_forward_ios_rounded,
          enabled: canGoForward,
          onTap: canGoForward ? _goToNextSection : null,
        ),
      ],
    );
  }

  Widget _navArrowButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Opacity(
          opacity: enabled ? 1 : 0.35,
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.85),
                  AppColors.accent.withOpacity(0.7),
                ],
              ),
              border: Border.all(
                color: AppColors.accent.withOpacity(0.35),
              ),
            ),
            child: Icon(icon, size: 18, color: AppColors.textPrimary),
          ),
        ),
      ),
    );
  }

  Widget _tinyActionButton({
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
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: (danger ? Colors.redAccent : AppColors.primary).withOpacity(0.2),
            border: Border.all(
              color: (danger ? Colors.redAccent : AppColors.primary).withOpacity(0.45),
            ),
          ),
          child: Icon(
            icon,
            size: 14,
            color: danger ? Colors.redAccent : AppColors.accent,
          ),
        ),
      ),
    );
  }
}

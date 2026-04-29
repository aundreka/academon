import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/services/n8n_service.dart';
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
  Uint8List? _pdfBytes;
  String? _pdfName;
  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _modules = [];

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
      final modules = await N8nService.uploadSyllabus(_pdfBytes!, _pdfName!);
      setState(() => _modules = modules);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
          Text(
            hasData
                ? '${_modules.length} section(s) generated.'
                : 'Generated reviewer content appears here.',
            style: AppTextStyles.body.copyWith(fontSize: 12),
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
          else
            ...List.generate(_modules.length, (index) {
              final item = _modules[index];
              final title = '${item['title'] ?? 'Module ${index + 1}'}';
              final material = '${item['material'] ?? item['summary'] ?? ''}';
              final quiz = item['quiz'];
              final points = quiz is List
                  ? quiz.map((q) => '$q').toList()
                  : quiz is Map
                      ? quiz.values.map((q) => '$q').toList()
                      : <String>[];

              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == _modules.length - 1 ? 0 : AppSpacing.sm,
                ),
                child: section(index + 1, title, material, points),
              );
            }),
        ],
      ),
    );
  }
}

import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/services/n8n_service.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/textstyles.dart';
import '../../core/widgets/ui/topnav.dart';
class FlashcardsScreen extends StatelessWidget {
  const FlashcardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        AppTopNav(),
        Expanded(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: FlashcardsTabPanel(),
          ),
        ),
      ],
    );
  }
}

class FlashcardsTabPanel extends StatefulWidget {
  const FlashcardsTabPanel({super.key});

  @override
  State<FlashcardsTabPanel> createState() => _FlashcardsTabPanelState();
}

class _FlashcardsTabPanelState extends State<FlashcardsTabPanel> {
  Uint8List? _pdfBytes;
  String? _pdfName;
  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _flashcards = [];

  int _activeIndex = 0;
  bool _showAnswer = false;

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
      _flashcards = [];
      _activeIndex = 0;
      _showAnswer = false;
      _error = null;
    });
  }

  Future<void> _generateFlashcards() async {
    if (_pdfBytes == null || _pdfName == null) {
      setState(() => _error = 'Please upload a PDF first.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final cards = await N8nService.generateFlashcards(_pdfBytes!);
      setState(() {
        _flashcards = cards;
        _activeIndex = 0;
        _showAnswer = false;
      });
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
          children: [
            _header(),
            const SizedBox(height: AppSpacing.md),
            _actionCard(
              title: '1. Upload PDF',
              subtitle: _pdfName == null
                  ? 'Choose your source file for flashcard generation.'
                  : 'Selected: $_pdfName',
              buttonText: 'Choose PDF',
              icon: Icons.upload_file_rounded,
              onTap: _isLoading ? null : _pickPdf,
            ),
            const SizedBox(height: AppSpacing.md),
            _actionCard(
              title: '2. Generate Flashcards',
              subtitle: 'Create a study deck from the uploaded document.',
              buttonText: _isLoading ? 'Generating...' : 'Generate Flashcards',
              icon: Icons.auto_awesome_rounded,
              emphasize: true,
              onTap: _isLoading ? null : _generateFlashcards,
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
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.16),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.style_rounded, color: AppColors.accent),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            'Flashcards',
            style: AppTextStyles.title.copyWith(fontSize: 18),
          ),
        ),
      ],
    );
  }

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

  void _goToPrevCard() {
    if (_activeIndex <= 0) return;
    setState(() {
      _activeIndex--;
      _showAnswer = false;
    });
  }

  void _goToNextCard() {
    if (_activeIndex >= _flashcards.length - 1) return;
    setState(() {
      _activeIndex++;
      _showAnswer = false;
    });
  }

  Widget _generatedSection() {
    Widget placeholderCard(String title, String hint) => Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 160),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.card.withOpacity(0.78),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: AppTextStyles.button.copyWith(fontSize: 13),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                hint,
                style: AppTextStyles.body.copyWith(fontSize: 12),
              ),
            ],
          ),
        );

    final hasData = _flashcards.isNotEmpty;

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
            'Generated Flashcards',
            style: AppTextStyles.button.copyWith(fontSize: 14),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            hasData
                ? '${_flashcards.length} card(s) generated.'
                : 'Generated cards will appear here.',
            style: AppTextStyles.body.copyWith(fontSize: 12),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (!hasData)
            placeholderCard(
              'No flashcards yet',
              'Upload a PDF and tap Generate Flashcards to get results.',
            )
          else ...[
            _buildFlipCard(
              question:
                  '${_flashcards[_activeIndex]['front'] ?? _flashcards[_activeIndex]['question'] ?? 'Front'}',
              answer:
                  '${_flashcards[_activeIndex]['back'] ?? _flashcards[_activeIndex]['answer'] ?? 'Back'}',
            ),
            const SizedBox(height: AppSpacing.md),
            _buildArrowRow(),
          ],
        ],
      ),
    );
  }

  Widget _buildFlipCard({required String question, required String answer}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _showAnswer = !_showAnswer),
        borderRadius: BorderRadius.circular(14),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (Widget child, Animation<double> animation) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutCubic,
            );
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.06),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
          child: Container(
            key: ValueKey<bool>(_showAnswer),
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 200),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.card.withOpacity(0.78),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _showAnswer ? 'ANSWER' : 'QUESTION',
                      style: AppTextStyles.body.copyWith(
                        fontSize: 10,
                        letterSpacing: 0.8,
                        color: AppColors.accent,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      _showAnswer ? answer : question,
                      style: _showAnswer
                          ? AppTextStyles.body.copyWith(fontSize: 13)
                          : AppTextStyles.button.copyWith(fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Tap to flip',
                  style: AppTextStyles.body.copyWith(
                    fontSize: 11,
                    color: AppColors.textSecondary.withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildArrowRow() {
    final canGoBack = _activeIndex > 0;
    final canGoForward = _activeIndex < _flashcards.length - 1;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _navArrowButton(
          icon: Icons.arrow_back_ios_new_rounded,
          enabled: canGoBack,
          onTap: canGoBack ? _goToPrevCard : null,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Text(
            '${_activeIndex + 1} / ${_flashcards.length}',
            style: AppTextStyles.button.copyWith(fontSize: 13),
          ),
        ),
        _navArrowButton(
          icon: Icons.arrow_forward_ios_rounded,
          enabled: canGoForward,
          onTap: canGoForward ? _goToNextCard : null,
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
}

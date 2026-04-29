import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../theme/spacing.dart';
import '../../theme/textstyles.dart';

class ArenaQuestionWidget extends StatefulWidget {
  final String moduleId;
  final SupabaseClient? supabase;
  final ValueChanged<ArenaQuestionResult>? onCompleted;

  const ArenaQuestionWidget({
    super.key,
    required this.moduleId,
    this.supabase,
    this.onCompleted,
  });

  @override
  State<ArenaQuestionWidget> createState() => _ArenaQuestionWidgetState();
}

class _ArenaQuestionWidgetState extends State<ArenaQuestionWidget> {
  late final SupabaseClient _supabase;

  bool _loading = true;
  bool _submitting = false;
  String? _errorMessage;
  String? _attemptId;
  String? _selectedChoice;
  String? _pressedChoice;
  int _currentIndex = 0;
  int _score = 0;
  DateTime? _questionShownAt;
  List<_ArenaStudyQuestion> _questions = const [];

  @override
  void initState() {
    super.initState();
    _supabase = widget.supabase ?? Supabase.instance.client;
    unawaited(_loadQuestions());
  }

  Future<void> _loadQuestions() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('You need to be logged in before starting a study battle.');
      }

      final rows = await _supabase
          .from('questions')
          .select(
            'id, question_text, choices, correct_answer, explanation, difficulty, order_index',
          )
          .eq('module_id', widget.moduleId)
          .eq('question_type', 'mcq')
          .order('order_index', ascending: true)
          .order('created_at', ascending: true);

      final questions = rows
          .map<_ArenaStudyQuestion?>(
            (dynamic row) => _ArenaStudyQuestion.tryParse(
              row as Map<String, dynamic>,
            ),
          )
          .whereType<_ArenaStudyQuestion>()
          .toList();

      if (questions.isEmpty) {
        throw Exception('No multiple choice questions were found for this module yet.');
      }

      final attempt = await _supabase
          .from('module_attempts')
          .insert({
            'user_id': user.id,
            'module_id': widget.moduleId,
            'total_questions': questions.length,
            'score': 0,
            'accuracy': 0,
          })
          .select('id')
          .single();

      if (!mounted) {
        return;
      }

      setState(() {
        _questions = questions;
        _attemptId = attempt['id'] as String;
        _currentIndex = 0;
        _score = 0;
        _selectedChoice = null;
        _pressedChoice = null;
        _questionShownAt = DateTime.now();
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _handleChoiceTap(String choice) async {
    if (_submitting || _selectedChoice != null || _attemptId == null) {
      return;
    }

    final question = _questions[_currentIndex];
    final isCorrect = choice.trim().toLowerCase() ==
        question.correctAnswer.trim().toLowerCase();
    final responseTimeMs = _questionShownAt == null
        ? null
        : DateTime.now().difference(_questionShownAt!).inMilliseconds;

    setState(() {
      _selectedChoice = choice;
      _submitting = true;
      if (isCorrect) {
        _score += 1;
      }
    });

    try {
      await _supabase.from('question_attempts').insert({
        'attempt_id': _attemptId,
        'question_id': question.id,
        'selected_answer': choice,
        'is_correct': isCorrect,
        'response_time_ms': responseTimeMs,
        'damage_dealt': isCorrect ? 10 : 0,
      });

      await Future<void>.delayed(const Duration(milliseconds: 550));

      if (!mounted) {
        return;
      }

      if (_currentIndex >= _questions.length - 1) {
        await _finishAttempt();
        return;
      }

      setState(() {
        _currentIndex += 1;
        _selectedChoice = null;
        _pressedChoice = null;
        _submitting = false;
        _questionShownAt = DateTime.now();
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _submitting = false;
        _errorMessage = 'Failed to save your answer. ${error.toString().replaceFirst('Exception: ', '')}';
      });
    }
  }

  Future<void> _finishAttempt() async {
    final attemptId = _attemptId;
    if (attemptId == null) {
      return;
    }

    final totalQuestions = _questions.length;
    final accuracy = totalQuestions == 0 ? 0.0 : _score / totalQuestions;

    await _supabase.from('module_attempts').update({
      'score': _score,
      'total_questions': totalQuestions,
      'accuracy': accuracy,
      'passed': accuracy >= 0.6,
      'completed_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', attemptId);

    if (!mounted) {
      return;
    }

    final result = ArenaQuestionResult(
      attemptId: attemptId,
      moduleId: widget.moduleId,
      score: _score,
      totalQuestions: totalQuestions,
      accuracy: accuracy,
    );

    setState(() {
      _submitting = false;
    });

    widget.onCompleted?.call(result);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return _BattleShell(
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: CircularProgressIndicator(color: Color(0xFFFFD56A)),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return _BattleShell(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFFF9F68),
                size: 34,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(
                  color: const Color(0xFFFFE1D1),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: _loadQuestions,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF214A8E),
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  'Retry',
                  style: AppTextStyles.button.copyWith(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final question = _questions[_currentIndex];
    final progress = (_currentIndex + 1) / _questions.length;

    return _BattleShell(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF23345F),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: const Color(0xFF76D8FF).withOpacity(0.38),
                    ),
                  ),
                  child: Text(
                    'QUESTION ${_currentIndex + 1}',
                    style: AppTextStyles.body.copyWith(
                      color: const Color(0xFF8EEBFF),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${_currentIndex + 1}/${_questions.length}',
                  style: AppTextStyles.body.copyWith(
                    color: const Color(0xFFFFEAAE),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 9,
                backgroundColor: Colors.white.withOpacity(0.10),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFFFFD56A),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: const Color(0xFF0E1630),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF7EDFFF).withOpacity(0.20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enemy Challenge',
                    style: AppTextStyles.button.copyWith(
                      color: const Color(0xFFFFD56A),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    question.questionText,
                    style: AppTextStyles.body.copyWith(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            for (final choice in question.choices) ...[
              _ChoiceTile(
                label: choice,
                isSelected: _selectedChoice == choice,
                isCorrect: _selectedChoice != null &&
                    choice.trim().toLowerCase() ==
                        question.correctAnswer.trim().toLowerCase(),
                isWrongSelection: _selectedChoice == choice &&
                    choice.trim().toLowerCase() !=
                        question.correctAnswer.trim().toLowerCase(),
                isPressed: _pressedChoice == choice,
                enabled: !_submitting && _selectedChoice == null,
                onTap: () => _handleChoiceTap(choice),
                onPressedStateChanged: (pressed) {
                  if (!mounted || _selectedChoice != null || _submitting) {
                    return;
                  }
                  setState(() {
                    _pressedChoice = pressed ? choice : null;
                  });
                },
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            if (_selectedChoice != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                question.explanation?.trim().isNotEmpty == true
                    ? question.explanation!.trim()
                    : (_selectedChoice!.trim().toLowerCase() ==
                            question.correctAnswer.trim().toLowerCase()
                        ? 'Critical hit. That answer is correct.'
                        : 'The correct answer is ${question.correctAnswer}.'),
                style: AppTextStyles.body.copyWith(
                  color: const Color(0xFFD7F5FF),
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isCorrect;
  final bool isWrongSelection;
  final bool isPressed;
  final bool enabled;
  final VoidCallback onTap;
  final ValueChanged<bool> onPressedStateChanged;

  const _ChoiceTile({
    required this.label,
    required this.isSelected,
    required this.isCorrect,
    required this.isWrongSelection,
    required this.isPressed,
    required this.enabled,
    required this.onTap,
    required this.onPressedStateChanged,
  });

  @override
  Widget build(BuildContext context) {
    final Color borderColor;
    final List<Color> gradientColors;

    if (isCorrect) {
      borderColor = const Color(0xFF7CFFB2);
      gradientColors = const [
        Color(0xFF1B5B4A),
        Color(0xFF24926A),
      ];
    } else if (isWrongSelection) {
      borderColor = const Color(0xFFFF8B87);
      gradientColors = const [
        Color(0xFF60273B),
        Color(0xFF8F3745),
      ];
    } else {
      borderColor = const Color(0xFF5F78B8);
      gradientColors = const [
        Color(0xFF182548),
        Color(0xFF253868),
      ];
    }

    final scale = isPressed ? 0.97 : 1.0;
    final glowColor = isSelected
        ? borderColor.withOpacity(0.28)
        : Colors.black.withOpacity(0.18);

    return AnimatedScale(
      scale: scale,
      duration: const Duration(milliseconds: 120),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          onTapDown: enabled ? (_) => onPressedStateChanged(true) : null,
          onTapCancel: enabled ? () => onPressedStateChanged(false) : null,
          onTapUp: enabled ? (_) => onPressedStateChanged(false) : null,
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
              ),
              border: Border.all(color: borderColor, width: 1.4),
              boxShadow: [
                BoxShadow(
                  color: glowColor,
                  blurRadius: isSelected ? 18 : 12,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.10),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.16),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    isCorrect
                        ? Icons.check_rounded
                        : isWrongSelection
                            ? Icons.close_rounded
                            : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    label,
                    style: AppTextStyles.button.copyWith(
                      fontSize: 14,
                      color: Colors.white,
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
}

class _BattleShell extends StatelessWidget {
  final Widget child;

  const _BattleShell({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0B1020),
            Color(0xFF142347),
            Color(0xFF1F3564),
          ],
        ),
        border: Border.all(
          color: const Color(0xFF89DFFF).withOpacity(0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF07101F).withOpacity(0.42),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -18,
            right: -8,
            child: Container(
              width: 110,
              height: 110,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Color(0x33FFD56A),
                    Color(0x00FFD56A),
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.04),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _ArenaStudyQuestion {
  final String id;
  final String questionText;
  final List<String> choices;
  final String correctAnswer;
  final String? explanation;

  const _ArenaStudyQuestion({
    required this.id,
    required this.questionText,
    required this.choices,
    required this.correctAnswer,
    required this.explanation,
  });

  static _ArenaStudyQuestion? tryParse(Map<String, dynamic> json) {
    final id = json['id'] as String?;
    final questionText = (json['question_text'] as String?)?.trim();
    final correctAnswer = (json['correct_answer'] as String?)?.trim();
    final choices = _parseChoices(json['choices']);

    if (id == null ||
        questionText == null ||
        questionText.isEmpty ||
        correctAnswer == null ||
        correctAnswer.isEmpty ||
        choices.length < 2) {
      return null;
    }

    return _ArenaStudyQuestion(
      id: id,
      questionText: questionText,
      choices: choices,
      correctAnswer: correctAnswer,
      explanation: (json['explanation'] as String?)?.trim(),
    );
  }

  static List<String> _parseChoices(dynamic rawChoices) {
    if (rawChoices is List) {
      return rawChoices
          .map((dynamic value) => value.toString().trim())
          .where((String value) => value.isNotEmpty)
          .toList();
    }

    if (rawChoices is Map) {
      return rawChoices.values
          .map((dynamic value) => value.toString().trim())
          .where((String value) => value.isNotEmpty)
          .toList();
    }

    return const [];
  }
}

class ArenaQuestionResult {
  final String attemptId;
  final String moduleId;
  final int score;
  final int totalQuestions;
  final double accuracy;

  const ArenaQuestionResult({
    required this.attemptId,
    required this.moduleId,
    required this.score,
    required this.totalQuestions,
    required this.accuracy,
  });
}

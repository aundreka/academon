// question.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ArenaQuestionWidget extends StatefulWidget {
  final String moduleId;
  final SupabaseClient? supabase;
  final ValueChanged<ArenaQuestionResult>? onCompleted;
  final ArenaQuestionTurnDecision Function(ArenaAnswerResolution)?
  onAnswerResolved;

  const ArenaQuestionWidget({
    super.key,
    required this.moduleId,
    this.supabase,
    this.onCompleted,
    this.onAnswerResolved,
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
        throw Exception(
          'You need to be logged in before starting a study battle.',
        );
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
            (dynamic row) =>
                _ArenaStudyQuestion.tryParse(row as Map<String, dynamic>),
          )
          .whereType<_ArenaStudyQuestion>()
          .toList();

      if (questions.isEmpty) {
        throw Exception(
          'No multiple choice questions were found for this module yet.',
        );
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

      if (!mounted) return;

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
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _handleChoiceTap(String choice) async {
    if (_submitting || _selectedChoice != null || _attemptId == null) return;

    final question = _questions[_currentIndex];
    final isCorrect =
        choice.trim().toLowerCase() ==
        question.correctAnswer.trim().toLowerCase();
    final responseTimeMs = _questionShownAt == null
        ? null
        : DateTime.now().difference(_questionShownAt!).inMilliseconds;

    setState(() {
      _selectedChoice = choice;
      _submitting = true;
      if (isCorrect) _score += 1;
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

      await Future<void>.delayed(const Duration(milliseconds: 800));

      if (!mounted) return;

      final resolution = ArenaAnswerResolution(
        moduleId: widget.moduleId,
        questionId: question.id,
        questionIndex: _currentIndex,
        totalQuestions: _questions.length,
        selectedChoice: choice,
        correctAnswer: question.correctAnswer,
        explanation: question.explanation,
        isCorrect: isCorrect,
      );

      final decision =
          widget.onAnswerResolved?.call(resolution) ??
          ArenaQuestionTurnDecision.continueQuiz;

      if (decision == ArenaQuestionTurnDecision.finishAttempt) {
        await _finishAttempt();
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
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _errorMessage =
            'Failed to save your answer. ${error.toString().replaceFirst('Exception: ', '')}';
      });
    }
  }

  Future<void> _finishAttempt() async {
    final attemptId = _attemptId;
    if (attemptId == null) return;

    final totalQuestions = _questions.length;
    final accuracy = totalQuestions == 0 ? 0.0 : _score / totalQuestions;

    await _supabase
        .from('module_attempts')
        .update({
          'score': _score,
          'total_questions': totalQuestions,
          'accuracy': accuracy,
          'passed': accuracy >= 0.6,
          'completed_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', attemptId);

    if (!mounted) return;

    final result = ArenaQuestionResult(
      attemptId: attemptId,
      moduleId: widget.moduleId,
      score: _score,
      totalQuestions: totalQuestions,
      accuracy: accuracy,
    );

    setState(() => _submitting = false);
    widget.onCompleted?.call(result);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const _PokeDialogShell(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(
              color: Color(0xFF3860D8),
              strokeWidth: 3,
            ),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return _PokeDialogShell(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _errorMessage!,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  color: Color(0xFF2C2C2C),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _loadQuestions,
                child: const _PokeActionButton(
                  label: 'RETRY',
                  topColor: Color(0xFFEC6565),
                  bottomColor: Color(0xFFA83030),
                  textColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final question = _questions[_currentIndex];

    // Determine explanation text shown after answering
    String? explanationText;
    if (_selectedChoice != null) {
      final isCorrect =
          _selectedChoice!.trim().toLowerCase() ==
          question.correctAnswer.trim().toLowerCase();
      if (question.explanation?.trim().isNotEmpty == true) {
        explanationText = question.explanation!.trim();
      } else {
        explanationText = isCorrect
            ? 'That\'s right!'
            : 'The answer was ${question.correctAnswer}.';
      }
    }

    return _PokeBattleBox(
      questionText: _selectedChoice != null
          ? (explanationText ?? '')
          : question.questionText,
      questionIndex: _currentIndex,
      totalQuestions: _questions.length,
      choices: question.choices,
      selectedChoice: _selectedChoice,
      pressedChoice: _pressedChoice,
      correctAnswer: question.correctAnswer,
      submitting: _submitting,
      onChoiceTap: _handleChoiceTap,
      onPressedStateChanged: (choice, pressed) {
        if (!mounted || _selectedChoice != null || _submitting) return;
        setState(() => _pressedChoice = pressed ? choice : null);
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Pokemon-style Battle Box — the main layout
// ---------------------------------------------------------------------------

class _PokeBattleBox extends StatelessWidget {
  final String questionText;
  final int questionIndex;
  final int totalQuestions;
  final List<String> choices;
  final String? selectedChoice;
  final String? pressedChoice;
  final String correctAnswer;
  final bool submitting;
  final ValueChanged<String> onChoiceTap;
  final void Function(String choice, bool pressed) onPressedStateChanged;

  const _PokeBattleBox({
    required this.questionText,
    required this.questionIndex,
    required this.totalQuestions,
    required this.choices,
    required this.selectedChoice,
    required this.pressedChoice,
    required this.correctAnswer,
    required this.submitting,
    required this.onChoiceTap,
    required this.onPressedStateChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Pad choices to exactly 4 slots for the 2x2 grid
    final paddedChoices = List<String?>.from(choices);
    while (paddedChoices.length < 4) {
      paddedChoices.add(null);
    }

    // Define the 4 button colors — no green or red (reserved for correct/wrong feedback)
    const buttonDefs = [
      _PokeButtonDef(
        topColor: Color(0xFF5AABEC),
        bottomColor: Color(0xFF2E5FA8),
        textColor: Colors.white,
      ),
      _PokeButtonDef(
        topColor: Color(0xFFD4903A),
        bottomColor: Color(0xFF8C5A18),
        textColor: Colors.white,
      ),
      _PokeButtonDef(
        topColor: Color(0xFF9B6FD4),
        bottomColor: Color(0xFF5E3A9A),
        textColor: Colors.white,
      ),
      _PokeButtonDef(
        topColor: Color(0xFF3ABCB8),
        bottomColor: Color(0xFF1E7A77),
        textColor: Colors.white,
      ),
    ];

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left: Question dialog box (larger)
          Expanded(
            flex: 5,
            child: _PokeDialogShell(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Progress indicator: small dots or text
                    Text(
                      'Q${questionIndex + 1}/$totalQuestions',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        color: Color(0xFF777777),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      questionText,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 14,
                        color: Color(0xFF1A1A1A),
                        fontWeight: FontWeight.bold,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 4),

          // Right: 2×2 button grid
          Expanded(
            flex: 4,
            child: _PokeButtonGrid(
              choices: paddedChoices,
              buttonDefs: buttonDefs,
              selectedChoice: selectedChoice,
              pressedChoice: pressedChoice,
              correctAnswer: correctAnswer,
              submitting: submitting,
              onChoiceTap: onChoiceTap,
              onPressedStateChanged: onPressedStateChanged,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 2×2 button grid
// ---------------------------------------------------------------------------

class _PokeButtonGrid extends StatelessWidget {
  final List<String?> choices;
  final List<_PokeButtonDef> buttonDefs;
  final String? selectedChoice;
  final String? pressedChoice;
  final String correctAnswer;
  final bool submitting;
  final ValueChanged<String> onChoiceTap;
  final void Function(String choice, bool pressed) onPressedStateChanged;

  const _PokeButtonGrid({
    required this.choices,
    required this.buttonDefs,
    required this.selectedChoice,
    required this.pressedChoice,
    required this.correctAnswer,
    required this.submitting,
    required this.onChoiceTap,
    required this.onPressedStateChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        // Outer border matches the dialog box style
        color: const Color(0xFFF0F0F0),
        border: Border.all(color: const Color(0xFF2C2C2C), width: 2.5),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(5),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _buildButton(0)),
                const SizedBox(width: 4),
                Expanded(child: _buildButton(1)),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _buildButton(2)),
                const SizedBox(width: 4),
                Expanded(child: _buildButton(3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(int index) {
    if (index >= choices.length || choices[index] == null) {
      return const SizedBox.shrink();
    }

    final choice = choices[index]!;
    final def = buttonDefs[index % buttonDefs.length];
    final answered = selectedChoice != null;
    final isSelected = selectedChoice == choice;
    final isThisCorrect =
        choice.trim().toLowerCase() == correctAnswer.trim().toLowerCase();
    final isWrongSelection = isSelected && !isThisCorrect;
    final isPressed = pressedChoice == choice;
    final enabled = !submitting && !answered;

    Color resolvedTop;
    Color resolvedBottom;

    if (!answered) {
      resolvedTop = def.topColor;
      resolvedBottom = def.bottomColor;
    } else if (isWrongSelection) {
      resolvedTop = const Color(0xFFEC6565);
      resolvedBottom = const Color(0xFFA83030);
    } else if (isThisCorrect) {
      resolvedTop = const Color(0xFF5ABF6A);
      resolvedBottom = const Color(0xFF2E7A3C);
    } else {
      resolvedTop = const Color(0xFF9E9E9E);
      resolvedBottom = const Color(0xFF616161);
    }

    return _PokeActionButton(
      label: choice,
      topColor: resolvedTop,
      bottomColor: resolvedBottom,
      textColor: Colors.white,
      isPressed: isPressed,
      isSelected: isSelected,
      enabled: enabled,
      onTap: enabled ? () => onChoiceTap(choice) : null,
      onPressedChanged: enabled
          ? (pressed) => onPressedStateChanged(choice, pressed)
          : null,
    );
  }
}

// ---------------------------------------------------------------------------
// Individual Pokémon-style action button
// ---------------------------------------------------------------------------

class _PokeButtonDef {
  final Color topColor;
  final Color bottomColor;
  final Color textColor;

  const _PokeButtonDef({
    required this.topColor,
    required this.bottomColor,
    required this.textColor,
  });
}

class _PokeActionButton extends StatelessWidget {
  final String label;
  final Color topColor;
  final Color bottomColor;
  final Color textColor;
  final bool isPressed;
  final bool isSelected;
  final bool enabled;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onPressedChanged;

  const _PokeActionButton({
    required this.label,
    required this.topColor,
    required this.bottomColor,
    required this.textColor,
    this.isPressed = false,
    this.isSelected = false,
    this.enabled = true,
    this.onTap,
    this.onPressedChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onTapDown: (_) => onPressedChanged?.call(true),
      onTapUp: (_) => onPressedChanged?.call(false),
      onTapCancel: () => onPressedChanged?.call(false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOut,
        child: SizedBox.expand(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Shadow/bottom layer (darker color — gives 3D effect)
              Container(
                decoration: BoxDecoration(
                  color: bottomColor,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: Colors.black.withOpacity(0.35),
                    width: 1.5,
                  ),
                ),
              ),
              // Top face (shifts down when pressed)
              AnimatedPadding(
                duration: const Duration(milliseconds: 80),
                padding: EdgeInsets.only(bottom: isPressed ? 0 : 3),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: isPressed ? 9 : 7,
                  ),
                  decoration: BoxDecoration(
                    color: topColor,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: Colors.black.withOpacity(0.30),
                      width: 1.5,
                    ),
                    // Subtle highlight on top-left edge
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.25),
                        topColor,
                        bottomColor.withOpacity(0.6),
                      ],
                      stops: const [0.0, 0.4, 1.0],
                    ),
                  ),
                  child: Center(
                    child: SizedBox(
                      height: 32,
                      child: Center(
                        child: Text(
                          label.toUpperCase(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            height: 1.15,
                            fontWeight: FontWeight.w900,
                            color: textColor,
                            letterSpacing: 0.3,
                            shadows: const [
                              Shadow(
                                color: Colors.black45,
                                offset: Offset(0, 1),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pokémon-style white dialog shell with thick rounded border
// ---------------------------------------------------------------------------

class _PokeDialogShell extends StatelessWidget {
  final Widget child;

  const _PokeDialogShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        // Crisp white background like the GBA dialog
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(10),
        // Two-tone border: outer dark, inner light — classic Pokémon panel look
        border: Border.all(color: const Color(0xFF2C2C2C), width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 0,
            offset: const Offset(3, 3),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: const Color(0xFFAAAAAA), width: 1.5),
        ),
        child: child,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Data models & enums (unchanged)
// ---------------------------------------------------------------------------

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

class ArenaAnswerResolution {
  final String moduleId;
  final String questionId;
  final int questionIndex;
  final int totalQuestions;
  final String selectedChoice;
  final String correctAnswer;
  final String? explanation;
  final bool isCorrect;

  const ArenaAnswerResolution({
    required this.moduleId,
    required this.questionId,
    required this.questionIndex,
    required this.totalQuestions,
    required this.selectedChoice,
    required this.correctAnswer,
    required this.explanation,
    required this.isCorrect,
  });
}

enum ArenaQuestionTurnDecision { continueQuiz, finishAttempt }

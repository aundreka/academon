import '../models/study_topic.dart';

class FallbackQuestionTemplate {
  final String lessonTitle;
  final String questionTemplate;
  final String descriptionTemplate;
  final List<String> choiceTemplates;
  final int correctChoiceIndex;
  final String explanationTemplate;

  const FallbackQuestionTemplate({
    required this.lessonTitle,
    required this.questionTemplate,
    required this.descriptionTemplate,
    required this.choiceTemplates,
    required this.correctChoiceIndex,
    required this.explanationTemplate,
  });
}

class FallbackModuleQuestion {
  final String questionText;
  final List<String> choices;
  final String correctAnswer;
  final String explanation;
  final String difficulty;

  const FallbackModuleQuestion({
    required this.questionText,
    required this.choices,
    required this.correctAnswer,
    required this.explanation,
    required this.difficulty,
  });

  Map<String, dynamic> toInsertMap({
    required String moduleId,
    required int orderIndex,
  }) {
    return {
      'module_id': moduleId,
      'question_text': questionText,
      'question_type': 'mcq',
      'choices': choices,
      'correct_answer': correctAnswer,
      'explanation': explanation,
      'difficulty': difficulty,
      'order_index': orderIndex,
    };
  }
}

const List<FallbackQuestionTemplate> fallbackQuestionTemplates = [
  FallbackQuestionTemplate(
    lessonTitle: 'Overview',
    questionTemplate: 'What is the main purpose of {moduleName}?',
    descriptionTemplate:
        'Start by defining {moduleName}, identifying its scope, and writing a short explanation in your own words.',
    choiceTemplates: [
      'To understand the central ideas of {moduleName}',
      'To memorize unrelated trivia only',
      'To avoid practice and examples',
      'To replace all other subjects entirely',
    ],
    correctChoiceIndex: 0,
    explanationTemplate:
        '{moduleName} begins with understanding its central purpose and the ideas it covers.',
  ),
  FallbackQuestionTemplate(
    lessonTitle: 'Core Terms',
    questionTemplate: 'Which core terms should every learner know in {moduleName}?',
    descriptionTemplate:
        'List the key vocabulary used in {moduleName} and practice matching each term to its meaning.',
    choiceTemplates: [
      'The main vocabulary and definitions used in {moduleName}',
      'Only random facts with no connection to the module',
      'Names from completely different subjects',
      'Terms that are never used when studying the topic',
    ],
    correctChoiceIndex: 0,
    explanationTemplate:
        'A strong start in {moduleName} comes from recognizing and defining its key terms.',
  ),
  FallbackQuestionTemplate(
    lessonTitle: 'Key Ideas',
    questionTemplate: 'What are the most important ideas behind {moduleName}?',
    descriptionTemplate:
        'Break {moduleName} into a few essential concepts and connect how those ideas work together.',
    choiceTemplates: [
      'The essential concepts and how they connect',
      'Only one detail without context',
      'Unrelated opinions about a different topic',
      'A list with no meaning or explanation',
    ],
    correctChoiceIndex: 0,
    explanationTemplate:
        '{moduleName} should be understood through its essential concepts and their relationships.',
  ),
  FallbackQuestionTemplate(
    lessonTitle: 'Examples',
    questionTemplate: 'How can {moduleName} be applied in a simple example?',
    descriptionTemplate:
        'Work through at least one concrete example that shows how {moduleName} appears in practice.',
    choiceTemplates: [
      'By solving or explaining a simple example related to {moduleName}',
      'By ignoring examples and skipping application',
      'By replacing the lesson with an unrelated story',
      'By avoiding any step-by-step reasoning',
    ],
    correctChoiceIndex: 0,
    explanationTemplate:
        'Using an example helps turn {moduleName} from an abstract idea into something practical.',
  ),
  FallbackQuestionTemplate(
    lessonTitle: 'Self-Check',
    questionTemplate: 'How would you explain {moduleName} to someone else?',
    descriptionTemplate:
        'Review the big ideas from {moduleName} and answer short recall questions without looking at your notes.',
    choiceTemplates: [
      'By summarizing the topic clearly and checking recall',
      'By repeating words without understanding them',
      'By avoiding any review of the main ideas',
      'By changing the subject completely',
    ],
    correctChoiceIndex: 0,
    explanationTemplate:
        'Teaching or summarizing {moduleName} is a strong way to check whether you truly understand it.',
  ),
];

List<String> fallbackQuestionsForModule(String moduleName) {
  return fallbackQuestionTemplates
      .map((template) => template.questionTemplate.replaceAll('{moduleName}', moduleName))
      .toList();
}

List<FallbackModuleQuestion> buildFallbackModuleQuestions(
  StudyTopic topic, {
  String? difficulty,
}) {
  final moduleName = topic.title.trim().isEmpty ? 'Study Module' : topic.title.trim();
  final normalizedDifficulty = _normalizeDifficulty(difficulty ?? topic.difficulty);

  return fallbackQuestionTemplates.map((template) {
    final choices = template.choiceTemplates
        .map((choice) => choice.replaceAll('{moduleName}', moduleName))
        .toList();
    final safeCorrectIndex = template.correctChoiceIndex.clamp(0, choices.length - 1);

    return FallbackModuleQuestion(
      questionText: template.questionTemplate.replaceAll('{moduleName}', moduleName),
      choices: choices,
      correctAnswer: choices[safeCorrectIndex],
      explanation: template.explanationTemplate.replaceAll('{moduleName}', moduleName),
      difficulty: normalizedDifficulty,
    );
  }).toList();
}

StudyTopic buildFallbackStudyTopic(String prompt) {
  final normalizedPrompt = prompt.trim();
  final moduleName = _deriveModuleName(normalizedPrompt);
  final topic = _deriveTopic(moduleName, normalizedPrompt);
  final questions = fallbackQuestionsForModule(moduleName);

  final lessons = fallbackQuestionTemplates.asMap().entries.map((entry) {
    final index = entry.key;
    final template = entry.value;
    final question = questions[index];

    return StudyLesson(
      id: '',
      title: '${template.lessonTitle}: $moduleName',
      description:
          '${template.descriptionTemplate.replaceAll('{moduleName}', moduleName)} Focus question: $question',
      orderIndex: index,
    );
  }).toList();

  return StudyTopic(
    id: '',
    ownerId: null,
    linkedTopicId: null,
    title: moduleName,
    topic: topic,
    category: 'General Study',
    difficulty: 'normal',
    summary:
        'This module for $moduleName was created from the built-in fallback template because online generation was unavailable. Use the lesson questions to structure your review and build your own notes.',
    status: 'ready',
    sourceType: 'generated',
    imageUrl: '',
    fileUrl: null,
    popularityCount: 0,
    isOwnedByUser: false,
    lessons: lessons,
  );
}

String _deriveModuleName(String prompt) {
  if (prompt.isEmpty) return 'Study Skills Foundations';

  final sanitized = prompt
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp(r'^(i want to learn|teach me|help me learn)\s+', caseSensitive: false), '')
      .trim();

  if (sanitized.isEmpty) return 'Study Skills Foundations';
  if (sanitized.length <= 60) return _toTitleCase(sanitized);

  final words = sanitized.split(' ').take(8).join(' ');
  return _toTitleCase(words);
}

String _deriveTopic(String moduleName, String prompt) {
  final source = prompt.trim().isEmpty ? moduleName : prompt.trim();
  final words = source.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).take(3).toList();
  if (words.isEmpty) return moduleName;
  return _toTitleCase(words.join(' '));
}

String _toTitleCase(String value) {
  return value
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .map(
        (part) => part.length == 1
            ? part.toUpperCase()
            : '${part[0].toUpperCase()}${part.substring(1)}',
      )
      .join(' ');
}

String _normalizeDifficulty(String value) {
  final normalized = value.trim().toLowerCase();
  if (const {'easy', 'normal', 'hard', 'exam'}.contains(normalized)) {
    return normalized;
  }
  return 'normal';
}

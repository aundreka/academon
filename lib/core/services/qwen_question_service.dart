import 'dart:convert';
import 'package:http/http.dart' as http;

class QwenGeneratedQuestion {
  final String questionText;
  final List<String> choices;
  final String correctAnswer;
  final String explanation;
  final String difficulty;

  const QwenGeneratedQuestion({
    required this.questionText,
    required this.choices,
    required this.correctAnswer,
    required this.explanation,
    required this.difficulty,
  });
}

class QwenQuestionService {
  // =========================
  // QWEN CONFIG
  // =========================
  static const String _qwenApiKey = String.fromEnvironment(
    'QWEN_API_KEY',
    defaultValue: '',
  );

  static const String _qwenBaseUrl = String.fromEnvironment(
    'QWEN_API_BASE_URL',
    defaultValue: 'https://dashscope-intl.aliyuncs.com/compatible-mode/v1',
  );

  static const String _qwenModel = String.fromEnvironment(
    'QWEN_MODEL',
    defaultValue: 'qwen-turbo',
  );

  // =========================
  // GEMINI CONFIG (SEEDED)
  // =========================
  // 🔥 FOR TESTING ONLY
  static const String _geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  static const String _geminiModel = 'gemini-2.5-flash';

  const QwenQuestionService();

  Future<List<QwenGeneratedQuestion>> generateQuestions({
    required String moduleTitle,
    required String moduleTopic,
    required String moduleSummary,
    required String moduleDifficulty,
    int count = 20,
  }) async {
    final summary = moduleSummary.trim();
    if (summary.isEmpty) {
      throw Exception('Module needs a summary.');
    }

    final providerErrors = <String>[];
    final normalizedQwenKey = _qwenApiKey.trim();
    final normalizedGeminiKey = _geminiApiKey.trim();

    if (_hasUsableQwenKey(normalizedQwenKey)) {
      try {
        return await _generateWithQwen(
          moduleTitle,
          moduleTopic,
          moduleSummary,
          moduleDifficulty,
          count,
        );
      } catch (error) {
        providerErrors.add('$error');
      }
    } else if (normalizedQwenKey.isNotEmpty) {
      providerErrors.add(
        'Qwen is misconfigured. `QWEN_API_KEY` looks like a Google/Gemini key, not a DashScope key.',
      );
    }

    if (normalizedGeminiKey.isNotEmpty) {
      try {
        return await _generateWithGemini(
          moduleTitle,
          moduleTopic,
          moduleSummary,
          moduleDifficulty,
          count,
        );
      } catch (error) {
        providerErrors.add('$error');
      }
    }

    if (providerErrors.isEmpty) {
      throw Exception(
        'Question generation is not configured. Run with `--dart-define=QWEN_API_KEY=<dashscope-key>` or `--dart-define=GEMINI_API_KEY=<gemini-key>`.',
      );
    }

    throw Exception(providerErrors.join('\n'));
  }

  // =========================
  // QWEN IMPLEMENTATION
  // =========================
  Future<List<QwenGeneratedQuestion>> _generateWithQwen(
    String moduleTitle,
    String moduleTopic,
    String moduleSummary,
    String moduleDifficulty,
    int count,
  ) async {
    final response = await http.post(
      Uri.parse('$_qwenBaseUrl/chat/completions'),
      headers: {
        'Authorization': 'Bearer $_qwenApiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': _qwenModel,
        'response_format': {'type': 'json_object'},
        'messages': [
          {
            'role': 'system',
            'content':
                'Return ONLY JSON: {"questions":[{"question_text":"","choices":[],"correct_answer":"","explanation":"","difficulty":""}]}',
          },
          {
            'role': 'user',
            'content':
                'Create $count MCQs.\nTitle: $moduleTitle\nTopic: $moduleTopic\nDifficulty: $moduleDifficulty\nSummary: $moduleSummary',
          },
        ],
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Qwen failed: ${response.statusCode} ${response.body}');
    }

    final decoded = jsonDecode(response.body);
    final content = decoded['choices'][0]['message']['content'];

    return _parseQuestions(content, count);
  }

  // =========================
  // GEMINI IMPLEMENTATION
  // =========================
  Future<List<QwenGeneratedQuestion>> _generateWithGemini(
    String moduleTitle,
    String moduleTopic,
    String moduleSummary,
    String moduleDifficulty,
    int count,
  ) async {
    final response = await http.post(
      Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$_geminiModel:generateContent?key=$_geminiApiKey',
      ),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'systemInstruction': {
          'parts': [
            {
              'text':
                  'Return ONLY JSON in this exact shape: '
                  '{"questions":[{"question_text":"","choices":["","","",""],"correct_answer":"","explanation":"","difficulty":""}]}',
            },
          ],
        },
        "contents": [
          {
            'role': 'user',
            "parts": [
              {
                "text":
                    'Generate $count MCQs.\n'
                    "Title: $moduleTitle\nTopic: $moduleTopic\nDifficulty: $moduleDifficulty\nSummary: $moduleSummary",
              },
            ],
          },
        ],
        'generationConfig': {'responseMimeType': 'application/json'},
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Gemini failed: ${response.statusCode} ${response.body}');
    }

    final decoded = jsonDecode(response.body);

    final text = decoded['candidates'][0]['content']['parts'][0]['text'];

    return _parseQuestions(text, count);
  }

  // =========================
  // SHARED PARSER
  // =========================
  List<QwenGeneratedQuestion> _parseQuestions(String raw, int count) {
    final cleanJson = _extractJsonObject(raw);
    final parsed = jsonDecode(cleanJson);

    final rawQuestions = parsed['questions'] as List;

    return rawQuestions
        .map((q) {
          return QwenGeneratedQuestion(
            questionText: q['question_text'],
            choices: List<String>.from(q['choices']),
            correctAnswer: q['correct_answer'],
            explanation: q['explanation'],
            difficulty: q['difficulty'],
          );
        })
        .take(count)
        .toList();
  }

  bool _hasUsableQwenKey(String key) {
    if (key.isEmpty) {
      return false;
    }
    return !key.startsWith('AIza');
  }

  String _extractJsonObject(String raw) {
    final trimmed = raw.trim();
    if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
      return trimmed;
    }

    final fencedMatch = RegExp(
      r'```(?:json)?\s*([\s\S]*?)\s*```',
    ).firstMatch(trimmed);
    if (fencedMatch != null) {
      return fencedMatch.group(1)!.trim();
    }

    final jsonStart = trimmed.indexOf('{');
    final jsonEnd = trimmed.lastIndexOf('}');
    if (jsonStart >= 0 && jsonEnd > jsonStart) {
      return trimmed.substring(jsonStart, jsonEnd + 1);
    }

    throw Exception('Question generator returned an invalid JSON payload.');
  }
}

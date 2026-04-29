import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../models/study_topic.dart';
import 'n8n_service.dart';

class AiFallbackService {
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';
  static const String _apiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );
  static const String _model = String.fromEnvironment(
    'GEMINI_MODEL',
    defaultValue: 'gemini-1.5-flash',
  );

  static void _ensureConfigured() {
    if (_apiKey.isEmpty) {
      throw Exception(
        'Gemini fallback is not configured. Run with --dart-define=GEMINI_API_KEY=<your-key>',
      );
    }
  }

  static Future<List<Map<String, dynamic>>> generateFlashcardsFromPdf(
    Uint8List pdfBytes,
  ) async {
    _ensureConfigured();
    final materialText = N8nService.extractTextFromPdf(pdfBytes).trim();
    if (materialText.isEmpty) {
      throw Exception('No readable text was found in the selected PDF.');
    }
    final trimmedMaterial = materialText.length > 12000
        ? materialText.substring(0, 12000)
        : materialText;

    final response = await _chatComplete(
      systemPrompt:
          'You are an educational AI. Output ONLY raw JSON in this exact shape: '
          '{"flashcards":[{"front":"...","back":"..."}]}.',
      userPrompt:
          'Generate 10-20 concise flashcards from this material:\n$trimmedMaterial',
    );

    final parsed = _parseJsonObject(response);
    final cards = parsed['flashcards'];
    if (cards is! List) return <Map<String, dynamic>>[];
    return cards
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  static Future<List<Map<String, dynamic>>> generateReviewerFromPdf(
    Uint8List pdfBytes,
  ) async {
    _ensureConfigured();
    final materialText = N8nService.extractTextFromPdf(pdfBytes).trim();
    if (materialText.isEmpty) {
      throw Exception('No readable text was found in the selected PDF.');
    }

    final trimmedMaterial = materialText.length > 12000
        ? materialText.substring(0, 12000)
        : materialText;

    final response = await _chatComplete(
      systemPrompt:
          'You are an educational AI. Output ONLY raw JSON. '
          'Preferred shape is a JSON array where each item is: '
          '{"title":"...","material":"...","quiz":["..."]}. '
          'If needed, you may output {"modules":[...]} with the same item shape.',
      userPrompt:
          'Create 3-8 reviewer modules from this material. '
          'Each module needs a short title, concise material summary, and 3-5 quiz questions.\n$trimmedMaterial',
    );

    final parsed = _parseReviewerModules(response);
    return parsed
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  static Future<StudyTopic> generateTopicFromPrompt(String prompt) async {
    _ensureConfigured();

    final response = await _chatComplete(
      systemPrompt:
          'You are an educational AI that creates study topics. Output ONLY raw JSON '
          'with this exact shape: '
          '{"title":"...","topic":"...","category":"...","difficulty":"easy|normal|hard|exam",'
          '"summary":"...","lessons":[{"title":"...","description":"..."}]}.',
      userPrompt:
          'Create a study topic for this learner request: "$prompt". '
          'Make the summary concise and clear, and generate 4 to 7 lessons.',
    );

    final parsed = _parseJsonObject(response);
    final rawLessons = parsed['lessons'] as List<dynamic>? ?? const [];
    final lessons = rawLessons
        .whereType<Map>()
        .map(
          (item) => StudyLesson(
            id: '',
            title: '${item['title'] ?? 'Lesson'}'.trim(),
            description: '${item['description'] ?? ''}'.trim(),
            orderIndex: rawLessons.indexOf(item),
          ),
        )
        .where((lesson) => lesson.title.isNotEmpty)
        .toList();

    return StudyTopic(
      id: '',
      ownerId: null,
      linkedTopicId: null,
      title: '${parsed['title'] ?? 'Generated Topic'}'.trim(),
      topic: '${parsed['topic'] ?? parsed['category'] ?? 'General Study'}'.trim(),
      category: '${parsed['category'] ?? parsed['topic'] ?? 'General'}'.trim(),
      difficulty: '${parsed['difficulty'] ?? 'normal'}'.trim().toLowerCase(),
      summary: '${parsed['summary'] ?? ''}'.trim(),
      status: 'ready',
      sourceType: 'generated',
      imageUrl: '',
      fileUrl: null,
      popularityCount: 0,
      isOwnedByUser: false,
      lessons: lessons,
    );
  }

  static Future<String> _chatComplete({
    required String systemPrompt,
    required String userPrompt,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/$_model:generateContent?key=$_apiKey'),
      headers: const {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'systemInstruction': {
          'parts': [
            {'text': systemPrompt},
          ],
        },
        'contents': [
          {
            'role': 'user',
            'parts': [
              {'text': userPrompt},
            ],
          },
        ],
        'generationConfig': {
          'responseMimeType': 'application/json',
        },
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Gemini fallback failed: ${response.statusCode} ${response.body}');
    }

    final decoded = jsonDecode(response.body);
    String? content;
    if (decoded is Map<String, dynamic>) {
      final candidates = decoded['candidates'];
      if (candidates is List && candidates.isNotEmpty) {
        final firstCandidate = candidates.first;
        if (firstCandidate is Map<String, dynamic>) {
          final candidateContent = firstCandidate['content'];
          if (candidateContent is Map<String, dynamic>) {
            final parts = candidateContent['parts'];
            if (parts is List) {
              for (final part in parts) {
                if (part is Map<String, dynamic>) {
                  final text = part['text'];
                  if (text is String && text.trim().isNotEmpty) {
                    content = text;
                    break;
                  }
                }
              }
            }
          }
        }
      }
    }

    if (content is! String || content.trim().isEmpty) {
      throw Exception('Gemini fallback returned an empty response.');
    }

    return content.trim();
  }

  static Map<String, dynamic> _parseJsonObject(String raw) {
    final normalized = _extractJsonPayload(raw);
    final decoded = jsonDecode(normalized);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Gemini fallback response is not a JSON object.');
    }
    return decoded;
  }

  static List<dynamic> _parseReviewerModules(String raw) {
    final normalized = _extractJsonPayload(raw);
    final decoded = jsonDecode(normalized);
    if (decoded is List) {
      return decoded;
    }
    if (decoded is Map<String, dynamic>) {
      final modules = decoded['modules'] ?? decoded['reviewer'] ?? decoded['sections'];
      if (modules is List) {
        return modules;
      }
    }
    throw Exception('Gemini fallback reviewer response is not a supported JSON format.');
  }

  static String _extractJsonPayload(String raw) {
    final trimmed = raw.trim();
    if ((trimmed.startsWith('{') && trimmed.endsWith('}')) ||
        (trimmed.startsWith('[') && trimmed.endsWith(']'))) {
      return trimmed;
    }

    final blockMatch = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```').firstMatch(trimmed);
    if (blockMatch != null) {
      return blockMatch.group(1)!.trim();
    }

    final objectStart = trimmed.indexOf('{');
    final objectEnd = trimmed.lastIndexOf('}');
    if (objectStart >= 0 && objectEnd > objectStart) {
      return trimmed.substring(objectStart, objectEnd + 1);
    }

    final arrayStart = trimmed.indexOf('[');
    final arrayEnd = trimmed.lastIndexOf(']');
    if (arrayStart >= 0 && arrayEnd > arrayStart) {
      return trimmed.substring(arrayStart, arrayEnd + 1);
    }

    throw Exception('Unable to locate JSON payload in fallback response.');
  }
}

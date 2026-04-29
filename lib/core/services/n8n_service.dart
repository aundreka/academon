import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_pdf/pdf.dart';

class N8nService {
  static const String _baseUrl = String.fromEnvironment(
    'N8N_WEBHOOK_BASE_URL',
    defaultValue: 'https://witty-digital-module.onhexcorearena.com/webhook-test',
  );

  static String _webhookUrl(String path) {
    final normalizedBase = _baseUrl.endsWith('/')
        ? _baseUrl.substring(0, _baseUrl.length - 1)
        : _baseUrl;
    final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
    return '$normalizedBase/$normalizedPath';
  }

  static void _ensureConfigured() {
    if (_baseUrl.contains('YOUR-N8N-INSTANCE.com')) {
      throw Exception(
        'N8N webhook base URL is not configured. '
        'Run with --dart-define=N8N_WEBHOOK_BASE_URL=https://<your-host>/webhook',
      );
    }
  }

  static Future<List<Map<String, dynamic>>> generateFlashcards(
    Uint8List pdfBytes,
  ) async {
    _ensureConfigured();
    final materialText = extractTextFromPdf(pdfBytes).trim();
    if (materialText.isEmpty) {
      throw Exception('No readable text was found in the selected PDF.');
    }

    final response = await http.post(
      Uri.parse(_webhookUrl('flashcard-generate')),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({'materialText': materialText}),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Flashcard generation failed: ${response.statusCode} ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);
    final cards = decoded is Map<String, dynamic> ? decoded['flashcards'] : null;
    if (cards is! List) {
      return <Map<String, dynamic>>[];
    }
    return cards
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  static Future<List<Map<String, dynamic>>> uploadSyllabus(
    Uint8List pdfBytes,
    String fileName,
  ) async {
    _ensureConfigured();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(_webhookUrl('syllabus-upload')),
    )
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          pdfBytes,
          filename: fileName,
        ),
      );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      throw Exception(
        'Syllabus upload failed: ${response.statusCode} ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    if (decoded is Map<String, dynamic>) {
      return [decoded];
    }
    return <Map<String, dynamic>>[];
  }

  static Future<Map<String, dynamic>> submitQuiz(
    Uint8List pdfBytes,
    String fileName,
    List<Map<String, dynamic>> answers,
  ) async {
    _ensureConfigured();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(_webhookUrl('quiz-submit')),
    )
      ..fields['answers'] = jsonEncode(answers)
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          pdfBytes,
          filename: fileName,
        ),
      );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      throw Exception(
        'Quiz submission failed: ${response.statusCode} ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Unexpected quiz response format.');
    }
    return decoded;
  }

  static String extractTextFromPdf(Uint8List pdfBytes) {
    final document = PdfDocument(inputBytes: pdfBytes);
    try {
      final extractor = PdfTextExtractor(document);
      return extractor.extractText();
    } finally {
      document.dispose();
    }
  }
}

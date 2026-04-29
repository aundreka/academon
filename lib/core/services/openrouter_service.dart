import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_pdf/pdf.dart';

class OpenRouterService {
  static const String _apiKey = 'sk-or-v1-blablabla'; // 🔴 PUT YOUR KEY HERE
  static const String _apiUrl = 'https://openrouter.ai/api/v1/chat/completions';
  
  // You can change this to 'meta-llama/llama-3-70b-instruct', 'openai/gpt-3.5-turbo', etc.
  static const String _model = 'nvidia/nemotron-3-nano-30b-a3b:free'; 

  /// Helper to extract text from the uploaded PDF bytes
  static String _extractTextFromPdf(Uint8List bytes) {
    try {
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      final String text = PdfTextExtractor(document).extractText();
      document.dispose();
      return text;
    } catch (e) {
      throw Exception('Failed to read PDF text. Make sure it is a valid text-based PDF.');
    }
  }

  /// Sends a prompt to OpenRouter and expects a JSON response
  static Future<dynamic> _callOpenRouter(String prompt) async {
    final response = await http.post(
      Uri.parse(_apiUrl),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
        'HTTP-Referer': 'https://yourapp.com', // Optional but recommended by OpenRouter
        'X-Title': 'SchEDU Learn', // Optional
      },
      body: jsonEncode({
        'model': _model,
        'response_format': {'type': 'json_object'}, // Forces JSON output
        'messages': [
          {'role': 'user', 'content': prompt}
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final content = data['choices'][0]['message']['content'];
      // Clean up markdown block formatting if the LLM includes it
      final cleanContent = content.replaceAll('```json', '').replaceAll('```', '').trim();
      return jsonDecode(cleanContent);
    } else {
      throw Exception('Failed to generate from OpenRouter: ${response.body}');
    }
  }

  /// Generates Reviewer Modules
  static Future<List<Map<String, dynamic>>> generateReviewer(Uint8List pdfBytes, String fileName) async {
    final documentText = _extractTextFromPdf(pdfBytes);
    
    // Truncate text if it's too massive to save tokens, or send whole thing if model supports it.
    final safeText = documentText.length > 30000 ? documentText.substring(0, 30000) : documentText;

    final prompt = '''
    Analyze the following academic document and generate a structured study reviewer. 
    Return ONLY a raw JSON object with a single key "modules" containing an array of objects.
    Each object should have: "title" (string), "summary" (string), and "quiz" (an array of 3 important bullet points/takeaways).
    
    Document text:
    $safeText
    ''';

    final result = await _callOpenRouter(prompt);
    return List<Map<String, dynamic>>.from(result['modules'] ?? []);
  }

  /// Generates Flashcards
  static Future<List<Map<String, dynamic>>> generateFlashcards(Uint8List pdfBytes) async {
    final documentText = _extractTextFromPdf(pdfBytes);
    final safeText = documentText.length > 30000 ? documentText.substring(0, 30000) : documentText;

    final prompt = '''
    Analyze the following academic document and generate 10 study flashcards.
    Return ONLY a raw JSON object with a single key "flashcards" containing an array of objects.
    Each object must have "front" (the question) and "back" (the answer).
    
    Document text:
    $safeText
    ''';

    final result = await _callOpenRouter(prompt);
    return List<Map<String, dynamic>>.from(result['flashcards'] ?? []);
  }
}
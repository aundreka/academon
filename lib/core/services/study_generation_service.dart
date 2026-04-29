import 'dart:typed_data';

import 'ai_fallback_service.dart';
import 'n8n_service.dart';

class StudyGenerationService {
  const StudyGenerationService();

  Future<List<Map<String, dynamic>>> generateFlashcards(Uint8List pdfBytes) async {
    try {
      return await N8nService.generateFlashcards(pdfBytes);
    } catch (n8nError) {
      try {
        return await AiFallbackService.generateFlashcardsFromPdf(pdfBytes);
      } catch (apiError) {
        throw Exception(
          'Both generation paths failed.\nN8N: $n8nError\nFallback API: $apiError',
        );
      }
    }
  }

  Future<List<Map<String, dynamic>>> generateReviewer(
    Uint8List pdfBytes,
    String fileName,
  ) async {
    try {
      return await N8nService.uploadSyllabus(pdfBytes, fileName);
    } catch (n8nError) {
      try {
        return await AiFallbackService.generateReviewerFromPdf(pdfBytes);
      } catch (apiError) {
        throw Exception(
          'Both generation paths failed.\nN8N: $n8nError\nFallback API: $apiError',
        );
      }
    }
  }
}

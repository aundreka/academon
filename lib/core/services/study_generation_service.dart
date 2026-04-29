import 'dart:typed_data';

import '../data/questions.dart';
import '../models/study_topic.dart';
import 'ai_fallback_service.dart';
import 'n8n_service.dart';

class StudyGenerationService {
  const StudyGenerationService();

  Future<StudyTopic> generateTopicFromPrompt(String prompt) async {
    try {
      final generated = await N8nService.generateTopic(prompt);
      return _studyTopicFromMap(generated);
    } catch (_) {
      try {
        return await AiFallbackService.generateTopicFromPrompt(prompt);
      } catch (_) {
        return buildFallbackStudyTopic(prompt);
      }
    }
  }

  Future<List<Map<String, dynamic>>> generateFlashcards(Uint8List pdfBytes) async {
    try {
      return await N8nService.generateFlashcards(pdfBytes);
    } catch (n8nError) {
      try {
        return await AiFallbackService.generateFlashcardsFromPdf(pdfBytes);
      } catch (apiError) {
        throw Exception(
          'Both generation paths failed.\nN8N: $n8nError\nGemini fallback: $apiError',
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
          'Both generation paths failed.\nN8N: $n8nError\nGemini fallback: $apiError',
        );
      }
    }
  }

  StudyTopic _studyTopicFromMap(Map<String, dynamic> generated) {
    final rawLessons = generated['lessons'] as List<dynamic>? ?? const [];
    final lessons = <StudyLesson>[];

    for (var i = 0; i < rawLessons.length; i++) {
      final lesson = rawLessons[i];
      if (lesson is! Map) continue;

      final lessonMap = Map<String, dynamic>.from(lesson);
      final title = '${lessonMap['title'] ?? 'Lesson'}'.trim();
      if (title.isEmpty) continue;

      lessons.add(
        StudyLesson(
          id: '',
          title: title,
          description: '${lessonMap['description'] ?? ''}'.trim(),
          orderIndex: i,
        ),
      );
    }

    return StudyTopic(
      id: '',
      ownerId: null,
      linkedTopicId: null,
      title: '${generated['title'] ?? 'Generated Topic'}'.trim(),
      topic: '${generated['topic'] ?? generated['category'] ?? 'General Study'}'.trim(),
      category: '${generated['category'] ?? generated['topic'] ?? 'General'}'.trim(),
      difficulty: '${generated['difficulty'] ?? 'normal'}'.trim().toLowerCase(),
      summary: '${generated['summary'] ?? ''}'.trim(),
      status: 'ready',
      sourceType: 'generated',
      imageUrl: '${generated['image_url'] ?? generated['imageUrl'] ?? ''}'.trim(),
      fileUrl: null,
      popularityCount: 0,
      isOwnedByUser: false,
      lessons: lessons,
    );
  }
}

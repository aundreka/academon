import 'package:supabase_flutter/supabase_flutter.dart';

class StudyPersistenceService {
  const StudyPersistenceService();

  Future<void> saveFlashcardsFromUpload({
    required String sourceName,
    required List<Map<String, dynamic>> cards,
  }) async {
    if (cards.isEmpty) return;
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;

    final now = DateTime.now().toUtc().toIso8601String();
    final module = await client
        .from('modules')
        .insert({
          'user_id': userId,
          'title': _titleFromSource(sourceName, fallback: 'Flashcard Deck'),
          'topic': 'Flashcards',
          'difficulty': 'normal',
          'source_type': 'upload',
          'summary': 'Generated ${cards.length} flashcards from uploaded PDF.',
          'status': 'ready',
          'last_used_at': now,
          'updated_at': now,
        })
        .select('id')
        .single();

    final moduleId = module['id'] as String?;
    if (moduleId == null) return;

    final flashcardsPayload = <Map<String, dynamic>>[];
    for (var i = 0; i < cards.length; i++) {
      final item = cards[i];
      final question = '${item['front'] ?? item['question'] ?? ''}'.trim();
      final answer = '${item['back'] ?? item['answer'] ?? ''}'.trim();
      if (question.isEmpty || answer.isEmpty) continue;
      flashcardsPayload.add({
        'module_id': moduleId,
        'question': question,
        'answer': answer,
        'difficulty': 'normal',
        'order_index': i,
      });
    }

    if (flashcardsPayload.isNotEmpty) {
      await client.from('flashcards').insert(flashcardsPayload);
    }
  }

  Future<void> saveReviewerFromUpload({
    required String sourceName,
    required List<Map<String, dynamic>> modules,
  }) async {
    if (modules.isEmpty) return;
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;

    final now = DateTime.now().toUtc().toIso8601String();
    final moduleRow = await client
        .from('modules')
        .insert({
          'user_id': userId,
          'title': _titleFromSource(sourceName, fallback: 'Reviewer Module'),
          'topic': 'Reviewer',
          'difficulty': 'normal',
          'source_type': 'upload',
          'summary': 'Generated ${modules.length} reviewer section(s) from uploaded PDF.',
          'status': 'ready',
          'last_used_at': now,
          'updated_at': now,
        })
        .select('id')
        .single();

    final moduleId = moduleRow['id'] as String?;
    if (moduleId == null) return;

    final reviewersPayload = <Map<String, dynamic>>[];
    for (final item in modules) {
      final title = '${item['title'] ?? ''}'.trim();
      final content = '${item['material'] ?? item['summary'] ?? ''}'.trim();
      if (title.isEmpty || content.isEmpty) continue;
      reviewersPayload.add({
        'module_id': moduleId,
        'title': title,
        'content': content,
        'updated_at': now,
      });
    }

    if (reviewersPayload.isNotEmpty) {
      await client.from('reviewers').insert(reviewersPayload);
    }
  }

  String _titleFromSource(String sourceName, {required String fallback}) {
    final clean = sourceName.trim();
    if (clean.isEmpty) return fallback;
    final dot = clean.lastIndexOf('.');
    final name = dot > 0 ? clean.substring(0, dot) : clean;
    return name.trim().isEmpty ? fallback : name.trim();
  }
}

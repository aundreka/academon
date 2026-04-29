import 'dart:convert';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/questions.dart';
import '../models/study_topic.dart';
import 'study_generation_service.dart';

class StudyTopicService {
  static final RegExp _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-'
    r'[0-9a-fA-F]{4}-'
    r'[0-9a-fA-F]{4}-'
    r'[0-9a-fA-F]{4}-'
    r'[0-9a-fA-F]{12}$',
  );

  final SupabaseClient _supabase;
  final StudyGenerationService _generationService;

  StudyTopicService(
    this._supabase, {
    StudyGenerationService? generationService,
  }) : _generationService = generationService ?? const StudyGenerationService();

  Future<List<StudyTopic>> fetchUserModules() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return <StudyTopic>[];

    final moduleRows = await _supabase
        .from('modules')
        .select(
          'id, user_id, topic_id, title, topic, category, difficulty, source_type, '
          'file_url, image_url, summary, status, popularity_count',
        )
        .eq('user_id', user.id)
        .order('updated_at', ascending: false);

    if (moduleRows.isEmpty) return <StudyTopic>[];

    final modules = <StudyTopic>[];
    for (final row in moduleRows) {
      final map = Map<String, dynamic>.from(row);
      final lessons = await _fetchModuleLessons(map['id'] as String);
      modules.add(StudyTopic.fromModuleMap(map, lessons: lessons));
    }

    return modules;
  }

  Future<StudyTopic> fetchModuleDetail(String moduleId) async {
    final row = await _supabase
        .from('modules')
        .select(
          'id, user_id, topic_id, title, topic, category, difficulty, source_type, '
          'file_url, image_url, summary, status, popularity_count',
        )
        .eq('id', moduleId)
        .single();

    final lessons = await _fetchModuleLessons(moduleId);
    return StudyTopic.fromModuleMap(Map<String, dynamic>.from(row), lessons: lessons);
  }

  Future<List<StudyTopic>> fetchAvailableTopics() async {
    final topicRows = await _supabase
        .from('topics')
        .select(
          'id, created_by, title, topic, category, difficulty, summary, status, '
          'source_type, image_url, popularity_count',
        )
        .eq('status', 'ready')
        .order('popularity_count', ascending: false)
        .order('updated_at', ascending: false);

    if (topicRows.isEmpty) return <StudyTopic>[];

    final topics = <StudyTopic>[];
    for (final row in topicRows) {
      final map = Map<String, dynamic>.from(row);
      final lessons = await _fetchTopicLessons(map['id'] as String);
      topics.add(StudyTopic.fromTopicMap(map, lessons: lessons));
    }

    return topics;
  }

  Future<StudyTopic> createModule({
    required String title,
    required String topic,
    required String summary,
    required String difficulty,
    required String category,
    required List<StudyLesson> lessons,
    Uint8List? imageBytes,
    String? imageExtension,
    String sourceType = 'upload',
    String? linkedTopicId,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('You need to be logged in to create a module.');
    }

    final now = DateTime.now().toUtc().toIso8601String();
    final normalizedLinkedTopicId = _normalizeLinkedTopicId(linkedTopicId);
    final existingModule = await _findExistingModule(
      userId: user.id,
      linkedTopicId: normalizedLinkedTopicId,
      title: title,
      topic: topic,
      category: category,
      difficulty: difficulty,
    );
    if (existingModule != null) {
      return fetchModuleDetail(existingModule);
    }

    final module = await _supabase
        .from('modules')
        .insert({
          'user_id': user.id,
          'topic_id': normalizedLinkedTopicId,
          'title': title.trim(),
          'topic': topic.trim(),
          'category': category.trim(),
          'difficulty': difficulty.trim(),
          'source_type': sourceType,
          'summary': summary.trim(),
          'image_url': _toDataUri(imageBytes, imageExtension),
          'status': 'ready',
          'updated_at': now,
          'last_used_at': now,
        })
        .select(
          'id, user_id, topic_id, title, topic, category, difficulty, source_type, '
          'file_url, image_url, summary, status, popularity_count',
        )
        .single();

    final moduleId = module['id'] as String;
    if (lessons.isNotEmpty) {
      await _supabase.from('module_lessons').insert(
            lessons
                .asMap()
                .entries
                .map(
                  (entry) => {
                    'module_id': moduleId,
                    ...entry.value.copyWith(orderIndex: entry.key).toInsertMap(),
                  },
                )
                .toList(),
          );
    }

    return fetchModuleDetail(moduleId);
  }

  Future<StudyTopic> createModuleFromTopic(StudyTopic topic) {
    return createModule(
      title: topic.title,
      topic: topic.topic,
      summary: topic.summary,
      difficulty: topic.difficulty,
      category: topic.category,
      lessons: topic.lessons,
      sourceType: 'topic',
      linkedTopicId: _normalizeLinkedTopicId(topic.id),
    );
  }

  Future<StudyTopic> createGeneratedTopicModule(String prompt) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('You need to be logged in to create a module.');
    }

    final generated = await _generationService.generateTopicFromPrompt(prompt);
    final topicRow = await _supabase
        .from('topics')
        .insert({
          'created_by': user.id,
          'title': generated.title,
          'topic': generated.topic,
          'category': generated.category,
          'difficulty': generated.difficulty,
          'summary': generated.summary,
          'status': 'ready',
          'source_type': 'generated',
          'image_url': generated.imageUrl,
        })
        .select(
          'id, created_by, title, topic, category, difficulty, summary, status, '
          'source_type, image_url, popularity_count',
        )
        .single();

    final topicId = topicRow['id'] as String;
    if (generated.lessons.isNotEmpty) {
      await _supabase.from('topic_lessons').insert(
            generated.lessons
                .asMap()
                .entries
                .map(
                  (entry) => {
                    'topic_id': topicId,
                    ...entry.value.copyWith(orderIndex: entry.key).toInsertMap(),
                  },
                )
                .toList(),
          );
    }

    final module = await createModule(
      title: generated.title,
      topic: generated.topic,
      summary: generated.summary,
      difficulty: generated.difficulty,
      category: generated.category,
      lessons: generated.lessons,
      sourceType: 'generated',
      linkedTopicId: topicId,
      imageBytes: generated.imageBytes,
      imageExtension: 'png',
    );

    await _ensureModuleQuestions(module);
    return module;
  }

  Future<List<StudyLesson>> _fetchModuleLessons(String moduleId) async {
    final rows = await _supabase
        .from('module_lessons')
        .select('id, title, description, order_index')
        .eq('module_id', moduleId)
        .order('order_index', ascending: true);

    return rows
        .map((row) => StudyLesson.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<List<StudyLesson>> _fetchTopicLessons(String topicId) async {
    final rows = await _supabase
        .from('topic_lessons')
        .select('id, title, description, order_index')
        .eq('topic_id', topicId)
        .order('order_index', ascending: true);

    return rows
        .map((row) => StudyLesson.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  String? _toDataUri(Uint8List? imageBytes, String? imageExtension) {
    if (imageBytes == null || imageBytes.isEmpty) return null;
    final extension = (imageExtension ?? 'png').toLowerCase();
    final mimeType = switch (extension) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'gif' => 'image/gif',
      'webp' => 'image/webp',
      _ => 'image/png',
    };
    return 'data:$mimeType;base64,${base64Encode(imageBytes)}';
  }

  String? _normalizeLinkedTopicId(String? topicId) {
    final trimmed = topicId?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return _uuidPattern.hasMatch(trimmed) ? trimmed : null;
  }

  Future<String?> _findExistingModule({
    required String userId,
    required String? linkedTopicId,
    required String title,
    required String topic,
    required String category,
    required String difficulty,
  }) async {
    if (linkedTopicId != null) {
      final existing = await _supabase
          .from('modules')
          .select('id')
          .eq('user_id', userId)
          .eq('topic_id', linkedTopicId)
          .maybeSingle();
      final existingId = (existing?['id'] as String?)?.trim();
      if (existingId != null && existingId.isNotEmpty) {
        return existingId;
      }
    }

    final rows = await _supabase
        .from('modules')
        .select('id, title, topic, category, difficulty')
        .eq('user_id', userId);

    final normalizedTitle = _normalizeDuplicateKey(title);
    final normalizedTopic = _normalizeDuplicateKey(topic);
    final normalizedCategory = _normalizeDuplicateKey(category);
    final normalizedDifficulty = _normalizeDuplicateKey(difficulty);

    for (final row in rows.whereType<Map<String, dynamic>>()) {
      if (_normalizeDuplicateKey(row['title'] as String?) != normalizedTitle) continue;
      if (_normalizeDuplicateKey(row['topic'] as String?) != normalizedTopic) continue;
      if (_normalizeDuplicateKey(row['category'] as String?) != normalizedCategory) continue;
      if (_normalizeDuplicateKey(row['difficulty'] as String?) != normalizedDifficulty) continue;

      final existingId = (row['id'] as String?)?.trim();
      if (existingId != null && existingId.isNotEmpty) {
        return existingId;
      }
    }

    return null;
  }

  String _normalizeDuplicateKey(String? value) {
    return value?.trim().toLowerCase() ?? '';
  }

  Future<void> _ensureModuleQuestions(StudyTopic module) async {
    final existing = await _supabase
        .from('questions')
        .select('id')
        .eq('module_id', module.id)
        .eq('question_type', 'mcq')
        .limit(1);
    if (existing.isNotEmpty) {
      return;
    }

    final fallbackQuestions = buildFallbackModuleQuestions(module);
    if (fallbackQuestions.isEmpty) {
      return;
    }

    await _supabase.from('questions').insert(
          fallbackQuestions
              .asMap()
              .entries
              .map(
                (entry) => entry.value.toInsertMap(
                  moduleId: module.id,
                  orderIndex: entry.key,
                ),
              )
              .toList(),
        );
  }
}

extension on StudyLesson {
  StudyLesson copyWith({
    String? id,
    String? title,
    String? description,
    int? orderIndex,
  }) {
    return StudyLesson(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      orderIndex: orderIndex ?? this.orderIndex,
    );
  }
}

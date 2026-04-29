import 'dart:convert';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/study_topic.dart';
import 'study_generation_service.dart';

class StudyTopicService {
  final SupabaseClient _supabase;
  final StudyGenerationService _generationService;

  StudyTopicService(
    this._supabase, {
    StudyGenerationService? generationService,
  }) : _generationService = generationService ?? const StudyGenerationService();

  Future<List<StudyTopic>> fetchUserModules() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return const <StudyTopic>[];

    final moduleRows = await _supabase
        .from('modules')
        .select(
          'id, user_id, topic_id, title, topic, category, difficulty, source_type, '
          'file_url, image_url, summary, status, popularity_count',
        )
        .eq('user_id', user.id)
        .order('updated_at', ascending: false);

    if (moduleRows.isEmpty) return const <StudyTopic>[];

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

    if (topicRows.isEmpty) return const <StudyTopic>[];

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
    final module = await _supabase
        .from('modules')
        .insert({
          'user_id': user.id,
          'topic_id': linkedTopicId,
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

    return createModule(
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

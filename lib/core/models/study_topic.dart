import 'dart:convert';
import 'dart:typed_data';

class StudyLesson {
  final String id;
  final String title;
  final String description;
  final int orderIndex;

  const StudyLesson({
    required this.id,
    required this.title,
    required this.description,
    required this.orderIndex,
  });

  factory StudyLesson.fromMap(Map<String, dynamic> map) {
    return StudyLesson(
      id: (map['id'] as String?) ?? '',
      title: ((map['title'] as String?) ?? '').trim(),
      description: ((map['description'] as String?) ?? '').trim(),
      orderIndex: (map['order_index'] as int?) ?? 0,
    );
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'title': title,
      'description': description,
      'order_index': orderIndex,
    };
  }
}

class StudyTopic {
  final String id;
  final String? ownerId;
  final String? linkedTopicId;
  final String title;
  final String topic;
  final String category;
  final String difficulty;
  final String summary;
  final String status;
  final String sourceType;
  final String imageUrl;
  final String? fileUrl;
  final int popularityCount;
  final bool isOwnedByUser;
  final List<StudyLesson> lessons;

  const StudyTopic({
    required this.id,
    required this.ownerId,
    required this.linkedTopicId,
    required this.title,
    required this.topic,
    required this.category,
    required this.difficulty,
    required this.summary,
    required this.status,
    required this.sourceType,
    required this.imageUrl,
    required this.fileUrl,
    required this.popularityCount,
    required this.isOwnedByUser,
    this.lessons = const [],
  });

  factory StudyTopic.fromModuleMap(
    Map<String, dynamic> map, {
    List<StudyLesson> lessons = const [],
  }) {
    return StudyTopic(
      id: (map['id'] as String?) ?? '',
      ownerId: map['user_id'] as String?,
      linkedTopicId: map['topic_id'] as String?,
      title: ((map['title'] as String?) ?? 'Untitled Module').trim(),
      topic: ((map['topic'] as String?) ?? 'General Study').trim(),
      category: ((map['category'] as String?) ?? (map['topic'] as String?) ?? 'General')
          .trim(),
      difficulty: ((map['difficulty'] as String?) ?? 'normal').trim(),
      summary: ((map['summary'] as String?) ?? '').trim(),
      status: ((map['status'] as String?) ?? 'ready').trim(),
      sourceType: ((map['source_type'] as String?) ?? 'upload').trim(),
      imageUrl: ((map['image_url'] as String?) ?? '').trim(),
      fileUrl: map['file_url'] as String?,
      popularityCount: (map['popularity_count'] as int?) ?? 0,
      isOwnedByUser: true,
      lessons: lessons,
    );
  }

  factory StudyTopic.fromTopicMap(
    Map<String, dynamic> map, {
    List<StudyLesson> lessons = const [],
  }) {
    return StudyTopic(
      id: (map['id'] as String?) ?? '',
      ownerId: map['created_by'] as String?,
      linkedTopicId: null,
      title: ((map['title'] as String?) ?? 'Untitled Topic').trim(),
      topic: ((map['topic'] as String?) ?? 'General Study').trim(),
      category: ((map['category'] as String?) ?? (map['topic'] as String?) ?? 'General')
          .trim(),
      difficulty: ((map['difficulty'] as String?) ?? 'normal').trim(),
      summary: ((map['summary'] as String?) ?? '').trim(),
      status: ((map['status'] as String?) ?? 'ready').trim(),
      sourceType: ((map['source_type'] as String?) ?? 'curated').trim(),
      imageUrl: ((map['image_url'] as String?) ?? '').trim(),
      fileUrl: null,
      popularityCount: (map['popularity_count'] as int?) ?? 0,
      isOwnedByUser: false,
      lessons: lessons,
    );
  }

  String get description =>
      summary.isNotEmpty ? summary : 'A study topic focused on $topic.';

  Uint8List? get imageBytes {
    if (!imageUrl.startsWith('data:image')) return null;
    final commaIndex = imageUrl.indexOf(',');
    if (commaIndex < 0 || commaIndex >= imageUrl.length - 1) return null;
    try {
      return base64Decode(imageUrl.substring(commaIndex + 1));
    } catch (_) {
      return null;
    }
  }
}

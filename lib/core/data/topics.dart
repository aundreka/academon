import '../models/study_topic.dart';

/// Local placeholder topics for UI seeding and prototyping.
///
/// Replace these with real topic data when you're ready.
final List<StudyTopic> seededTopics = [
  placeholderStudyTopic(
    id: 'topic_placeholder_1',
    title: 'Placeholder Topic',
    topic: 'General Study',
    category: 'Basics',
    difficulty: 'normal',
    summary: 'Short description for this placeholder topic.',
    popularityCount: 0,
  ),
];

/// Copy this helper call to add more placeholder topics quickly:
///
/// ```dart
/// placeholderStudyTopic(
///   id: 'topic_placeholder_2',
///   title: 'Another Topic',
///   topic: 'Subject Name',
///   category: 'Category',
///   difficulty: 'easy',
///   summary: 'Brief summary here.',
///   popularityCount: 0,
/// )
/// ```
StudyTopic placeholderStudyTopic({
  required String id,
  required String title,
  required String topic,
  required String category,
  required String difficulty,
  required String summary,
  int popularityCount = 0,
  String imageUrl = '',
}) {
  return StudyTopic(
    id: id,
    ownerId: null,
    linkedTopicId: null,
    title: title,
    topic: topic,
    category: category,
    difficulty: difficulty,
    summary: summary,
    status: 'ready',
    sourceType: 'curated',
    imageUrl: imageUrl,
    fileUrl: null,
    popularityCount: popularityCount,
    isOwnedByUser: false,
    lessons: const [],
  );
}

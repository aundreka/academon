import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/data/topics.dart';
import '../../core/models/study_topic.dart';
import '../../core/services/study_topic_service.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/textstyles.dart';
import 'pve.dart';

class PveScreen extends StatefulWidget {
  const PveScreen({super.key});

  @override
  State<PveScreen> createState() => _PveScreenState();
}

class _PveScreenState extends State<PveScreen> {
  late final StudyTopicService _topicService;
  late Future<_PveLobbyData> _lobbyFuture;
  final TextEditingController _chatController = TextEditingController();
  bool _generating = false;
  String? _convertingTopicId;

  @override
  void initState() {
    super.initState();
    _topicService = StudyTopicService(Supabase.instance.client);
    _lobbyFuture = _loadLobbyData();
  }

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  Future<_PveLobbyData> _loadLobbyData() async {
    final modules = List<StudyTopic>.from(await _topicService.fetchUserModules());
    final topics = List<StudyTopic>.from(seededTopics);

    int compareTopics(StudyTopic a, StudyTopic b) {
      final popularity = b.popularityCount.compareTo(a.popularityCount);
      if (popularity != 0) return popularity;
      final category = a.category.toLowerCase().compareTo(b.category.toLowerCase());
      if (category != 0) return category;
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    }

    modules.sort(compareTopics);
    topics.sort(compareTopics);

    return _PveLobbyData(modules: modules, topics: topics);
  }

  Future<void> _refreshLobby() async {
    final future = _loadLobbyData();
    setState(() {
      _lobbyFuture = future;
    });
    await future;
  }

  Future<void> _generateTopic() async {
    final prompt = _chatController.text.trim();
    if (prompt.isEmpty || _generating) return;

    setState(() {
      _generating = true;
    });

    try {
      final generatedModule = await _topicService.createGeneratedTopicModule(prompt);
      _chatController.clear();
      await _refreshLobby();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${generatedModule.title} is ready for training.',
            style: AppTextStyles.body.copyWith(color: Colors.white),
          ),
        ),
      );

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PveBattleScreen(topic: generatedModule),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().replaceFirst('Exception: ', ''),
            style: AppTextStyles.body.copyWith(color: Colors.white),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _generating = false;
        });
      }
    }
  }

  void _openTopic(StudyTopic topic) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PveBattleScreen(topic: topic),
      ),
    );
  }

  Future<void> _convertTopicToModule(StudyTopic topic) async {
    if (_convertingTopicId != null) return;

    setState(() {
      _convertingTopicId = topic.id;
    });
    try {
      final created = await _topicService.createModuleFromTopic(topic);
      await _refreshLobby();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${created.title} is ready in your modules.',
            style: AppTextStyles.body.copyWith(color: Colors.white),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().replaceFirst('Exception: ', ''),
            style: AppTextStyles.body.copyWith(color: Colors.white),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _convertingTopicId = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Training Grounds', style: AppTextStyles.button),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: _PveMenuBackground()),
          Positioned.fill(
            child: CustomPaint(
              painter: _ArenaGridPainter(),
            ),
          ),
          FutureBuilder<_PveLobbyData>(
            future: _lobbyFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Text(
                      snapshot.error.toString().replaceFirst('Exception: ', ''),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body.copyWith(fontSize: 13),
                    ),
                  ),
                );
              }

              final lobby = snapshot.data ?? const _PveLobbyData();

              return RefreshIndicator(
                onRefresh: _refreshLobby,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    104,
                    AppSpacing.md,
                    AppSpacing.xl,
                  ),
                  children: [
                    _GeneratorPanel(
                      controller: _chatController,
                      generating: _generating,
                      onGenerate: _generateTopic,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const _SectionHeader(
                      title: 'Train Your Brain',
                      subtitle: 'Strengthen your pokemons through battle.',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (lobby.modules.isEmpty)
                      const _EmptySectionCard(
                        message:
                            'No modules ready yet. Use the chatbot above to generate one for training.',
                      )
                    else
                      ...lobby.modules.asMap().entries.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: _LevelMenuTile(
                            topic: entry.value,
                            badgeLabel:
                                '${entry.value.category} | ${entry.value.popularityCount} plays',
                            accentColor: const Color(0xFF2FBD7C),
                            onTap: () => _openTopic(entry.value),
                          ),
                        ),
                      ),
                    const SizedBox(height: AppSpacing.lg),
                    const _SectionHeader(
                      title: 'Choose a Topic to Study',
                      subtitle: 'Convert a topic into your module before battling.',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (lobby.topics.isEmpty)
                      const _EmptySectionCard(
                        message: 'No public topics are available for training yet.',
                      )
                    else
                      ...lobby.topics.asMap().entries.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: _LevelMenuTile(
                            topic: entry.value,
                            badgeLabel:
                                '${entry.value.popularityCount} learners | ${entry.value.category}',
                            accentColor: const Color(0xFFFFB347),
                            onTap: _convertingTopicId == entry.value.id
                                ? null
                                : () => _convertTopicToModule(entry.value),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _GeneratorPanel extends StatelessWidget {
  final TextEditingController controller;
  final bool generating;
  final VoidCallback onGenerate;

  const _GeneratorPanel({
    required this.controller,
    required this.generating,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.28),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF2FBD7C).withOpacity(0.34),
                      AppColors.primary.withOpacity(0.18),
                      const Color(0xFF101827),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: -42,
              right: -26,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ),
            Positioned(
              bottom: -52,
              left: -26,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withOpacity(0.12),
                ),
              ),
            ),
            Positioned.fill(
              child: CustomPaint(
                painter: _DiagonalTexturePainter(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: Colors.white.withOpacity(0.1),
                        ),
                        child: const Icon(
                          Icons.smart_toy_rounded,
                          color: Color(0xFF86F0B8),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Battle Prep Chatbot',
                              style: AppTextStyles.button.copyWith(
                                fontSize: 15,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Describe what you want to learn and turn it into a playable training stage.',
                              style: AppTextStyles.body.copyWith(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: TextField(
                      controller: controller,
                      minLines: 2,
                      maxLines: 4,
                      style: AppTextStyles.body.copyWith(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(AppSpacing.md),
                        hintText:
                            'Example: Generate a beginner algebra module with equation practice.',
                        hintStyle: AppTextStyles.body.copyWith(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      onSubmitted: (_) => onGenerate(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: generating ? null : onGenerate,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF101827),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      icon: generating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.catching_pokemon_rounded),
                      label: Text(
                        generating ? 'Generating Topic...' : 'Generate and Train',
                        style: AppTextStyles.button.copyWith(fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.title.copyWith(
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: AppTextStyles.body.copyWith(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _LevelMenuTile extends StatelessWidget {
  final StudyTopic topic;
  final String badgeLabel;
  final Color accentColor;
  final VoidCallback? onTap;

  const _LevelMenuTile({
    required this.topic,
    required this.badgeLabel,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accentColor.withOpacity(0.30),
                AppColors.primary.withOpacity(0.16),
                const Color(0xFF101827),
              ],
            ),
            border: Border.all(color: accentColor.withOpacity(0.22)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.22),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              children: [
                Positioned(
                  top: -32,
                  right: -20,
                  child: Container(
                    width: 116,
                    height: 116,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.05),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: CustomPaint(
                    painter: _DiagonalTexturePainter(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          badgeLabel,
                          style: AppTextStyles.body.copyWith(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        topic.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.button.copyWith(
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        topic.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body.copyWith(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.16),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              topic.difficulty.toUpperCase(),
                              style: AppTextStyles.body.copyWith(
                                fontSize: 10,
                                color: accentColor,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              topic.topic,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.body.copyWith(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptySectionCard extends StatelessWidget {
  final String message;

  const _EmptySectionCard({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card.withOpacity(0.9),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.primary.withOpacity(0.14)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Text(
        message,
        style: AppTextStyles.body.copyWith(
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _PveMenuBackground extends StatelessWidget {
  const _PveMenuBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.background,
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF16213A),
                  Color(0xFF0A0F1C),
                  Color(0xFF050812),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 70,
          left: -80,
          right: -80,
          child: Container(
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.primary.withOpacity(0.28),
                  AppColors.primary.withOpacity(0.08),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 230,
          left: -40,
          right: -40,
          child: Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateX(1.08),
            alignment: Alignment.center,
            child: Container(
              height: 420,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF2FBD7C).withOpacity(0.42),
                    const Color(0xFF1A7A55).withOpacity(0.24),
                    const Color(0xFF0B1C18).withOpacity(0.86),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2FBD7C).withOpacity(0.22),
                    blurRadius: 60,
                    spreadRadius: 8,
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -30,
          left: -60,
          right: -60,
          child: Container(
            height: 220,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  AppColors.background.withOpacity(0.92),
                  AppColors.background,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ArenaGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.025)
      ..strokeWidth = 1;

    const gap = 28.0;

    for (double x = 0; x < size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }

    for (double y = 0; y < size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DiagonalTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.055)
      ..strokeWidth = 1;

    const gap = 18.0;

    for (double x = -size.height; x < size.width; x += gap) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PveLobbyData {
  final List<StudyTopic> modules;
  final List<StudyTopic> topics;

  const _PveLobbyData({
    this.modules = const <StudyTopic>[],
    this.topics = const <StudyTopic>[],
  });
}

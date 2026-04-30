import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/data/topics.dart';
import '../core/models/study_topic.dart';
import '../core/services/study_topic_service.dart';
import '../core/theme/colors.dart';
import '../core/theme/spacing.dart';
import '../core/theme/textstyles.dart';
import '../core/widgets/topics/topic_views.dart';
import 'arena/pve.dart';
import '../core/widgets/ui/topnav.dart';
import 'arena/pve_menu.dart';

class ArenaScreen extends StatefulWidget {
  const ArenaScreen({super.key});

  @override
  State<ArenaScreen> createState() => _ArenaScreenState();
}

class _ArenaScreenState extends State<ArenaScreen> {
  late final SupabaseClient _supabase;
  late final StudyTopicService _topicService;
  late Future<int?> _energyFuture;
  late Future<List<StudyTopic>> _popularTopicsFuture;
  String? _convertingTopicId;

  @override
  void initState() {
    super.initState();
    _supabase = Supabase.instance.client;
    _topicService = StudyTopicService(_supabase);
    _energyFuture = _loadCurrentEnergy();
    _popularTopicsFuture = _loadPopularTopics();
  }

  Future<int?> _loadCurrentEnergy() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final stats = await _supabase
        .from('user_stats')
        .select('current_energy')
        .eq('user_id', user.id)
        .maybeSingle();

    return stats?['current_energy'] as int?;
  }

  Future<void> _refreshEnergy() async {
    final nextFuture = _loadCurrentEnergy();
    final topicsFuture = _loadPopularTopics();
    setState(() {
      _energyFuture = nextFuture;
      _popularTopicsFuture = topicsFuture;
    });
    await nextFuture;
  }

  Future<List<StudyTopic>> _loadPopularTopics() async {
    final topics = List<StudyTopic>.from(seededTopics);
    topics.sort((a, b) {
      final popularity = b.popularityCount.compareTo(a.popularityCount);
      if (popularity != 0) return popularity;
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });
    return topics.take(3).toList(growable: false);
  }

  void _openScreen(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  Future<void> _convertTopicToModule(StudyTopic topic) async {
    if (_convertingTopicId != null) return;

    setState(() {
      _convertingTopicId = topic.id;
    });

    try {
      final created = await _topicService.createModuleFromTopic(topic);
      _popularTopicsFuture = _loadPopularTopics();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${created.title} is ready in Training Grounds.',
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

  Future<void> _openDemoPvp() async {
    try {
      final modules = await _topicService.fetchUserModules();
      if (!mounted) return;

      if (modules.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No modules available yet. Create one in Training Grounds first.',
              style: AppTextStyles.body.copyWith(color: Colors.white),
            ),
          ),
        );
        _openScreen(const PveScreen());
        return;
      }

      final random = math.Random();
      final module = modules[random.nextInt(modules.length)];
      _openScreen(PveBattleScreen(topic: module));
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: _ArenaBackground()),
        Positioned.fill(child: CustomPaint(painter: _ArenaGridPainter())),
        Column(
          children: [
            const AppTopNav(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshEnergy,
                child: Stack(
                  children: [
                    ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.md,
                        AppSpacing.md,
                        120,
                      ),
                      children: [
                        _ArenaControlPanel(
                          onTrain: () => _openScreen(const PveScreen()),
                          onQuickmatch: _openDemoPvp,
                          onRanked: _openDemoPvp,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _DailyPopularTopicsSection(
                          topicsFuture: _popularTopicsFuture,
                          convertingTopicId: _convertingTopicId,
                          onTopicTap: _convertTopicToModule,
                        ),
                      ],
                    ),
                    Positioned(
                      left: AppSpacing.md,
                      right: AppSpacing.md,
                      bottom: AppSpacing.md,
                      child: _EnergyPanel(energyFuture: _energyFuture),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ArenaBackground extends StatelessWidget {
  const _ArenaBackground();

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
          top: 210,
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
          top: 295,
          left: 24,
          right: 24,
          child: Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateX(1.08),
            alignment: Alignment.center,
            child: Container(
              height: 230,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),

        Positioned(
          top: 335,
          left: 72,
          right: 72,
          child: Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateX(1.08),
            alignment: Alignment.center,
            child: Container(
              height: 145,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
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

class _ArenaControlPanel extends StatelessWidget {
  final VoidCallback onTrain;
  final VoidCallback onQuickmatch;
  final VoidCallback onRanked;

  const _ArenaControlPanel({
    required this.onTrain,
    required this.onQuickmatch,
    required this.onRanked,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.28),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        children: [
          _ArenaModeTile(
            title: 'Train',
            subtitle: 'Enter PvE dungeon trials',
            imagePath: 'assets/ui/train.png',
            icon: Icons.auto_awesome_rounded,
            accent: const Color(0xFF2FBD7C),
            onTap: onTrain,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _ArenaModeTile(
                  title: 'Ranked',
                  subtitle: 'Climb the trainer ladder',
                  imagePath: 'assets/ui/battle.png',
                  icon: Icons.emoji_events_rounded,
                  accent: const Color(0xFFFF8A3D),
                  onTap: onRanked,
                  compact: true,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _ArenaModeTile(
                  title: 'Quick\nmatch',
                  subtitle: 'Jump into a fast battle',
                  imagePath: 'assets/ui/battle.png',
                  icon: Icons.flash_on_rounded,
                  accent: const Color(0xFFFFB347),
                  onTap: onQuickmatch,
                  compact: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ArenaModeTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imagePath;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;
  final bool compact;

  const _ArenaModeTile({
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.icon,
    required this.accent,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final contentPadding = compact
        ? const EdgeInsets.fromLTRB(12, AppSpacing.md, 12, AppSpacing.md)
        : const EdgeInsets.all(AppSpacing.md);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Ink(
          height: compact ? 152 : 168,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accent.withOpacity(0.36),
                AppColors.primary.withOpacity(0.20),
                const Color(0xFF101827),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withOpacity(0.18),
                blurRadius: 26,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              children: [
                Positioned(
                  top: -42,
                  right: -30,
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
                  child: CustomPaint(painter: _DiagonalTexturePainter()),
                ),
                Padding(
                  padding: contentPadding,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(icon, color: accent, size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    'MODE',
                                    style: AppTextStyles.body.copyWith(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.textSecondary,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            Text(
                              title,
                              style: AppTextStyles.title.copyWith(
                                fontSize: compact ? 18 : 28,
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              subtitle,
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                                fontSize: compact ? 11 : 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: compact ? AppSpacing.xs : AppSpacing.md),
                      Container(
                        width: compact ? 72 : 96,
                        height: compact ? 72 : 96,
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Image.asset(
                          imagePath,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) {
                            return Icon(
                              icon,
                              size: compact ? 34 : 48,
                              color: accent,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: AppSpacing.md,
                  bottom: AppSpacing.md,
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white.withOpacity(0.72),
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

class _DailyPopularTopicsSection extends StatelessWidget {
  final Future<List<StudyTopic>> topicsFuture;
  final ValueChanged<StudyTopic> onTopicTap;
  final String? convertingTopicId;

  const _DailyPopularTopicsSection({
    required this.topicsFuture,
    required this.onTopicTap,
    required this.convertingTopicId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card.withOpacity(0.9),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.primary.withOpacity(0.14)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily Popular Topics',
            style: AppTextStyles.title.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            'Convert one of today\'s seeded picks into a training module.',
            style: AppTextStyles.body.copyWith(fontSize: 12),
          ),
          const SizedBox(height: AppSpacing.md),
          FutureBuilder<List<StudyTopic>>(
            future: topicsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const SizedBox(
                  height: 150,
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Text(
                  'Unable to load popular topics right now.',
                  style: AppTextStyles.body.copyWith(fontSize: 12),
                );
              }

              final topics = snapshot.data ?? const <StudyTopic>[];
              if (topics.isEmpty) {
                return Text(
                  'No popular topics yet. Check back after more arena sessions.',
                  style: AppTextStyles.body.copyWith(fontSize: 12),
                );
              }

              return SizedBox(
                height: 174,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: topics.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final topic = topics[index];
                    return SizedBox(
                      width: 250,
                      child: StudyTopicCard(
                        topic: topic,
                        badgeLabel: convertingTopicId == topic.id
                            ? 'Converting...'
                            : '${topic.popularityCount} learners | ${topic.category}',
                        onTap: convertingTopicId == topic.id
                            ? null
                            : () => onTopicTap(topic),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _EnergyPanel extends StatelessWidget {
  final Future<int?> energyFuture;

  const _EnergyPanel({required this.energyFuture});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.card.withOpacity(0.92),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.30),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: FutureBuilder<int?>(
        future: energyFuture,
        builder: (context, snapshot) {
          final isLoading = snapshot.connectionState != ConnectionState.done;
          final hasError = snapshot.hasError;
          final energy = snapshot.data;

          return Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD56A), Color(0xFFFF9F3D)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD56A).withOpacity(0.25),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.bolt_rounded, color: Color(0xFF1B2234)),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Current Energy',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasError
                          ? 'Unable to load'
                          : isLoading
                          ? 'Loading...'
                          : '${energy ?? 0}',
                      style: AppTextStyles.title.copyWith(fontSize: 22),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
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

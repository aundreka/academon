import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/theme/colors.dart';
import '../core/theme/spacing.dart';
import '../core/theme/textstyles.dart';
import '../core/widgets/ui/topnav.dart';
import 'arena/pve.dart';
import 'arena/pvp.dart';

class ArenaScreen extends StatefulWidget {
  const ArenaScreen({super.key});

  @override
  State<ArenaScreen> createState() => _ArenaScreenState();
}

class _ArenaScreenState extends State<ArenaScreen> {
  late final SupabaseClient _supabase;
  late Future<int?> _energyFuture;

  @override
  void initState() {
    super.initState();
    _supabase = Supabase.instance.client;
    _energyFuture = _loadCurrentEnergy();
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
    setState(() => _energyFuture = nextFuture);
    await nextFuture;
  }

  void _openScreen(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const AppTopNav(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refreshEnergy,
            child: Stack(
              children: [
                const Positioned.fill(
                  child: _ArenaBackground(),
                ),
                Positioned.fill(
                  child: CustomPaint(
                    painter: _ArenaGridPainter(),
                  ),
                ),
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
                      onTrain: () => _openScreen(context, const PveScreen()),
                      onBattle: () => _openScreen(context, const PvpScreen()),
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
  final VoidCallback onBattle;

  const _ArenaControlPanel({
    required this.onTrain,
    required this.onBattle,
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
          _ArenaModeTile(
            title: 'Battle',
            subtitle: 'Challenge other trainers',
            imagePath: 'assets/ui/battle.png',
            icon: Icons.local_fire_department_rounded,
            accent: const Color(0xFFFF8A3D),
            onTap: onBattle,
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

  const _ArenaModeTile({
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Ink(
          height: 168,
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
                  child: CustomPaint(
                    painter: _DiagonalTexturePainter(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
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
                                fontSize: 28,
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              subtitle,
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Container(
                        width: 96,
                        height: 96,
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
                              size: 48,
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

class _EnergyPanel extends StatelessWidget {
  final Future<int?> energyFuture;

  const _EnergyPanel({
    required this.energyFuture,
  });

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
                    colors: [
                      Color(0xFFFFD56A),
                      Color(0xFFFF9F3D),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD56A).withOpacity(0.25),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.bolt_rounded,
                  color: Color(0xFF1B2234),
                ),
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
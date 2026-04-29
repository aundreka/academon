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
    if (user == null) {
      return null;
    }

    final stats = await _supabase
        .from('user_stats')
        .select('current_energy')
        .eq('user_id', user.id)
        .maybeSingle();

    return stats?['current_energy'] as int?;
  }

  Future<void> _refreshEnergy() async {
    final nextFuture = _loadCurrentEnergy();
    setState(() {
      _energyFuture = nextFuture;
    });
    await nextFuture;
  }

  void _openScreen(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
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
              fit: StackFit.expand,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: const AssetImage('assets/bg/arena.png'),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        AppColors.background.withOpacity(0.34),
                        BlendMode.darken,
                      ),
                    ),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.background.withOpacity(0.16),
                        AppColors.background.withOpacity(0.78),
                      ],
                    ),
                  ),
                ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final availableWidth = constraints.maxWidth - (AppSpacing.lg * 2);
                    final cardSize = availableWidth.clamp(220.0, 280.0);

                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.lg,
                        AppSpacing.lg,
                        120,
                      ),
                      children: [
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight - AppSpacing.lg - 120,
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _ArenaActionCard(
                                  title: 'Train',
                                  imagePath: 'assets/ui/train.png',
                                  color: const Color(0xFF2FBD7C),
                                  size: cardSize,
                                  onTap: () => _openScreen(context, const PveScreen()),
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                _ArenaActionCard(
                                  title: 'Battle',
                                  imagePath: 'assets/ui/battle.png',
                                  color: const Color(0xFFFF8A3D),
                                  size: cardSize,
                                  onTap: () => _openScreen(context, const PvpScreen()),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                Positioned(
                  left: AppSpacing.lg,
                  bottom: AppSpacing.lg,
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
        color: const Color(0xFF0E1524).withOpacity(0.86),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.24),
            blurRadius: 18,
            offset: const Offset(0, 10),
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
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF1C2841),
                ),
                child: const Icon(
                  Icons.bolt_rounded,
                  color: Color(0xFFFFD56A),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Current Energy',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
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
            ],
          );
        },
      ),
    );
  }
}

class _ArenaActionCard extends StatelessWidget {
  final String title;
  final String imagePath;
  final Color color;
  final double size;
  final VoidCallback onTap;

  const _ArenaActionCard({
    required this.title,
    required this.imagePath,
    required this.color,
    required this.size,
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
          width: size,
          height: size,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.card.withOpacity(0.84),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.22),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.title.copyWith(fontSize: 22),
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    color: color.withOpacity(0.12),
                  ),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Text(
                          title,
                          style: AppTextStyles.button.copyWith(
                            color: color,
                            fontSize: 18,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

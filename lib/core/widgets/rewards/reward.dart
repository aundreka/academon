import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/item.dart';
import '../../models/reward.dart';
import '../../theme/spacing.dart';
import '../../theme/textstyles.dart';
import '../item/item.dart';

class RewardDialog extends StatefulWidget {
  final String title;
  final String subtitle;
  final Reward reward;

  const RewardDialog({
    super.key,
    required this.title,
    required this.subtitle,
    required this.reward,
  });

  @override
  State<RewardDialog> createState() => _RewardDialogState();
}

class _RewardDialogState extends State<RewardDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _contentScale;
  late final Animation<double> _contentOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _contentScale = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _contentOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 1, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(AppSpacing.lg),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: 0.86 + (_contentScale.value * 0.14),
            child: Opacity(
              opacity: _contentOpacity.value.clamp(0.0, 1.0),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 560),
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFF8B63),
                      Color(0xFFFFC95E),
                      Color(0xFF69E0D0),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFC9669).withOpacity(0.34),
                      blurRadius: 34,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: _CelebrationPainter(progress: _controller.value),
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.title,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.title.copyWith(
                            fontSize: 24,
                            color: const Color(0xFF18304A),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          widget.subtitle,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.body.copyWith(
                            color: const Color(0xFF27445F),
                            fontWeight: FontWeight.w700,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        RewardSummaryChips(
                          reward: widget.reward,
                          lightMode: true,
                          centered: true,
                        ),
                        if (widget.reward.items.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.lg),
                          SizedBox(
                            height: 188,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: widget.reward.items.length,
                              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
                              itemBuilder: (context, index) {
                                final item = widget.reward.items[index];
                                return _AnimatedRewardItem(
                                  item: item,
                                  delayIndex: index,
                                );
                              },
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.lg),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF17324E),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: Text(
                              'Awesome',
                              style: AppTextStyles.button.copyWith(fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class RewardSummaryChips extends StatelessWidget {
  final Reward reward;
  final bool lightMode;
  final bool centered;

  const RewardSummaryChips({
    super.key,
    required this.reward,
    this.lightMode = false,
    this.centered = false,
  });

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[
      if (reward.coins > 0)
        _RewardStatChip(
          icon: Icons.monetization_on_rounded,
          label: '${reward.coins} Coins',
          color: lightMode ? const Color(0xFF8C6500) : const Color(0xFFFFD15C),
          backgroundColor: lightMode ? const Color(0xFFFFE7A6) : const Color(0x1AFFF1B7),
        ),
      if (reward.xp > 0)
        _RewardStatChip(
          icon: Icons.bolt_rounded,
          label: '${reward.xp} XP',
          color: lightMode ? const Color(0xFF0F5868) : const Color(0xFF7CEBFF),
          backgroundColor: lightMode ? const Color(0xFFB9F4FF) : const Color(0x1A9AEFFF),
        ),
      if (reward.diamonds > 0)
        _RewardStatChip(
          icon: Icons.diamond_rounded,
          label: '${reward.diamonds} Diamonds',
          color: lightMode ? const Color(0xFF623D8E) : const Color(0xFFFFA0F4),
          backgroundColor: lightMode ? const Color(0xFFE5CBFF) : const Color(0x1AFFC8FB),
        ),
      if (reward.items.isNotEmpty)
        _RewardStatChip(
          icon: Icons.inventory_2_rounded,
          label: '${reward.items.length} Item${reward.items.length == 1 ? '' : 's'}',
          color: lightMode ? const Color(0xFF1F6A45) : const Color(0xFFA5FFCA),
          backgroundColor: lightMode ? const Color(0xFFC9FFE1) : const Color(0x1AB1FFD2),
        ),
    ];

    return Wrap(
      alignment: centered ? WrapAlignment.center : WrapAlignment.start,
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: chips,
    );
  }
}

class _RewardStatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color backgroundColor;

  const _RewardStatChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: AppTextStyles.body.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedRewardItem extends StatelessWidget {
  final InventoryItem item;
  final int delayIndex;

  const _AnimatedRewardItem({
    required this.item,
    required this.delayIndex,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 520 + (delayIndex * 160)),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, (1 - value) * 30),
          child: Transform.scale(
            scale: 0.82 + (value * 0.18),
            child: Opacity(
              opacity: value.clamp(0.0, 1.0),
              child: child,
            ),
          ),
        );
      },
      child: SizedBox(
        width: 132,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            ItemCard(
              item: item,
              width: 132,
              height: 180,
            ),
            Positioned(
              top: -8,
              right: -6,
              child: _SparkleBadge(quantity: item.quantity),
            ),
          ],
        ),
      ),
    );
  }
}

class _SparkleBadge extends StatelessWidget {
  final int quantity;

  const _SparkleBadge({
    required this.quantity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF17324E),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.auto_awesome_rounded,
            size: 14,
            color: Color(0xFFFFD66B),
          ),
          const SizedBox(width: 4),
          Text(
            'x$quantity',
            style: AppTextStyles.body.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _CelebrationPainter extends CustomPainter {
  final double progress;

  const _CelebrationPainter({
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final sparklePaint = Paint()..color = Colors.white.withOpacity(0.55);
    final balloonPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0x66FFFFFF);

    for (var i = 0; i < 14; i++) {
      final x = (size.width / 14) * i + 18;
      final y = 40 + math.sin((progress * 6) + i) * 16;
      canvas.drawCircle(Offset(x, y), i.isEven ? 3.5 : 2.5, sparklePaint);
    }

    for (var i = 0; i < 4; i++) {
      final x = 40 + (i * (size.width - 80) / 3);
      final y = size.height - 90 - (progress * 22) - (i.isEven ? 0 : 10);
      final rect = Rect.fromCenter(center: Offset(x, y), width: 22, height: 28);
      canvas.drawOval(rect, balloonPaint);
      canvas.drawLine(
        Offset(x, y + 14),
        Offset(x - (i.isEven ? 6 : -6), y + 34),
        Paint()
          ..color = Colors.white.withOpacity(0.35)
          ..strokeWidth = 1.2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CelebrationPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

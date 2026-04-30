import 'dart:math' as math;

import 'package:flutter/material.dart';

class PvPLoadingScreen extends StatefulWidget {
  const PvPLoadingScreen({
    super.key,
    this.title = 'Finding Opponent',
    this.subtitle = 'Preparing your PvP arena...',
  });

  final String title;
  final String subtitle;

  @override
  State<PvPLoadingScreen> createState() => _PvPLoadingScreenState();
}

class _PvPLoadingScreenState extends State<PvPLoadingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070B18),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.2,
            colors: [
              Color(0xFF1A237E),
              Color(0xFF0A0F1C),
              Color(0xFF050713),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _controller.value * math.pi * 2,
                        child: child,
                      );
                    },
                    child: Container(
                      width: 104,
                      height: 104,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF00E5FF),
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF5170FF).withOpacity(0.55),
                            blurRadius: 34,
                            spreadRadius: 6,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.sports_martial_arts_rounded,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                  ),
                  const SizedBox(height: 34),
                  Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.72),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 34),
                  const SizedBox(
                    width: 220,
                    child: LinearProgressIndicator(
                      minHeight: 8,
                      borderRadius: BorderRadius.all(Radius.circular(999)),
                      backgroundColor: Color(0x332D8CFF),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF00E5FF),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'Loading battle data...',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.55),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
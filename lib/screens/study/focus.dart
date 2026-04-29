import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/services/xp_service.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/textstyles.dart';
import '../../core/widgets/ui/topnav.dart';
class FocusScreen extends StatelessWidget {
  const FocusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        AppTopNav(),
        Expanded(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: FocusTabPanel(),
          ),
        ),
      ],
    );
  }
}

class FocusTabPanel extends StatefulWidget {
  const FocusTabPanel({super.key});

  @override
  State<FocusTabPanel> createState() => _FocusTabPanelState();
}

class _FocusTabPanelState extends State<FocusTabPanel> {
  final XpService _xpService = const XpService();

  static const int _breakSecondsTotal = 5 * 60;
  static const int _minDuration = 5;
  static const int _maxDuration = 90;

  int _durationMinutes = 25;
  int _secondsLeft = 25 * 60;
  int _breakSecondsLeft = _breakSecondsTotal;

  bool _started = false;
  bool _isRunning = false;
  bool _isBreak = false;
  bool _sessionDone = false;
  bool _xpGrantedForSession = false;

  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  int get _totalSeconds => _durationMinutes * 60;

  void _setDuration(int minutes) {
    if (_started) return;
    final clamped = minutes.clamp(_minDuration, _maxDuration);
    setState(() {
      _durationMinutes = clamped;
      _secondsLeft = clamped * 60;
    });
  }

  void _adjustDuration(int delta) => _setDuration(_durationMinutes + delta);

  void _startOrResume() {
    if (_sessionDone) return;
    setState(() {
      _started = true;
      _isRunning = true;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isRunning) return;
      setState(() {
        if (_isBreak) {
          if (_breakSecondsLeft <= 1) {
            _breakSecondsLeft = 0;
            _isRunning = false;
            _sessionDone = true;
            _timer?.cancel();
            _awardFocusXp();
          } else {
            _breakSecondsLeft--;
          }
        } else {
          if (_secondsLeft <= 1) {
            _secondsLeft = 0;
            _isRunning = false;
            _isBreak = true;
            _breakSecondsLeft = _breakSecondsTotal;
            _timer?.cancel();
          } else {
            _secondsLeft--;
          }
        }
      });
    });
  }

  void _pause() {
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _startBreak() {
    if (_sessionDone) return;
    setState(() {
      _started = true;
      _isBreak = true;
      _isRunning = true;
      if (_breakSecondsLeft <= 0 || _breakSecondsLeft > _breakSecondsTotal) {
        _breakSecondsLeft = _breakSecondsTotal;
      }
    });
    _startOrResume();
  }

  void _skipBreak() {
    _timer?.cancel();
    setState(() {
      _isBreak = false;
      _isRunning = false;
      _sessionDone = true;
    });
    _awardFocusXp();
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _started = false;
      _isRunning = false;
      _isBreak = false;
      _sessionDone = false;
      _xpGrantedForSession = false;
      _secondsLeft = _durationMinutes * 60;
      _breakSecondsLeft = _breakSecondsTotal;
    });
  }

  Future<void> _awardFocusXp() async {
    if (_xpGrantedForSession) return;
    _xpGrantedForSession = true;
    try {
      await _xpService.addXp(XpService.focusXp);
    } catch (_) {
      _xpGrantedForSession = false;
    }
  }

  String _format(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  double get _progress {
    if (_isBreak) {
      return (_breakSecondsTotal - _breakSecondsLeft) / _breakSecondsTotal;
    }
    return (_totalSeconds - _secondsLeft) / _totalSeconds;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF00E5FF).withOpacity(0.12),
                  Colors.transparent,
                  AppColors.primary.withOpacity(0.1),
                ],
              ),
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.card.withOpacity(0.95),
                AppColors.background.withOpacity(0.9),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.4),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.18),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _header(),
                const SizedBox(height: AppSpacing.md),
                _durationCard(),
                const SizedBox(height: AppSpacing.md),
                _timerCard(),
                const SizedBox(height: AppSpacing.md),
                _controlsCard(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _header() => Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.center_focus_strong_outlined,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Focus',
              style: AppTextStyles.title.copyWith(fontSize: 18),
            ),
          ),
        ],
      );

  Widget _durationCard() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.14),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.accent.withOpacity(0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Set Duration',
              style: AppTextStyles.button.copyWith(fontSize: 14),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Preview only. Choose your focus length before starting.',
              style: AppTextStyles.body.copyWith(fontSize: 12),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _MiniPill(
                  '-5',
                  onTap: _started ? null : () => _adjustDuration(-5),
                ),
                _MiniPill(
                  '-1',
                  onTap: _started ? null : () => _adjustDuration(-1),
                ),
                _MiniPill('${_durationMinutes}m'),
                _MiniPill(
                  '+1',
                  onTap: _started ? null : () => _adjustDuration(1),
                ),
                _MiniPill(
                  '+5',
                  onTap: _started ? null : () => _adjustDuration(5),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _timerCard() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.background.withOpacity(0.34),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(
              _sessionDone
                  ? 'Session Complete'
                  : _isBreak
                      ? 'Break Time'
                      : _isRunning
                          ? 'Focusing...'
                          : _started
                              ? 'Paused'
                              : 'Ready to Focus',
              style: AppTextStyles.body.copyWith(fontSize: 11, color: AppColors.accent),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _format(_isBreak ? _breakSecondsLeft : _secondsLeft),
              style: AppTextStyles.title.copyWith(fontSize: 36),
            ),
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: _progress.clamp(0, 1),
                minHeight: 10,
                backgroundColor: AppColors.card.withOpacity(0.8),
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.primary.withOpacity(0.9),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _isBreak
                  ? '${(_progress * 100).round()}% of break'
                  : '${(_progress * 100).round()}% of $_durationMinutes min',
              style: AppTextStyles.body.copyWith(fontSize: 12),
            ),
          ],
        ),
      );

  Widget _controlsCard() {
    final isFocusDone = !_isBreak && _started && _secondsLeft == 0 && !_sessionDone;
    return Column(
      children: [
        if (!_isRunning && !_sessionDone && !isFocusDone)
          _ActionButton(
            label: _started ? 'Resume' : 'Start Session',
            icon: Icons.play_arrow_rounded,
            onTap: _startOrResume,
          ),
        if (_isRunning)
          _ActionButton(
            label: _isBreak ? 'Pause Break' : 'Pause',
            icon: Icons.pause_rounded,
            onTap: _pause,
          ),
        if (isFocusDone && !_isBreak) ...[
          _ActionButton(
            label: 'Start Break',
            icon: Icons.free_breakfast_rounded,
            onTap: _startBreak,
          ),
          const SizedBox(height: AppSpacing.sm),
          _ActionButton(
            label: 'Skip Break',
            icon: Icons.skip_next_rounded,
            muted: true,
            onTap: _skipBreak,
          ),
        ],
        if (_sessionDone)
          _ActionButton(
            label: 'Another Round',
            icon: Icons.replay_rounded,
            onTap: _reset,
          ),
        const SizedBox(height: AppSpacing.sm),
        _ActionButton(
          label: 'Reset Timer',
          icon: Icons.restart_alt_rounded,
          muted: true,
          onTap: _reset,
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    this.onTap,
    this.muted = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Opacity(
        opacity: onTap == null ? 0.45 : 1,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm,
            horizontal: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: muted
                ? null
                : LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.9),
                      AppColors.accent.withOpacity(0.75),
                    ],
                  ),
            color: muted ? AppColors.background.withOpacity(0.35) : null,
            border: Border.all(
              color: muted
                  ? AppColors.primary.withOpacity(0.2)
                  : AppColors.accent.withOpacity(0.35),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.textPrimary, size: 18),
              const SizedBox(width: AppSpacing.sm),
              Text(
                label,
                style: AppTextStyles.button.copyWith(fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  const _MiniPill(
    this.text, {
    this.onTap,
  });

  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Opacity(
        opacity: onTap == null ? 0.55 : 1,
        child: Container(
          width: 44,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.background.withOpacity(0.35),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.2),
            ),
          ),
          child: Text(
            text,
            style: AppTextStyles.button.copyWith(fontSize: 12),
          ),
        ),
      ),
    );
  }
}

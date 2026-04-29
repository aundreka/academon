import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/textstyles.dart';

class PvpScreen extends StatelessWidget {
  const PvpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Battle',
          style: AppTextStyles.button,
        ),
        backgroundColor: AppColors.card,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(
            'PvP battle queue coming next.',
            style: AppTextStyles.body.copyWith(
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

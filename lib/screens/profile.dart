import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/theme/colors.dart';
import '../core/theme/spacing.dart';
import '../core/theme/textstyles.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<Map<String, dynamic>?> getProfile() async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) return null;

    try {
      final data = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      return data;
    } catch (e) {
      return null;
    }
  }

  Future<void> logout(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Widget statCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.accent),
          const SizedBox(height: 6),
          Text(value, style: AppTextStyles.title.copyWith(fontSize: 16)),
          Text(label,
              style: AppTextStyles.body.copyWith(
                  color: AppColors.textPrimary.withOpacity(0.7))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text("Trainer Profile", style: AppTextStyles.title),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => logout(context),
          )
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: getProfile(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data;

          final username = data?['username'] ?? "Unknown Trainer";
          final email = data?['email'] ?? "No Email";

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 👤 PROFILE CARD
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(24),
                    border:
                        Border.all(color: AppColors.primary.withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor:
                            AppColors.primary.withOpacity(0.2),
                        child: const Icon(Icons.person,
                            size: 40, color: AppColors.accent),
                      ),
                      const SizedBox(height: 12),
                      Text(username, style: AppTextStyles.title),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textPrimary.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 📊 STATS SECTION (PLACEHOLDER FOR NOW)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Academon Stats",
                      style: AppTextStyles.title.copyWith(fontSize: 18)),
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: statCard("Level", "1", Icons.star),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: statCard("XP", "0", Icons.bolt),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: statCard("Coins", "0", Icons.monetization_on),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // 🔘 LOGOUT BUTTON (BIG ONE)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => logout(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      "LOGOUT",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
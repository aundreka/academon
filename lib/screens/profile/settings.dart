import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/pokemon_avatars.dart';
import '../../core/data/current_user_profile.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/spacing.dart';
import '../../core/theme/textstyles.dart';

class SettingsScreen extends StatefulWidget {
  final String? initialAvatarPath;

  const SettingsScreen({
    super.key,
    this.initialAvatarPath,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final SupabaseClient _supabase;
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String _selectedAvatarPath = defaultPokemonAvatar;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _supabase = Supabase.instance.client;
    _selectedAvatarPath = widget.initialAvatarPath ?? defaultPokemonAvatar;
    _loadSettings();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() => _loading = false);
      }
      return;
    }

    try {
      final ensuredProfile = await CurrentUserProfileService(_supabase)
          .ensureCurrentUserProfile();
      final profile = await _supabase
          .from('profiles')
          .select('id, username, email, avatar_path')
          .eq('id', user.id)
          .maybeSingle();

      final username =
          (profile?['username'] as String?) ?? ensuredProfile?.username ?? 'Trainer';
      final email =
          (profile?['email'] as String?) ?? ensuredProfile?.email ?? user.email ?? '';
      final avatarPath = (profile?['avatar_path'] as String?)?.trim();

      if (!mounted) return;
      setState(() {
        _userId = user.id;
        _usernameController.text = username;
        _emailController.text = email;
        if (avatarPath != null && avatarPath.isNotEmpty) {
          _selectedAvatarPath = avatarPath;
        }
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load settings.')),
      );
    }
  }

  Future<void> _saveSettings() async {
    if (_saving || !_formKey.currentState!.validate()) return;

    final user = _supabase.auth.currentUser;
    final userId = _userId;
    if (user == null || userId == null) return;

    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    setState(() => _saving = true);

    try {
      final authUpdates = UserAttributes(
        email: email == user.email ? null : email,
        password: password.isEmpty ? null : password,
        data: {
          'username': username,
        },
      );

      if (authUpdates.email != null ||
          authUpdates.password != null ||
          authUpdates.data != null) {
        await _supabase.auth.updateUser(authUpdates);
      }

      await _supabase.from('profiles').update({
        'username': username,
        'email': email,
        'avatar_path': _selectedAvatarPath,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', userId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            email == user.email
                ? 'Profile updated.'
                : 'Profile updated. Check your email if Supabase asks you to confirm the new address.',
          ),
        ),
      );
      Navigator.of(context).pop(true);
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save settings: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Settings',
          style: AppTextStyles.title.copyWith(fontSize: 18),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.xl,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: _panelDecoration(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Trainer Identity',
                              style: AppTextStyles.title.copyWith(fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Update how your account appears in Academon and keep your login info current.',
                              style: AppTextStyles.body.copyWith(
                                color: const Color(0xFF90A4D2),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            _buildField(
                              controller: _usernameController,
                              label: 'Username',
                              icon: Icons.person_outline_rounded,
                              validator: (value) {
                                final text = value?.trim() ?? '';
                                if (text.isEmpty) return 'Username is required.';
                                if (text.length < 3) {
                                  return 'Username must be at least 3 characters.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _buildField(
                              controller: _emailController,
                              label: 'Email',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                final text = value?.trim() ?? '';
                                if (text.isEmpty) return 'Email is required.';
                                if (!text.contains('@')) return 'Enter a valid email.';
                                return null;
                              },
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _buildField(
                              controller: _passwordController,
                              label: 'New Password',
                              icon: Icons.lock_outline_rounded,
                              obscureText: true,
                              hintText: 'Leave blank to keep current password',
                              validator: (value) {
                                final text = value?.trim() ?? '';
                                if (text.isNotEmpty && text.length < 6) {
                                  return 'Password must be at least 6 characters.';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: _panelDecoration(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Choose Avatar',
                              style: AppTextStyles.title.copyWith(fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Pick a Pokemon portrait for your profile hero.',
                              style: AppTextStyles.body.copyWith(
                                color: const Color(0xFF90A4D2),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Center(
                              child: Container(
                                width: 98,
                                height: 98,
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF8231FF), Color(0xFF53D7FF)],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF6D35FF).withOpacity(0.35),
                                      blurRadius: 22,
                                    ),
                                  ],
                                ),
                                child: DecoratedBox(
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFF101728),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: ClipOval(
                                      child: Image.asset(
                                        _selectedAvatarPath,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) => const Icon(
                                          Icons.person,
                                          size: 42,
                                          color: AppColors.accent,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: pokemonAvatarPaths.map((avatarPath) {
                                final isSelected = _selectedAvatarPath == avatarPath;

                                return GestureDetector(
                                  onTap: () {
                                    setState(() => _selectedAvatarPath = avatarPath);
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    width: 68,
                                    height: 68,
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF16233E),
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFF65D5FF)
                                            : const Color(0xFF27406D),
                                        width: isSelected ? 2 : 1,
                                      ),
                                    ),
                                    child: Image.asset(avatarPath),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saving ? null : _saveSettings,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2D75FF),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: _saving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'Save Changes',
                                  style: AppTextStyles.button.copyWith(color: Colors.white),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
    bool obscureText = false,
    String? hintText,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: AppTextStyles.body.copyWith(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        labelStyle: AppTextStyles.body.copyWith(color: const Color(0xFF90A4D2)),
        hintStyle: AppTextStyles.body.copyWith(color: const Color(0xFF5F709D)),
        prefixIcon: Icon(icon, color: const Color(0xFF7AD8FF)),
        filled: true,
        fillColor: const Color(0xFF16233E),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFF27406D)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFF69D6FF), width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFFF7D98)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFFF7D98), width: 1.4),
        ),
      ),
    );
  }
}

BoxDecoration _panelDecoration() {
  return BoxDecoration(
    color: const Color(0xFF121D36),
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: const Color(0xFF21365D)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.16),
        blurRadius: 18,
        offset: const Offset(0, 10),
      ),
    ],
  );
}

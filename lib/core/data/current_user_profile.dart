import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/pokemon_avatars.dart';

class CurrentUserProfile {
  final String id;
  final String username;
  final String email;
  final String avatarPath;

  const CurrentUserProfile({
    required this.id,
    required this.username,
    required this.email,
    required this.avatarPath,
  });
}

class CurrentUserProfileService {
  final SupabaseClient _supabase;

  const CurrentUserProfileService(this._supabase);

  Future<CurrentUserProfile?> ensureCurrentUserProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final existingProfile = await _supabase
        .from('profiles')
        .select('id, username, email, avatar_path')
        .eq('id', user.id)
        .maybeSingle();

    if (existingProfile != null) {
      await _supabase.from('user_stats').upsert({
        'user_id': user.id,
      }, onConflict: 'user_id');

      return CurrentUserProfile(
        id: user.id,
        username: (existingProfile['username'] as String?) ?? 'Trainer',
        email: (existingProfile['email'] as String?) ?? user.email ?? '',
        avatarPath: ((existingProfile['avatar_path'] as String?)?.isNotEmpty ??
                false)
            ? existingProfile['avatar_path'] as String
            : defaultPokemonAvatar,
      );
    }

    final fallbackEmail = user.email ?? '';
    final baseUsername = _preferredUsernameForUser(user);
    final username = await _generateUniqueUsername(
      baseUsername: baseUsername,
      userId: user.id,
    );

    final profilePayload = {
      'id': user.id,
      'username': username,
      'email': fallbackEmail,
      'avatar_path': defaultPokemonAvatar,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    await _supabase.from('profiles').upsert(profilePayload, onConflict: 'id');
    await _supabase.from('user_stats').upsert({
      'user_id': user.id,
    }, onConflict: 'user_id');

    return CurrentUserProfile(
      id: user.id,
      username: username,
      email: fallbackEmail,
      avatarPath: defaultPokemonAvatar,
    );
  }

  String _preferredUsernameForUser(User user) {
    final metadataUsername = (user.userMetadata?['username'] as String?)?.trim();
    if (metadataUsername != null && metadataUsername.isNotEmpty) {
      return metadataUsername;
    }

    final email = user.email?.trim() ?? '';
    if (email.contains('@')) {
      final localPart = email.split('@').first.trim();
      if (localPart.isNotEmpty) {
        return localPart;
      }
    }

    return 'trainer';
  }

  Future<String> _generateUniqueUsername({
    required String baseUsername,
    required String userId,
  }) async {
    final normalizedBase = baseUsername.trim().isEmpty ? 'trainer' : baseUsername.trim();
    final candidates = <String>[
      normalizedBase,
      '${normalizedBase}_${userId.substring(0, 6)}',
      'trainer_${userId.substring(0, 8)}',
    ];

    for (final candidate in candidates) {
      final match = await _supabase
          .from('profiles')
          .select('id')
          .eq('username', candidate)
          .maybeSingle();

      if (match == null || match['id'] == userId) {
        return candidate;
      }
    }

    return 'trainer_${userId.replaceAll('-', '').substring(0, 10)}';
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';

class XpService {
  const XpService();

  static const int reviewerXp = 8;
  static const int flashcardXp = 12;
  static const int focusXp = 15;

  Future<int> addXp(int amount) async {
    if (amount <= 0) return 0;

    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) return 0;

    final row = await client
        .from('user_stats')
        .select('xp')
        .eq('user_id', userId)
        .maybeSingle();

    final currentXp = (row?['xp'] as int?) ?? 0;
    final nextXp = currentXp + amount;

    await client.from('user_stats').update({
      'xp': nextXp,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('user_id', userId);

    return nextXp;
  }
}

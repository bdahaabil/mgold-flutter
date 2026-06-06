import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/env.dart';

class SupabaseService {
  static SupabaseClient? _client;

  static SupabaseClient get client {
    final c = _client;
    if (c == null) {
      throw StateError('Supabase not initialized');
    }
    return c;
  }

  static bool get isInitialized => _client != null;

  static Future<void> initialize() async {
    if (!Env.isConfigured) return;
    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey, // ignore: deprecated_member_use
    );
    _client = Supabase.instance.client;
  }
}

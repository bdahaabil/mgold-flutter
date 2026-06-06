import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/env.dart';
import '../supabase/supabase_client.dart';

final authStateProvider = StreamProvider<AuthState>((ref) {
  if (!Env.isConfigured) {
    return Stream.value(const AuthState(AuthChangeEvent.signedIn, null));
  }
  return SupabaseService.client.auth.onAuthStateChange;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  if (!Env.isConfigured) return true;
  final auth = ref.watch(authStateProvider);
  return auth.maybeWhen(
    data: (state) => state.session != null,
    orElse: () => false,
  );
});

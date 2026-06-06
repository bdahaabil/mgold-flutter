import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';

final dashboardProvider = FutureProvider((ref) async {
  final repo = ref.watch(dashboardRepositoryProvider);
  return repo.getSummary();
});

final dashboardRefreshProvider = StateProvider<int>((ref) => 0);

final dashboardSummaryProvider = FutureProvider((ref) async {
  ref.watch(dashboardRefreshProvider);
  final repo = ref.read(dashboardRepositoryProvider);
  return repo.getSummary();
});

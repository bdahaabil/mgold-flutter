import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';

final partnersProvider = FutureProvider((ref) async {
  ref.watch(partnersRefreshProvider);
  final repo = ref.watch(partnerRepositoryProvider);
  return repo.getPartners();
});

final distributionsProvider = FutureProvider((ref) async {
  final repo = ref.watch(partnerRepositoryProvider);
  return repo.getDistributions();
});

final partnersRefreshProvider = StateProvider<int>((ref) => 0);

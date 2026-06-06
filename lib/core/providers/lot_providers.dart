import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/enums.dart';
import '../models/holding.dart';
import '../repositories/lot_repository.dart';
import 'providers.dart';

final lotsProvider = FutureProvider.family<List<dynamic>, LotStatus?>((ref, status) async {
  final repo = ref.watch(lotRepositoryProvider);
  return repo.getLots(status: status);
});

final lotDetailProvider =
    FutureProvider.family<LotDetail, String>((ref, lotId) async {
  final repo = ref.watch(lotRepositoryProvider);
  return repo.getLotDetail(lotId);
});

final lotsRefreshProvider = StateProvider<int>((ref) => 0);

final lotsListProvider = FutureProvider<List<dynamic>>((ref) async {
  ref.watch(lotsRefreshProvider);
  final repo = ref.read(lotRepositoryProvider);
  return repo.getLots();
});

final activeHoldingsProvider =
    FutureProvider.family<List<Holding>, String>((ref, lotId) async {
  ref.watch(lotsRefreshProvider);
  final detail = await ref.watch(lotDetailProvider(lotId).future);
  return detail.activeHoldings;
});

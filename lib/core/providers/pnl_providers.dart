import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/pnl_repository.dart';
import 'providers.dart';

class PnlPeriod {
  const PnlPeriod({this.start, this.end});
  final DateTime? start;
  final DateTime? end;
}

final pnlPeriodProvider = StateProvider((ref) => const PnlPeriod());

final periodPnlProvider = FutureProvider<PeriodPnl>((ref) async {
  final period = ref.watch(pnlPeriodProvider);
  final repo = ref.watch(pnlRepositoryProvider);
  return repo.getPeriodPnl(start: period.start, end: period.end);
});

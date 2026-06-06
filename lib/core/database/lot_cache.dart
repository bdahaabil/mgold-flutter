import '../models/lot.dart';

/// Lightweight in-memory lot cache for offline reads between sessions.
/// Primary offline data lives in [LocalStore].
class LotCache {
  LotCache._();
  static final instance = LotCache._();

  final _lots = <String, Lot>{};

  void put(Lot lot) => _lots[lot.id] = lot;

  Lot? get(String id) => _lots[id];

  List<Lot> get all => _lots.values.toList();

  void clear() => _lots.clear();
}

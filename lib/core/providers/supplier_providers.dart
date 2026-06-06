import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/supplier_repository.dart';
import 'providers.dart';

final suppliersProvider = FutureProvider((ref) async {
  ref.watch(suppliersRefreshProvider);
  final repo = ref.watch(supplierRepositoryProvider);
  return repo.getSuppliers();
});

final supplierLedgerProvider =
    FutureProvider.family<List<SupplierLedgerEntry>, String>((ref, id) async {
  final repo = ref.watch(supplierRepositoryProvider);
  return repo.getLedger(id);
});

final suppliersRefreshProvider = StateProvider<int>((ref) => 0);

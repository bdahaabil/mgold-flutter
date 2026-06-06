import '../config/env.dart';
import '../data/local_store.dart';
import '../models/enums.dart';
import '../utils/pnl_calculator.dart';
import 'lot_repository.dart';
import 'supplier_repository.dart';

class DashboardSummary {
  const DashboardSummary({
    required this.openLots,
    required this.goldInHand,
    required this.supplierBalance,
    required this.realisedPnl,
    required this.unrealisedPnl,
    required this.cashIn,
    required this.cashOut,
  });

  final int openLots;
  final Map<String, double> goldInHand;
  final double supplierBalance;
  final double realisedPnl;
  final double unrealisedPnl;
  final double cashIn;
  final double cashOut;
}

class DashboardRepository {
  final _lotRepo = LotRepository();
  final _supplierRepo = SupplierRepository();
  final _local = LocalStore.instance;

  Future<DashboardSummary> getSummary() async {
    if (!Env.isConfigured) {
      _local.seed();
      final open = _local.lots
          .where((l) => l.status != LotStatus.closed && l.status != LotStatus.sold)
          .length;
      final gold = <String, double>{};
      for (final h in _local.holdings.where((h) => h.isInHand)) {
        final key = '${h.purity}';
        gold[key] = (gold[key] ?? 0) + h.weightG;
      }
      double supplierBal = 0;
      for (final s in _local.suppliers) {
        supplierBal += s.balanceMyr;
      }
      double realised = 0, unrealised = 0;
      for (final lot in _local.lots) {
        final pnl = calculateLotPnl(
          purchases: _local.purchases.where((p) => p.lotId == lot.id).toList(),
          assays: _local.assayResults.where((a) => a.lotId == lot.id).toList(),
          sales: _local.sales.where((s) => s.lotId == lot.id).toList(),
          expenses: _local.expenses.where((e) => e.lotId == lot.id).toList(),
          holdings: _local.holdings.where((h) => h.lotId == lot.id).toList(),
        );
        realised += pnl.realisedProfit - pnl.expenses;
        unrealised += pnl.unrealisedInventory;
      }
      final cashIn = _local.payments
          .where((p) => p.direction == PaymentDirection.in_)
          .fold<double>(0, (a, p) => a + p.amountMyr);
      final cashOut = _local.payments
          .where((p) => p.direction == PaymentDirection.out)
          .fold<double>(0, (a, p) => a + p.amountMyr);
      return DashboardSummary(
        openLots: open,
        goldInHand: gold,
        supplierBalance: supplierBal,
        realisedPnl: realised,
        unrealisedPnl: unrealised,
        cashIn: cashIn,
        cashOut: cashOut,
      );
    }

    final lots = await _lotRepo.getLots();
    final suppliers = await _supplierRepo.getSuppliers();
    final open = lots
        .where((l) => l.status != LotStatus.closed && l.status != LotStatus.sold)
        .length;
    double supplierBal = suppliers.fold(0, (a, s) => a + s.balanceMyr);
    double realised = 0, unrealised = 0;
    final gold = <String, double>{};
    for (final lot in lots) {
      final detail = await _lotRepo.getLotDetail(lot.id);
      final pnl = calculateLotPnl(
        purchases: detail.purchases,
        assays: detail.assays,
        sales: detail.sales,
        expenses: detail.expenses,
        holdings: detail.holdings,
      );
      realised += pnl.realisedProfit - pnl.expenses;
      unrealised += pnl.unrealisedInventory;
      for (final h in detail.activeHoldings) {
        gold['${h.purity}'] = (gold['${h.purity}'] ?? 0) + h.weightG;
      }
    }
    return DashboardSummary(
      openLots: open,
      goldInHand: gold,
      supplierBalance: supplierBal,
      realisedPnl: realised,
      unrealisedPnl: unrealised,
      cashIn: 0,
      cashOut: 0,
    );
  }
}

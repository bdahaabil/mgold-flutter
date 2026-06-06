import '../config/env.dart';
import '../data/local_store.dart';
import '../models/lot.dart';
import '../utils/pnl_calculator.dart';
import 'lot_repository.dart';

class PeriodPnl {
  const PeriodPnl({
    required this.totalRevenue,
    required this.totalCost,
    required this.totalExpenses,
    required this.netProfit,
    required this.lotBreakdown,
  });

  final double totalRevenue;
  final double totalCost;
  final double totalExpenses;
  final double netProfit;
  final List<LotPnlRow> lotBreakdown;
}

class LotPnlRow {
  const LotPnlRow({
    required this.lot,
    required this.pnl,
  });

  final Lot lot;
  final LotPnl pnl;
}

class PnlRepository {
  final _lotRepo = LotRepository();
  final _local = LocalStore.instance;

  Future<PeriodPnl> getPeriodPnl({
    DateTime? start,
    DateTime? end,
  }) async {
    if (!Env.isConfigured) {
      _local.seed();
      final rows = <LotPnlRow>[];
      double revenue = 0, cost = 0, expenses = 0;
      for (final lot in _local.lots) {
        final lotSales = _local.sales.where((s) {
          if (s.lotId != lot.id) return false;
          if (start != null && s.saleDate.isBefore(start)) return false;
          if (end != null && s.saleDate.isAfter(end)) return false;
          return true;
        }).toList();
        if (lotSales.isEmpty && start != null) continue;
        final pnl = calculateLotPnl(
          purchases: _local.purchases.where((p) => p.lotId == lot.id).toList(),
          assays: _local.assayResults.where((a) => a.lotId == lot.id).toList(),
          sales: lotSales.isEmpty
              ? _local.sales.where((s) => s.lotId == lot.id).toList()
              : lotSales,
          expenses: _local.expenses.where((e) => e.lotId == lot.id).toList(),
          holdings: _local.holdings.where((h) => h.lotId == lot.id).toList(),
        );
        rows.add(LotPnlRow(lot: lot, pnl: pnl));
        revenue += pnl.revenue;
        cost += pnl.cogs;
        expenses += pnl.expenses;
      }
      final netProfit = rows.fold<double>(
        0,
        (s, r) => s + r.pnl.netProfit,
      );
      return PeriodPnl(
        totalRevenue: revenue,
        totalCost: cost,
        totalExpenses: expenses,
        netProfit: netProfit,
        lotBreakdown: rows,
      );
    }

    final lots = await _lotRepo.getLots();
    final rows = <LotPnlRow>[];
    double revenue = 0, cost = 0, expenses = 0;
    for (final lot in lots) {
      final detail = await _lotRepo.getLotDetail(lot.id);
      var lotSales = detail.sales;
      if (start != null || end != null) {
        lotSales = lotSales.where((s) {
          if (start != null && s.saleDate.isBefore(start)) return false;
          if (end != null && s.saleDate.isAfter(end)) return false;
          return true;
        }).toList();
      }
      final pnl = calculateLotPnl(
        purchases: detail.purchases,
        assays: detail.assays,
        sales: lotSales.isEmpty ? detail.sales : lotSales,
        expenses: detail.expenses,
        holdings: detail.holdings,
      );
      if (pnl.revenue > 0 || pnl.cogs > 0 || pnl.unrealisedInventory > 0) {
        rows.add(LotPnlRow(lot: lot, pnl: pnl));
        revenue += pnl.revenue;
        cost += pnl.cogs;
        expenses += pnl.expenses;
      }
    }
    final netProfit = rows.fold<double>(
      0,
      (s, r) => s + r.pnl.netProfit,
    );
    return PeriodPnl(
      totalRevenue: revenue,
      totalCost: cost,
      totalExpenses: expenses,
      netProfit: netProfit,
      lotBreakdown: rows,
    );
  }
}

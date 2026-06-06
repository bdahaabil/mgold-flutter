import '../models/assay_result.dart';
import '../models/expense.dart';
import '../models/holding.dart';
import '../models/purchase.dart';
import '../models/sale.dart';

class LotPnl {
  const LotPnl({
    required this.revenue,
    required this.cogs,
    required this.realisedProfit,
    required this.unrealisedInventory,
    required this.expenses,
    required this.adjustments,
  });

  final double revenue;
  final double cogs;
  final double realisedProfit;
  final double unrealisedInventory;
  final double expenses;
  final double adjustments;

  /// Realised profit minus lot-level expenses (assay, transport, etc.).
  double get netProfit => realisedProfit - expenses;

  /// Legacy alias: total capital tied up in inventory + realised COGS.
  double get cost => cogs + unrealisedInventory;
}

LotPnl calculateLotPnl({
  required List<Purchase> purchases,
  required List<AssayResult> assays,
  required List<Sale> sales,
  required List<Expense> expenses,
  List<Holding>? holdings,
}) {
  final revenue = sales.fold<double>(0, (s, e) => s + e.totalMyr);
  final cogs = sales.fold<double>(
    0,
    (s, e) => s + (e.cogsMyr ?? 0),
  );
  final realisedProfit = revenue - cogs;
  final unrealised = holdings == null
      ? 0.0
      : holdings
          .where((h) => h.isInHand)
          .fold<double>(0, (s, e) => s + e.costBasisMyr);
  final adjustments = assays.fold<double>(0, (s, e) => s + e.adjustmentMyr);
  final expenseTotal = expenses.fold<double>(0, (s, e) => s + e.amountMyr);

  return LotPnl(
    revenue: revenue,
    cogs: cogs,
    realisedProfit: realisedProfit,
    unrealisedInventory: unrealised,
    expenses: expenseTotal,
    adjustments: adjustments,
  );
}

Map<String, double> partnerShares({
  required double netProfit,
  required Map<String, double> partnerPercents,
}) {
  return partnerPercents.map(
    (id, percent) => MapEntry(id, netProfit * percent / 100),
  );
}

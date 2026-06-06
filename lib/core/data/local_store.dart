import '../models/assay_result.dart';
import '../models/enums.dart';
import '../models/exchange.dart';
import '../models/expense.dart';
import '../models/holding.dart';
import '../models/lot.dart';
import '../models/partner.dart';
import '../models/payment.dart';
import '../models/profit_distribution.dart';
import '../models/profit_distribution_line.dart';
import '../models/purchase.dart';
import '../models/refining_job.dart';
import '../models/sale.dart';
import '../models/supplier.dart';
import '../utils/holdings_logic.dart';

/// In-memory store used when Supabase is not configured (demo / offline).
class LocalStore {
  LocalStore._();
  static final instance = LocalStore._();

  int _seq = 1;
  String _id() => 'local-${_seq++}';

  final lots = <Lot>[];
  final suppliers = <Supplier>[];
  final purchases = <Purchase>[];
  final assayResults = <AssayResult>[];
  final refiningJobs = <RefiningJob>[];
  final sales = <Sale>[];
  final holdings = <Holding>[];
  final exchanges = <Exchange>[];
  final expenses = <Expense>[];
  final payments = <Payment>[];
  final partners = <Partner>[];
  final distributions = <ProfitDistribution>[];
  final distributionLines = <ProfitDistributionLine>[];

  void seed() {
    if (suppliers.isNotEmpty) return;
    final supplier = Supplier(
      id: _id(),
      name: 'ABC Bullion Sdn Bhd',
      balanceMyr: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    suppliers.add(supplier);
    partners.addAll([
      Partner(
        id: _id(),
        name: 'Partner A',
        sharePercent: 60,
        email: 'a@mgold.local',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Partner(
        id: _id(),
        name: 'Partner B',
        sharePercent: 40,
        email: 'b@mgold.local',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ]);
  }

  Lot createLot(String lotNumber, {String? notes}) {
    final lot = Lot(
      id: _id(),
      lotNumber: lotNumber,
      status: LotStatus.open,
      notes: notes,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    lots.insert(0, lot);
    return lot;
  }

  void updateLotStatus(String lotId, LotStatus status) {
    final i = lots.indexWhere((l) => l.id == lotId);
    if (i >= 0) {
      lots[i] = lots[i].copyWith(status: status);
    }
  }

  void updatePurchase(Purchase p) {
    final i = purchases.indexWhere((x) => x.id == p.id);
    if (i < 0) return;
    final old = purchases[i];
    if (old.supplierId != p.supplierId) {
      _adjustSupplierBalance(old.supplierId, -old.totalMyr);
      _adjustSupplierBalance(p.supplierId, p.totalMyr);
    } else {
      _adjustSupplierBalance(p.supplierId, p.totalMyr - old.totalMyr);
    }
    purchases[i] = Purchase(
      id: p.id,
      lotId: p.lotId,
      supplierId: p.supplierId,
      claimedPurity: p.claimedPurity,
      weightG: p.weightG,
      pricePerG: p.pricePerG,
      totalMyr: p.totalMyr,
      purchaseDate: p.purchaseDate,
      notes: p.notes,
      createdAt: p.createdAt,
      supplierName: suppliers
          .firstWhere((s) => s.id == p.supplierId, orElse: () => suppliers.first)
          .name,
    );
  }

  Purchase addPurchase(Purchase p) {
    final purchase = Purchase(
      id: _id(),
      lotId: p.lotId,
      supplierId: p.supplierId,
      claimedPurity: p.claimedPurity,
      weightG: p.weightG,
      pricePerG: p.pricePerG,
      totalMyr: p.totalMyr,
      purchaseDate: p.purchaseDate,
      notes: p.notes,
      createdAt: DateTime.now(),
      supplierName: suppliers
          .firstWhere((s) => s.id == p.supplierId, orElse: () => suppliers.first)
          .name,
    );
    purchases.add(purchase);
    holdings.add(createPurchaseHolding(
      id: _id(),
      lotId: purchase.lotId,
      purity: purchase.claimedPurity,
      weightG: purchase.weightG,
      costBasisMyr: purchase.totalMyr,
    ));
    _adjustSupplierBalance(p.supplierId, purchase.totalMyr);
    return purchase;
  }

  void updateAssay(AssayResult a) {
    final i = assayResults.indexWhere((x) => x.id == a.id);
    if (i < 0) return;
    assayResults[i] = a;
    _updatePurchaseHoldingsPurity(a.lotId, a.actualPurity);
  }

  AssayResult addAssay(AssayResult a, {required double claimedPurity, required double pricePerG, String? supplierId}) {
    final adjustment = supplierId != null
        ? (a.actualPurity - claimedPurity) * a.actualWeightG * pricePerG / 10000
        : 0.0;
    final result = AssayResult(
      id: _id(),
      lotId: a.lotId,
      purchaseId: a.purchaseId,
      actualPurity: a.actualPurity,
      actualWeightG: a.actualWeightG,
      assayLab: a.assayLab,
      adjustmentMyr: adjustment,
      assayDate: a.assayDate,
      notes: a.notes,
      createdAt: DateTime.now(),
    );
    assayResults.add(result);
    if (supplierId != null) _adjustSupplierBalance(supplierId, adjustment);
    _updatePurchaseHoldingsPurity(a.lotId, a.actualPurity);
    updateLotStatus(a.lotId, LotStatus.assayed);
    return result;
  }

  Exchange addExchange(Exchange e) {
    final sourceIdx = holdings.indexWhere((h) => h.id == e.sourceHoldingId);
    if (sourceIdx < 0) {
      throw StateError('Source holding not found');
    }
    final source = holdings[sourceIdx];
    if (e.inputWeightG > source.weightG + weightEpsilon) {
      throw StateError('Input weight exceeds holding balance');
    }
    final costMoved = source.costPerG * e.inputWeightG;
    holdings[sourceIdx] = reduceHolding(source, e.inputWeightG, costMoved);

    final outputId = _id();
    final outputLabel =
        'Exchange @ ${e.outputPurity.toStringAsFixed(0)}';
    holdings.add(createOutputHolding(
      id: outputId,
      lotId: e.lotId,
      outputWeightG: e.outputWeightG,
      outputPurity: e.outputPurity,
      costBasisMyr: costMoved + e.expenseMyr,
      label: outputLabel,
    ));

    final exchange = Exchange(
      id: _id(),
      lotId: e.lotId,
      sourceHoldingId: e.sourceHoldingId,
      outputHoldingId: outputId,
      inputWeightG: e.inputWeightG,
      outputWeightG: e.outputWeightG,
      outputPurity: e.outputPurity,
      expenseMyr: e.expenseMyr,
      counterparty: e.counterparty,
      exchangeDate: e.exchangeDate,
      notes: e.notes,
      createdAt: DateTime.now(),
      sourceHoldingLabel: source.label,
    );
    exchanges.add(exchange);
    return exchange;
  }

  RefiningJob addRefining(RefiningJob r) {
    final job = RefiningJob(
      id: _id(),
      lotId: r.lotId,
      inputWeightG: r.inputWeightG,
      outputWeightG: r.outputWeightG,
      outputPurity: r.outputPurity,
      refinery: r.refinery,
      sentDate: r.sentDate,
      receivedDate: r.receivedDate,
      notes: r.notes,
      createdAt: DateTime.now(),
    );
    refiningJobs.add(job);
    if (r.receivedDate != null) {
      updateLotStatus(r.lotId, LotStatus.refined);
    }
    return job;
  }

  void updateSale(Sale s) {
    final i = sales.indexWhere((x) => x.id == s.id);
    if (i < 0) return;
    final existing = sales[i];
    sales[i] = Sale(
      id: s.id,
      lotId: s.lotId,
      saleType: s.saleType,
      weightG: s.weightG,
      purity: s.purity,
      pricePerG: s.pricePerG,
      totalMyr: s.totalMyr,
      customerName: s.customerName,
      saleDate: s.saleDate,
      holdingId: s.holdingId,
      cogsMyr: s.cogsMyr,
      notes: s.notes,
      createdAt: s.createdAt,
      lotNumber: s.lotNumber ?? existing.lotNumber,
    );
  }

  Sale addSale(Sale s) {
    double? cogs = s.cogsMyr;
    if (s.holdingId != null) {
      final idx = holdings.indexWhere((h) => h.id == s.holdingId);
      if (idx >= 0) {
        final holding = holdings[idx];
        cogs = holding.costPerG * s.weightG;
        holdings[idx] = reduceHolding(holding, s.weightG, cogs);
      }
    }
    final sale = Sale(
      id: _id(),
      lotId: s.lotId,
      saleType: s.saleType,
      weightG: s.weightG,
      purity: s.purity,
      pricePerG: s.pricePerG,
      totalMyr: s.totalMyr,
      customerName: s.customerName,
      saleDate: s.saleDate,
      holdingId: s.holdingId,
      cogsMyr: cogs,
      notes: s.notes,
      createdAt: DateTime.now(),
      lotNumber: lots.firstWhere((l) => l.id == s.lotId).lotNumber,
    );
    sales.add(sale);
    updateLotStatus(s.lotId, LotStatus.sold);
    return sale;
  }

  Expense addExpense(Expense e) {
    final expense = Expense(
      id: _id(),
      lotId: e.lotId,
      expenseType: e.expenseType,
      amountMyr: e.amountMyr,
      expenseDate: e.expenseDate,
      notes: e.notes,
      createdAt: DateTime.now(),
    );
    expenses.add(expense);
    return expense;
  }

  Payment addPayment(Payment p) {
    final payment = Payment(
      id: _id(),
      lotId: p.lotId,
      direction: p.direction,
      referenceType: p.referenceType,
      referenceId: p.referenceId,
      supplierId: p.supplierId,
      amountMyr: p.amountMyr,
      paymentDate: p.paymentDate,
      notes: p.notes,
      createdAt: DateTime.now(),
      supplierName: p.supplierId != null
          ? suppliers.firstWhere((s) => s.id == p.supplierId!).name
          : null,
    );
    payments.add(payment);
    if (p.direction == PaymentDirection.out && p.supplierId != null) {
      _adjustSupplierBalance(p.supplierId!, -p.amountMyr);
    }
    return payment;
  }

  Supplier addSupplier(String name, {String? notes}) {
    final s = Supplier(
      id: _id(),
      name: name,
      balanceMyr: 0,
      notes: notes,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    suppliers.add(s);
    return s;
  }

  Partner addPartner(Partner p) {
    final partner = Partner(
      id: _id(),
      userId: p.userId,
      name: p.name,
      sharePercent: p.sharePercent,
      email: p.email,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    partners.add(partner);
    return partner;
  }

  ProfitDistribution addDistribution(ProfitDistribution d, List<ProfitDistributionLine> lines) {
    final dist = ProfitDistribution(
      id: _id(),
      periodStart: d.periodStart,
      periodEnd: d.periodEnd,
      totalProfitMyr: d.totalProfitMyr,
      notes: d.notes,
      createdAt: DateTime.now(),
      lines: lines,
    );
    distributions.insert(0, dist);
    for (final line in lines) {
      distributionLines.add(ProfitDistributionLine(
        id: _id(),
        distributionId: dist.id,
        partnerId: line.partnerId,
        amountMyr: line.amountMyr,
        paidAt: line.paidAt ?? DateTime.now(),
        notes: line.notes,
        createdAt: DateTime.now(),
        partnerName: partners.firstWhere((p) => p.id == line.partnerId).name,
      ));
    }
    return dist;
  }

  void _updatePurchaseHoldingsPurity(String lotId, double purity) {
    for (var i = 0; i < holdings.length; i++) {
      final h = holdings[i];
      if (h.lotId == lotId && h.source == 'purchase' && h.status == 'in_hand') {
        holdings[i] = h.copyWith(purity: purity);
      }
    }
  }

  void _adjustSupplierBalance(String supplierId, double delta) {
    final i = suppliers.indexWhere((s) => s.id == supplierId);
    if (i >= 0) {
      final s = suppliers[i];
      suppliers[i] = Supplier(
        id: s.id,
        name: s.name,
        balanceMyr: s.balanceMyr + delta,
        notes: s.notes,
        createdAt: s.createdAt,
        updatedAt: DateTime.now(),
      );
    }
  }
}

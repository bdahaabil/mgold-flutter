import '../config/env.dart';
import '../data/local_store.dart';
import '../models/assay_result.dart';
import '../models/enums.dart';
import '../models/exchange.dart';
import '../models/expense.dart';
import '../models/holding.dart';
import '../models/lot.dart';
import '../models/payment.dart';
import '../models/purchase.dart';
import '../models/refining_job.dart';
import '../models/sale.dart';
import '../supabase/supabase_client.dart';
import '../utils/holdings_logic.dart';

class LotDetail {
  const LotDetail({
    required this.lot,
    required this.purchases,
    required this.assays,
    required this.refinings,
    required this.sales,
    required this.holdings,
    required this.exchanges,
    required this.expenses,
    required this.payments,
  });

  final Lot lot;
  final List<Purchase> purchases;
  final List<AssayResult> assays;
  final List<RefiningJob> refinings;
  final List<Sale> sales;
  final List<Holding> holdings;
  final List<Exchange> exchanges;
  final List<Expense> expenses;
  final List<Payment> payments;

  List<Holding> get activeHoldings =>
      holdings.where((h) => h.isInHand).toList();
}

class LotRepository {
  final _local = LocalStore.instance;

  Future<List<Lot>> getLots({LotStatus? status}) async {
    if (!Env.isConfigured) {
      _local.seed();
      final list = _local.lots;
      if (status == null) return list;
      return list.where((l) => l.status == status).toList();
    }
    var query = SupabaseService.client.from('lots').select();
    if (status != null) {
      query = query.eq('status', status.name);
    }
    final data = await query.order('created_at', ascending: false);
    return (data as List).map((e) => Lot.fromJson(e)).toList();
  }

  Future<Lot> createLot({required String lotNumber, String? notes}) async {
    if (!Env.isConfigured) {
      _local.seed();
      return _local.createLot(lotNumber, notes: notes);
    }
    final data = await SupabaseService.client
        .from('lots')
        .insert({'lot_number': lotNumber, 'notes': notes})
        .select()
        .single();
    return Lot.fromJson(data);
  }

  Future<void> updateLotStatus(String lotId, LotStatus status) async {
    if (!Env.isConfigured) {
      _local.updateLotStatus(lotId, status);
      return;
    }
    await SupabaseService.client
        .from('lots')
        .update({'status': status.name})
        .eq('id', lotId);
  }

  Future<LotDetail> getLotDetail(String lotId) async {
    if (!Env.isConfigured) {
      _local.seed();
      final lot = _local.lots.firstWhere((l) => l.id == lotId);
      return LotDetail(
        lot: lot,
        purchases: _local.purchases.where((p) => p.lotId == lotId).toList(),
        assays: _local.assayResults.where((a) => a.lotId == lotId).toList(),
        refinings: _local.refiningJobs.where((r) => r.lotId == lotId).toList(),
        sales: _local.sales.where((s) => s.lotId == lotId).toList(),
        holdings: _local.holdings.where((h) => h.lotId == lotId).toList(),
        exchanges: _local.exchanges.where((e) => e.lotId == lotId).toList(),
        expenses: _local.expenses.where((e) => e.lotId == lotId).toList(),
        payments: _local.payments.where((p) => p.lotId == lotId).toList(),
      );
    }
    final lotData = await SupabaseService.client
        .from('lots')
        .select()
        .eq('id', lotId)
        .single();
    final purchases = await SupabaseService.client
        .from('purchases')
        .select('*, suppliers(name)')
        .eq('lot_id', lotId);
    final assays = await SupabaseService.client
        .from('assay_results')
        .select()
        .eq('lot_id', lotId);
    final refinings = await SupabaseService.client
        .from('refining_jobs')
        .select()
        .eq('lot_id', lotId);
    final salesData = await SupabaseService.client
        .from('sales')
        .select()
        .eq('lot_id', lotId);
    final holdingsData = await SupabaseService.client
        .from('holdings')
        .select()
        .eq('lot_id', lotId)
        .order('created_at');
    final exchangesData = await SupabaseService.client
        .from('exchanges')
        .select()
        .eq('lot_id', lotId);
    final expenses = await SupabaseService.client
        .from('expenses')
        .select()
        .eq('lot_id', lotId);
    final payments = await SupabaseService.client
        .from('payments')
        .select('*, suppliers(name)')
        .eq('lot_id', lotId);

    return LotDetail(
      lot: Lot.fromJson(lotData),
      purchases: (purchases as List).map((e) => Purchase.fromJson(e)).toList(),
      assays: (assays as List).map((e) => AssayResult.fromJson(e)).toList(),
      refinings:
          (refinings as List).map((e) => RefiningJob.fromJson(e)).toList(),
      sales: (salesData as List).map((e) => Sale.fromJson(e)).toList(),
      holdings:
          (holdingsData as List).map((e) => Holding.fromJson(e)).toList(),
      exchanges:
          (exchangesData as List).map((e) => Exchange.fromJson(e)).toList(),
      expenses: (expenses as List).map((e) => Expense.fromJson(e)).toList(),
      payments: (payments as List).map((e) => Payment.fromJson(e)).toList(),
    );
  }

  Future<void> updatePurchase(Purchase purchase) async {
    if (!Env.isConfigured) {
      _local.updatePurchase(purchase);
      return;
    }
    await SupabaseService.client
        .from('purchases')
        .update(purchase.toUpdateJson())
        .eq('id', purchase.id);
  }

  Future<Purchase> addPurchase(Purchase purchase) async {
    if (!Env.isConfigured) {
      return _local.addPurchase(purchase);
    }
    final data = await SupabaseService.client
        .from('purchases')
        .insert(purchase.toInsertJson())
        .select('*, suppliers(name)')
        .single();
    final result = Purchase.fromJson(data);
    await SupabaseService.client.from('holdings').insert({
      'lot_id': result.lotId,
      'label': 'Purchase',
      'purity': result.claimedPurity,
      'weight_g': result.weightG,
      'original_weight_g': result.weightG,
      'cost_basis_myr': result.totalMyr,
      'source': 'purchase',
    });
    return result;
  }

  Future<void> updateAssay(AssayResult assay) async {
    if (!Env.isConfigured) {
      _local.updateAssay(assay);
      return;
    }
    await SupabaseService.client
        .from('assay_results')
        .update(assay.toUpdateJson())
        .eq('id', assay.id);
    await SupabaseService.client
        .from('holdings')
        .update({'purity': assay.actualPurity})
        .eq('lot_id', assay.lotId)
        .eq('source', 'purchase')
        .eq('status', 'in_hand');
  }

  Future<AssayResult> addAssay(AssayResult assay) async {
    if (!Env.isConfigured) {
      Purchase? purchase;
      if (assay.purchaseId != null) {
        purchase = _local.purchases
            .where((p) => p.id == assay.purchaseId)
            .firstOrNull;
      }
      return _local.addAssay(
        assay,
        claimedPurity: purchase?.claimedPurity ?? 9990,
        pricePerG: purchase?.pricePerG ?? 0,
        supplierId: purchase?.supplierId,
      );
    }
    final data = await SupabaseService.client
        .from('assay_results')
        .insert(assay.toInsertJson())
        .select()
        .single();
    await SupabaseService.client
        .from('holdings')
        .update({'purity': assay.actualPurity})
        .eq('lot_id', assay.lotId)
        .eq('source', 'purchase')
        .eq('status', 'in_hand');
    await updateLotStatus(assay.lotId, LotStatus.assayed);
    return AssayResult.fromJson(data);
  }

  Future<RefiningJob> addRefining(RefiningJob job) async {
    if (!Env.isConfigured) {
      return _local.addRefining(job);
    }
    final data = await SupabaseService.client
        .from('refining_jobs')
        .insert(job.toInsertJson())
        .select()
        .single();
    if (job.receivedDate != null) {
      await updateLotStatus(job.lotId, LotStatus.refined);
    }
    return RefiningJob.fromJson(data);
  }

  Future<Exchange> addExchange(Exchange exchange) async {
    if (!Env.isConfigured) {
      return _local.addExchange(exchange);
    }
    if (exchange.sourceHoldingId == null) {
      throw ArgumentError('sourceHoldingId is required');
    }
    final sourceData = await SupabaseService.client
        .from('holdings')
        .select()
        .eq('id', exchange.sourceHoldingId!)
        .single();
    final source = Holding.fromJson(sourceData);
    if (exchange.inputWeightG > source.weightG + weightEpsilon) {
      throw StateError('Input weight exceeds holding balance');
    }
    final costMoved = source.costPerG * exchange.inputWeightG;
    final reduced = reduceHolding(source, exchange.inputWeightG, costMoved);
    await SupabaseService.client
        .from('holdings')
        .update(reduced.toUpdateJson())
        .eq('id', source.id);

    final outputLabel = 'Exchange @ ${exchange.outputPurity.toStringAsFixed(0)}';
    final outputData = await SupabaseService.client
        .from('holdings')
        .insert({
          'lot_id': exchange.lotId,
          'label': outputLabel,
          'purity': exchange.outputPurity,
          'weight_g': exchange.outputWeightG,
          'original_weight_g': exchange.outputWeightG,
          'cost_basis_myr': costMoved + exchange.expenseMyr,
          'source': 'exchange',
        })
        .select()
        .single();
    final outputId = outputData['id'] as String;

    final exchangeData = await SupabaseService.client
        .from('exchanges')
        .insert({
          ...exchange.toInsertJson(),
          'output_holding_id': outputId,
        })
        .select()
        .single();
    return Exchange.fromJson(exchangeData);
  }

  Future<void> updateSale(Sale sale) async {
    if (!Env.isConfigured) {
      _local.updateSale(sale);
      return;
    }
    await SupabaseService.client
        .from('sales')
        .update(sale.toUpdateJson())
        .eq('id', sale.id);
  }

  Future<Sale> addSale(Sale sale) async {
    if (!Env.isConfigured) {
      return _local.addSale(sale);
    }
    double? cogs = sale.cogsMyr;
    if (sale.holdingId != null) {
      final holdingData = await SupabaseService.client
          .from('holdings')
          .select()
          .eq('id', sale.holdingId!)
          .single();
      final holding = Holding.fromJson(holdingData);
      cogs = holding.costPerG * sale.weightG;
      final reduced = reduceHolding(holding, sale.weightG, cogs);
      await SupabaseService.client
          .from('holdings')
          .update(reduced.toUpdateJson())
          .eq('id', holding.id);
    }
    final insertJson = sale.toInsertJson();
    if (cogs != null) insertJson['cogs_myr'] = cogs;

    final data = await SupabaseService.client
        .from('sales')
        .insert(insertJson)
        .select()
        .single();
    await updateLotStatus(sale.lotId, LotStatus.sold);
    return Sale.fromJson(data);
  }

  Future<Expense> addExpense(Expense expense) async {
    if (!Env.isConfigured) {
      return _local.addExpense(expense);
    }
    final data = await SupabaseService.client
        .from('expenses')
        .insert(expense.toInsertJson())
        .select()
        .single();
    return Expense.fromJson(data);
  }

  Future<Payment> addPayment(Payment payment) async {
    if (!Env.isConfigured) {
      return _local.addPayment(payment);
    }
    final data = await SupabaseService.client
        .from('payments')
        .insert(payment.toInsertJson())
        .select('*, suppliers(name)')
        .single();
    return Payment.fromJson(data);
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    if (!it.moveNext()) return null;
    return it.current;
  }
}

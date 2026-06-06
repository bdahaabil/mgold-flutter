import '../config/env.dart';
import '../data/local_store.dart';
import '../models/payment.dart';
import '../models/purchase.dart';
import '../models/supplier.dart';
import '../supabase/supabase_client.dart';

class SupplierLedgerEntry {
  const SupplierLedgerEntry({
    required this.date,
    required this.description,
    required this.amountMyr,
    required this.type,
  });

  final DateTime date;
  final String description;
  final double amountMyr;
  final String type;
}

class SupplierRepository {
  final _local = LocalStore.instance;

  Future<List<Supplier>> getSuppliers() async {
    if (!Env.isConfigured) {
      _local.seed();
      return List.from(_local.suppliers);
    }
    final data =
        await SupabaseService.client.from('suppliers').select().order('name');
    return (data as List).map((e) => Supplier.fromJson(e)).toList();
  }

  Future<Supplier> createSupplier({required String name, String? notes}) async {
    if (!Env.isConfigured) {
      _local.seed();
      return _local.addSupplier(name, notes: notes);
    }
    final data = await SupabaseService.client
        .from('suppliers')
        .insert({'name': name, 'notes': notes})
        .select()
        .single();
    return Supplier.fromJson(data);
  }

  Future<List<SupplierLedgerEntry>> getLedger(String supplierId) async {
    if (!Env.isConfigured) {
      _local.seed();
      final entries = <SupplierLedgerEntry>[];
      for (final p in _local.purchases.where((p) => p.supplierId == supplierId)) {
        entries.add(SupplierLedgerEntry(
          date: p.purchaseDate,
          description: 'Purchase (Lot)',
          amountMyr: p.totalMyr,
          type: 'purchase',
        ));
      }
      for (final a in _local.assayResults) {
        final purchase = _local.purchases
            .where((p) => p.id == a.purchaseId && p.supplierId == supplierId)
            .firstOrNull;
        if (purchase != null) {
          entries.add(SupplierLedgerEntry(
            date: a.assayDate,
            description: 'Assay adjustment',
            amountMyr: a.adjustmentMyr,
            type: 'adjustment',
          ));
        }
      }
      for (final pay in _local.payments.where((p) => p.supplierId == supplierId)) {
        entries.add(SupplierLedgerEntry(
          date: pay.paymentDate,
          description: 'Payment',
          amountMyr: -pay.amountMyr,
          type: 'payment',
        ));
      }
      entries.sort((a, b) => b.date.compareTo(a.date));
      return entries;
    }

    final purchases = await SupabaseService.client
        .from('purchases')
        .select()
        .eq('supplier_id', supplierId);
    final payments = await SupabaseService.client
        .from('payments')
        .select()
        .eq('supplier_id', supplierId);

    final entries = <SupplierLedgerEntry>[];
    for (final p in purchases as List) {
      final purchase = Purchase.fromJson(p);
      entries.add(SupplierLedgerEntry(
        date: purchase.purchaseDate,
        description: 'Purchase',
        amountMyr: purchase.totalMyr,
        type: 'purchase',
      ));
    }
    for (final pay in payments as List) {
      final payment = Payment.fromJson(pay);
      entries.add(SupplierLedgerEntry(
        date: payment.paymentDate,
        description: 'Payment',
        amountMyr: -payment.amountMyr,
        type: 'payment',
      ));
    }
    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries;
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    if (!it.moveNext()) return null;
    return it.current;
  }
}

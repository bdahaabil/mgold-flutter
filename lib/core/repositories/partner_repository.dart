import '../config/env.dart';
import '../data/local_store.dart';
import '../models/partner.dart';
import '../models/profit_distribution.dart';
import '../models/profit_distribution_line.dart';
import '../supabase/supabase_client.dart';

class PartnerRepository {
  final _local = LocalStore.instance;

  Future<List<Partner>> getPartners() async {
    if (!Env.isConfigured) {
      _local.seed();
      return List.from(_local.partners);
    }
    final data =
        await SupabaseService.client.from('partners').select().order('name');
    return (data as List).map((e) => Partner.fromJson(e)).toList();
  }

  Future<Partner> createPartner(Partner partner) async {
    if (!Env.isConfigured) {
      _local.seed();
      return _local.addPartner(partner);
    }
    final data = await SupabaseService.client
        .from('partners')
        .insert(partner.toInsertJson())
        .select()
        .single();
    return Partner.fromJson(data);
  }

  Future<ProfitDistribution> createCashout({
    required DateTime periodStart,
    required DateTime periodEnd,
    required double totalProfit,
    required List<ProfitDistributionLine> lines,
    String? notes,
  }) async {
    if (!Env.isConfigured) {
      _local.seed();
      return _local.addDistribution(
        ProfitDistribution(
          id: '',
          periodStart: periodStart,
          periodEnd: periodEnd,
          totalProfitMyr: totalProfit,
          notes: notes,
          createdAt: DateTime.now(),
        ),
        lines,
      );
    }
    final distData = await SupabaseService.client
        .from('profit_distributions')
        .insert({
          'period_start': periodStart.toIso8601String().split('T').first,
          'period_end': periodEnd.toIso8601String().split('T').first,
          'total_profit_myr': totalProfit,
          'notes': notes,
        })
        .select()
        .single();
    final distId = distData['id'] as String;
    for (final line in lines) {
      await SupabaseService.client.from('profit_distribution_lines').insert({
        'distribution_id': distId,
        'partner_id': line.partnerId,
        'amount_myr': line.amountMyr,
        'paid_at': DateTime.now().toIso8601String(),
        'notes': line.notes,
      });
    }
    final full = await SupabaseService.client
        .from('profit_distributions')
        .select('*, profit_distribution_lines(*, partners(name))')
        .eq('id', distId)
        .single();
    return ProfitDistribution.fromJson(full);
  }

  Future<List<ProfitDistribution>> getDistributions() async {
    if (!Env.isConfigured) {
      _local.seed();
      return List.from(_local.distributions);
    }
    final data = await SupabaseService.client
        .from('profit_distributions')
        .select('*, profit_distribution_lines(*, partners(name))')
        .order('created_at', ascending: false);
    return (data as List).map((e) => ProfitDistribution.fromJson(e)).toList();
  }
}

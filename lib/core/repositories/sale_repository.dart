import '../config/env.dart';
import '../data/local_store.dart';
import '../models/enums.dart';
import '../models/sale.dart';
import '../supabase/supabase_client.dart';

class SaleRepository {
  final _local = LocalStore.instance;

  Future<List<Sale>> getSales({SaleType? type}) async {
    if (!Env.isConfigured) {
      _local.seed();
      var list = List<Sale>.from(_local.sales);
      if (type != null) {
        list = list.where((s) => s.saleType == type).toList();
      }
      list.sort((a, b) => b.saleDate.compareTo(a.saleDate));
      return list;
    }
    var query = SupabaseService.client
        .from('sales')
        .select('*, lots(lot_number)');
    if (type != null) {
      query = query.eq('sale_type', type.name);
    }
    final data = await query.order('sale_date', ascending: false);
    return (data as List).map((e) => Sale.fromJson(e)).toList();
  }
}

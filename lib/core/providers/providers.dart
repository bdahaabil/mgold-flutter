import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/dashboard_repository.dart';
import '../repositories/lot_repository.dart';
import '../repositories/partner_repository.dart';
import '../repositories/pnl_repository.dart';
import '../repositories/sale_repository.dart';
import '../repositories/supplier_repository.dart';

final lotRepositoryProvider = Provider((ref) => LotRepository());
final supplierRepositoryProvider = Provider((ref) => SupplierRepository());
final saleRepositoryProvider = Provider((ref) => SaleRepository());
final partnerRepositoryProvider = Provider((ref) => PartnerRepository());
final pnlRepositoryProvider = Provider((ref) => PnlRepository());
final dashboardRepositoryProvider = Provider((ref) => DashboardRepository());

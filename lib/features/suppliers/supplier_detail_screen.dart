import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../app/design/app_spacing.dart';
import '../../app/design/tokens.dart';
import '../../core/providers/supplier_providers.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/empty_state.dart';

class SupplierDetailScreen extends ConsumerWidget {
  const SupplierDetailScreen({super.key, required this.supplierId});
  final String supplierId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suppliers = ref.watch(suppliersProvider);
    final ledger = ref.watch(supplierLedgerProvider(supplierId));
    return Scaffold(
      appBar: AppBar(title: const Text('Supplier Ledger')),
      body: suppliers.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) {
          final supplier = list.firstWhere((s) => s.id == supplierId);
          return Column(
            children: [
              AppCard(
                margin: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      supplier.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    VGap(8),
                    Text(
                      'Outstanding',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    VGap(4),
                    Text(
                      formatMyr(supplier.balanceMyr),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: supplier.balanceMyr > 0
                                ? AppTokens.gold
                                : Colors.green,
                          ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ledger.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (entries) {
                    if (entries.isEmpty) {
                      return const EmptyState(
                        message: 'No ledger entries.',
                        icon: Icons.receipt_long_outlined,
                      );
                    }
                    return ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      itemCount: entries.length,
                      itemBuilder: (context, i) {
                        final e = entries[i];
                        final positive = e.amountMyr >= 0;
                        return AppCard(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 12.h,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      e.description,
                                      style: Theme.of(context).textTheme.bodyLarge,
                                    ),
                                    VGap(4),
                                    Text(
                                      '${e.type} · ${formatDate(e.date)}',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${e.amountMyr >= 0 ? '+' : ''}${formatMyr(e.amountMyr)}',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      color: positive ? Colors.red : Colors.green,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

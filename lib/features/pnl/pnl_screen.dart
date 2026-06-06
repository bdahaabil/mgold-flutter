import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../app/design/app_spacing.dart';
import '../../app/design/tokens.dart';
import '../../core/providers/partner_providers.dart';
import '../../core/providers/pnl_providers.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/pnl_calculator.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/summary_rows.dart';

class PnlScreen extends ConsumerWidget {
  const PnlScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pnl = ref.watch(periodPnlProvider);
    final partners = ref.watch(partnersProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profit & Loss'),
        actions: [
          IconButton(
            icon: Icon(Icons.date_range, size: AppTokens.iconLg),
            onPressed: () => _pickPeriod(context, ref),
          ),
        ],
      ),
      body: pnl.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (data) => ListView(
          padding: EdgeInsets.all(16.w),
          children: [
            AppCard(
              child: SummaryRows(
                rows: [
                  SummaryRow(
                    label: 'Total Revenue',
                    value: formatMyr(data.totalRevenue),
                  ),
                  SummaryRow(
                    label: 'Total COGS',
                    value: formatMyr(data.totalCost),
                  ),
                  SummaryRow(
                    label: 'Total Expenses',
                    value: formatMyr(data.totalExpenses),
                  ),
                  SummaryRow(
                    label: 'Net Profit',
                    value: formatMyr(data.netProfit),
                    bold: true,
                    valueColor:
                        data.netProfit >= 0 ? Colors.green : Colors.red,
                  ),
                ],
              ),
            ),
            VGap(20),
            SectionHeader(title: 'Partner Shares'),
            partners.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('$e'),
              data: (list) {
                final shares = partnerShares(
                  netProfit: data.netProfit,
                  partnerPercents: {
                    for (final p in list) p.id: p.sharePercent,
                  },
                );
                return Column(
                  children: list.map((p) {
                    final amount = shares[p.id] ?? 0;
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
                                  p.name,
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                VGap(4),
                                Text(
                                  '${p.sharePercent}% stake',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          Text(
                            formatMyr(amount),
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            VGap(20),
            SectionHeader(title: 'Per Lot'),
            ...data.lotBreakdown.map(
              (row) => AppCard(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            row.lot.lotNumber,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          VGap(4),
                          Text(
                            'Rev ${formatMyr(row.pnl.revenue)} · COGS ${formatMyr(row.pnl.cogs)} · Inv ${formatMyr(row.pnl.unrealisedInventory)} · Exp ${formatMyr(row.pnl.expenses)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      formatMyr(row.pnl.netProfit),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: row.pnl.netProfit >= 0
                                ? Colors.green
                                : Colors.red,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickPeriod(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final start = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year, now.month, 1),
      firstDate: DateTime(2020),
      lastDate: now,
    );
    if (start == null || !context.mounted) return;
    final end = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: start,
      lastDate: now,
    );
    if (end != null) {
      ref.read(pnlPeriodProvider.notifier).state =
          PnlPeriod(start: start, end: end);
    }
  }
}

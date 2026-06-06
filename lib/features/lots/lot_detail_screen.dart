import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../app/design/app_spacing.dart';
import '../../app/design/tokens.dart';
import '../../core/models/holding.dart';
import '../../core/providers/dashboard_providers.dart';
import '../../core/providers/lot_providers.dart';
import '../../core/providers/supplier_providers.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/pnl_calculator.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/summary_rows.dart';
import 'widgets/forms/assay_form.dart';
import 'widgets/forms/exchange_form.dart';
import 'widgets/forms/expense_form.dart';
import 'widgets/forms/payment_form.dart';
import 'widgets/forms/purchase_form.dart';
import 'widgets/forms/refine_form.dart';
import 'widgets/forms/sale_form.dart';
import 'widgets/lot_action_sheet.dart';
import 'widgets/lot_timeline.dart';

class LotDetailScreen extends ConsumerWidget {
  const LotDetailScreen({super.key, required this.lotId});
  final String lotId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(lotDetailProvider(lotId));
    return Scaffold(
      appBar: AppBar(title: const Text('Lot Detail')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showActions(context, ref),
        child: Icon(Icons.add, size: AppTokens.iconLg),
      ),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (d) {
          final pnl = calculateLotPnl(
            purchases: d.purchases,
            assays: d.assays,
            sales: d.sales,
            expenses: d.expenses,
            holdings: d.holdings,
          );
          return ListView(
            padding: EdgeInsets.all(16.w),
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.lot.lotNumber,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    VGap(8),
                    Text(
                      'Status: ${d.lot.status.label}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (d.lot.notes != null) ...[
                      VGap(4),
                      Text(
                        d.lot.notes!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
              VGap(12),
              _HoldingsCard(holdings: d.activeHoldings),
              VGap(12),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('P&L', style: Theme.of(context).textTheme.titleMedium),
                    VGap(8),
                    SummaryRows(
                      rows: [
                        SummaryRow(label: 'Revenue', value: formatMyr(pnl.revenue)),
                        SummaryRow(label: 'COGS (sold)', value: formatMyr(pnl.cogs)),
                        SummaryRow(
                          label: 'Realised Profit',
                          value: formatMyr(pnl.realisedProfit),
                        ),
                        SummaryRow(
                          label: 'Inventory (cost)',
                          value: formatMyr(pnl.unrealisedInventory),
                        ),
                        SummaryRow(label: 'Expenses', value: formatMyr(pnl.expenses)),
                        SummaryRow(
                          label: 'Net Profit',
                          value: formatMyr(pnl.netProfit),
                          bold: true,
                          valueColor: pnl.netProfit >= 0 ? Colors.green : Colors.red,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              VGap(16),
              SectionHeader(title: 'Timeline'),
              LotTimeline(
                purchases: d.purchases,
                assays: d.assays,
                refinings: d.refinings,
                exchanges: d.exchanges,
                sales: d.sales,
                expenses: d.expenses,
                payments: d.payments,
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showActions(BuildContext context, WidgetRef ref) async {
    final action = await showLotActionSheet(context);
    if (action == null || !context.mounted) return;
    final detail = await ref.read(lotDetailProvider(lotId).future);
    if (!context.mounted) return;
    bool? saved;
    switch (action) {
      case LotAction.purchase:
        saved = await showDialog<bool>(
          context: context,
          builder: (_) => PurchaseFormDialog(lotId: lotId),
        );
      case LotAction.assay:
        saved = await showDialog<bool>(
          context: context,
          builder: (_) => AssayFormDialog(
            lotId: lotId,
            purchases: detail.purchases,
          ),
        );
      case LotAction.refine:
        saved = await showDialog<bool>(
          context: context,
          builder: (_) => RefineFormDialog(lotId: lotId),
        );
      case LotAction.exchange:
        saved = await showDialog<bool>(
          context: context,
          builder: (_) => ExchangeFormDialog(
            lotId: lotId,
            holdings: detail.holdings,
          ),
        );
      case LotAction.sale:
        saved = await showDialog<bool>(
          context: context,
          builder: (_) => SaleFormDialog(
            lotId: lotId,
            holdings: detail.holdings,
          ),
        );
      case LotAction.expense:
        saved = await showDialog<bool>(
          context: context,
          builder: (_) => ExpenseFormDialog(lotId: lotId),
        );
      case LotAction.payment:
        saved = await showDialog<bool>(
          context: context,
          builder: (_) => PaymentFormDialog(lotId: lotId),
        );
    }
    if (saved == true) {
      ref.invalidate(lotDetailProvider(lotId));
      ref.read(lotsRefreshProvider.notifier).state++;
      ref.read(dashboardRefreshProvider.notifier).state++;
      ref.read(suppliersRefreshProvider.notifier).state++;
    }
  }
}

class _HoldingsCard extends StatelessWidget {
  const _HoldingsCard({required this.holdings});
  final List<Holding> holdings;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Holdings', style: Theme.of(context).textTheme.titleMedium),
          VGap(8),
          if (holdings.isEmpty)
            Text(
              'No stock on hand.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                  ),
            )
          else
            ...holdings.map(
              (h) => Padding(
                padding: EdgeInsets.symmetric(vertical: 6.h),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${formatWeight(h.weightG)} @ ${formatPurityLabel(h.purity)}',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                    Text(
                      formatMyr(h.costBasisMyr),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

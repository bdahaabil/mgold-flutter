import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../app/design/app_spacing.dart';
import '../../app/design/tokens.dart';
import '../../core/models/profit_distribution_line.dart';
import '../../core/providers/partner_providers.dart';
import '../../core/providers/pnl_providers.dart';
import '../../core/providers/providers.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/pnl_calculator.dart';
import '../../core/widgets/app_card.dart';

class CashoutScreen extends ConsumerStatefulWidget {
  const CashoutScreen({super.key});

  @override
  ConsumerState<CashoutScreen> createState() => _CashoutScreenState();
}

class _CashoutScreenState extends ConsumerState<CashoutScreen> {
  DateTime _start = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _end = DateTime.now();
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final pnl = ref.watch(periodPnlProvider);
    final partners = ref.watch(partnersProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Record Cashout')),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppCard(
              margin: EdgeInsets.zero,
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    title: const Text('Period Start'),
                    subtitle: Text(formatDate(_start)),
                    trailing: Icon(Icons.calendar_today, size: AppTokens.iconMd),
                    onTap: () => _pickStart(),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Period End'),
                    subtitle: Text(formatDate(_end)),
                    trailing: Icon(Icons.calendar_today, size: AppTokens.iconMd),
                    onTap: () => _pickEnd(),
                  ),
                ],
              ),
            ),
            VGap(16),
            pnl.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('$e'),
              data: (data) => AppCard(
                margin: EdgeInsets.zero,
                child: Text(
                  'Net profit for period: ${formatMyr(data.netProfit)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ),
            VGap(16),
            Expanded(
              child: partners.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('$e'),
                data: (list) {
                  final profit = pnl.maybeWhen(
                    data: (d) => d.netProfit,
                    orElse: () => 0.0,
                  );
                  final shares = partnerShares(
                    netProfit: profit,
                    partnerPercents: {
                      for (final p in list) p.id: p.sharePercent,
                    },
                  );
                  return ListView(
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
                                    '${p.sharePercent}%',
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
            ),
            VGap(16),
            FilledButton(
              onPressed: _saving ? null : _recordCashout,
              child: _saving
                  ? SizedBox(
                      width: 20.w,
                      height: 20.w,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Confirm Cashout'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickStart() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime(2020),
      lastDate: _end,
    );
    if (d != null) {
      setState(() => _start = d);
      ref.read(pnlPeriodProvider.notifier).state =
          PnlPeriod(start: _start, end: _end);
    }
  }

  Future<void> _pickEnd() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _end,
      firstDate: _start,
      lastDate: DateTime.now(),
    );
    if (d != null) {
      setState(() => _end = d);
      ref.read(pnlPeriodProvider.notifier).state =
          PnlPeriod(start: _start, end: _end);
    }
  }

  Future<void> _recordCashout() async {
    final pnlData = await ref.read(periodPnlProvider.future);
    final partnerList = await ref.read(partnersProvider.future);
    if (pnlData.netProfit <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No profit to distribute for this period.'),
          ),
        );
      }
      return;
    }
    setState(() => _saving = true);
    final shares = partnerShares(
      netProfit: pnlData.netProfit,
      partnerPercents: {
        for (final p in partnerList) p.id: p.sharePercent,
      },
    );
    final lines = shares.entries
        .where((e) => e.value > 0)
        .map(
          (e) => ProfitDistributionLine(
            id: '',
            distributionId: '',
            partnerId: e.key,
            amountMyr: e.value,
            paidAt: DateTime.now(),
            createdAt: DateTime.now(),
          ),
        )
        .toList();
    await ref.read(partnerRepositoryProvider).createCashout(
          periodStart: _start,
          periodEnd: _end,
          totalProfit: pnlData.netProfit,
          lines: lines,
        );
    ref.read(partnersRefreshProvider.notifier).state++;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cashout recorded.')),
      );
      context.go('/partners');
    }
  }
}

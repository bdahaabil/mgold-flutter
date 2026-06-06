import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../app/design/app_spacing.dart';
import '../../app/design/tokens.dart';
import '../../core/models/enums.dart';
import '../../core/models/sale.dart';
import '../../core/providers/providers.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/list_screen_scaffold.dart';

final salesFilterProvider = StateProvider<SaleType?>((ref) => null);

final salesListProvider = FutureProvider((ref) async {
  final filter = ref.watch(salesFilterProvider);
  final repo = ref.watch(saleRepositoryProvider);
  return repo.getSales(type: filter);
});

class SalesScreen extends ConsumerWidget {
  const SalesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sales = ref.watch(salesListProvider);
    final filter = ref.watch(salesFilterProvider);
    return sales.when(
      loading: () => ListScreenScaffold(
        title: 'Sales',
        isLoading: true,
        itemCount: 0,
        itemBuilder: (_, __) => const SizedBox(),
        actions: [_filterButton(context, ref)],
      ),
      error: (e, _) => ListScreenScaffold(
        title: 'Sales',
        error: '$e',
        itemCount: 0,
        itemBuilder: (_, __) => const SizedBox(),
        actions: [_filterButton(context, ref)],
      ),
      data: (list) {
        final items = list.cast<Sale>();
        return ListScreenScaffold(
          title: 'Sales',
          isEmpty: items.isEmpty,
          emptyMessage: filter == null
              ? 'No sales recorded.'
              : 'No ${filter.label} sales.',
          emptyIcon: Icons.sell_outlined,
          itemCount: items.length,
          actions: [_filterButton(context, ref)],
          itemBuilder: (context, i) {
            final s = items[i];
            return AppCard(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.customerName,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        VGap(4),
                        Text(
                          '${s.saleType.label} · ${formatWeight(s.weightG)} @ ${formatPurityLabel(s.purity)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (s.lotNumber != null) ...[
                          VGap(2),
                          Text(
                            'Lot ${s.lotNumber}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatMyr(s.totalMyr),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      VGap(4),
                      Text(
                        formatDate(s.saleDate),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (s.cogsMyr != null) ...[
                        VGap(4),
                        Text(
                          'Profit ${formatMyr(s.profit)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: s.profit >= 0 ? Colors.green : Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _filterButton(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<SaleType?>(
      icon: Icon(Icons.filter_list, size: AppTokens.iconLg),
      onSelected: (v) => ref.read(salesFilterProvider.notifier).state = v,
      itemBuilder: (_) => [
        const PopupMenuItem(value: null, child: Text('All')),
        ...SaleType.values.map(
          (t) => PopupMenuItem(value: t, child: Text(t.label)),
        ),
      ],
    );
  }
}

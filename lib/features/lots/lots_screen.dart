import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../app/design/app_spacing.dart';
import '../../app/design/tokens.dart';
import '../../core/models/enums.dart';
import '../../core/models/lot.dart';
import '../../core/providers/lot_providers.dart';
import '../../core/providers/providers.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/form_dialog.dart';
import '../../core/widgets/list_screen_scaffold.dart';

class LotsScreen extends ConsumerWidget {
  const LotsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lots = ref.watch(lotsListProvider);
    return lots.when(
      loading: () => ListScreenScaffold(
        title: 'Lots',
        isLoading: true,
        itemCount: 0,
        itemBuilder: (_, __) => const SizedBox(),
        floatingActionButton: _fab(context, ref),
      ),
      error: (e, _) => ListScreenScaffold(
        title: 'Lots',
        error: '$e',
        itemCount: 0,
        itemBuilder: (_, __) => const SizedBox(),
        floatingActionButton: _fab(context, ref),
      ),
      data: (list) {
        final lotsList = list.cast<Lot>();
        return ListScreenScaffold(
          title: 'Lots',
          isEmpty: lotsList.isEmpty,
          emptyMessage: 'No lots yet. Create one to start.',
          emptyIcon: Icons.inventory_2_outlined,
          itemCount: lotsList.length,
          floatingActionButton: _fab(context, ref),
          itemBuilder: (context, i) {
            final lot = lotsList[i];
            return AppCard(
              onTap: () => context.go('/lots/${lot.id}'),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lot.lotNumber,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        VGap(4),
                        Text(
                          formatDate(lot.createdAt),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  _StatusChip(status: lot.status),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _fab(BuildContext context, WidgetRef ref) {
    return FloatingActionButton(
      onPressed: () => _createLot(context, ref),
      child: Icon(Icons.add, size: AppTokens.iconLg),
    );
  }

  Future<void> _createLot(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => FormDialog(
        title: 'New Lot',
        scrollable: false,
        children: [
          TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Lot Number'),
          ),
        ],
        onCancel: () => Navigator.pop(ctx),
        onSave: () => Navigator.pop(ctx, true),
        saveLabel: 'Create',
      ),
    );
    if (ok == true && controller.text.isNotEmpty) {
      final repo = ref.read(lotRepositoryProvider);
      final lot = await repo.createLot(lotNumber: controller.text.trim());
      ref.read(lotsRefreshProvider.notifier).state++;
      if (context.mounted) context.go('/lots/${lot.id}');
    }
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final LotStatus status;

  Color _color(BuildContext context) {
    return switch (status) {
      LotStatus.open => Theme.of(context).colorScheme.primary,
      LotStatus.assayed => Colors.purple,
      LotStatus.refined => Colors.orange,
      LotStatus.sold => Colors.green,
      LotStatus.closed => Colors.grey,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: _color(context).withValues(alpha: 0.15),
        borderRadius: AppTokens.borderRadiusSm,
      ),
      child: Text(
        status.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: _color(context),
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

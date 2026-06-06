import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../app/design/app_spacing.dart';
import '../../app/design/tokens.dart';
import '../../core/models/supplier.dart';
import '../../core/providers/providers.dart';
import '../../core/providers/supplier_providers.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/form_dialog.dart';
import '../../core/widgets/list_screen_scaffold.dart';

class SuppliersScreen extends ConsumerWidget {
  const SuppliersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(suppliersRefreshProvider);
    final suppliers = ref.watch(suppliersProvider);
    return suppliers.when(
      loading: () => ListScreenScaffold(
        title: 'Suppliers',
        isLoading: true,
        itemCount: 0,
        itemBuilder: (_, __) => const SizedBox(),
        floatingActionButton: _fab(context, ref),
      ),
      error: (e, _) => ListScreenScaffold(
        title: 'Suppliers',
        error: '$e',
        itemCount: 0,
        itemBuilder: (_, __) => const SizedBox(),
        floatingActionButton: _fab(context, ref),
      ),
      data: (list) {
        final items = list.cast<Supplier>();
        return ListScreenScaffold(
          title: 'Suppliers',
          isEmpty: items.isEmpty,
          emptyMessage: 'No suppliers yet.',
          emptyIcon: Icons.store_outlined,
          itemCount: items.length,
          floatingActionButton: _fab(context, ref),
          itemBuilder: (context, i) {
            final s = items[i];
            return AppCard(
              onTap: () => context.go('/suppliers/${s.id}'),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        VGap(4),
                        Text(
                          'Balance: ${formatMyr(s.balanceMyr)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (s.balanceMyr > 0)
                    Icon(
                      Icons.warning_amber_rounded,
                      color: AppTokens.gold,
                      size: AppTokens.iconLg,
                    ),
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
      onPressed: () => _addSupplier(context, ref),
      child: Icon(Icons.add, size: AppTokens.iconLg),
    );
  }

  Future<void> _addSupplier(BuildContext context, WidgetRef ref) async {
    final name = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => FormDialog(
        title: 'Add Supplier',
        scrollable: false,
        children: [
          TextField(
            controller: name,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
        ],
        onCancel: () => Navigator.pop(ctx),
        onSave: () => Navigator.pop(ctx, true),
      ),
    );
    if (ok == true && name.text.isNotEmpty) {
      await ref.read(supplierRepositoryProvider).createSupplier(name: name.text.trim());
      ref.read(suppliersRefreshProvider.notifier).state++;
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../app/design/app_spacing.dart';
import '../../app/design/tokens.dart';
import '../../core/config/env.dart';
import '../../core/providers/dashboard_providers.dart';
import '../../core/providers/lot_providers.dart';
import '../../core/providers/providers.dart';
import '../../core/repositories/dashboard_repository.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/form_dialog.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/stat_card.dart';
import '../../core/widgets/theme_toggle.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(dashboardSummaryProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('MGold'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, size: AppTokens.iconLg),
            onPressed: () =>
                ref.read(dashboardRefreshProvider.notifier).state++,
          ),
          const ThemeToggleButton(),
        ],
      ),
      body: summary.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (data) => RefreshIndicator(
          onRefresh: () async {
            ref.read(dashboardRefreshProvider.notifier).state++;
            await ref.read(dashboardSummaryProvider.future);
          },
          child: ListView(
            padding: EdgeInsets.all(16.w),
            children: [
              if (!Env.isConfigured) _DemoBanner(),
              _StatGrid(data: data),
              VGap(20),
              SectionHeader(title: 'Gold In Hand'),
              if (data.goldInHand.isEmpty)
                AppCard(
                  child: Text(
                    'No gold in inventory',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                )
              else
                ...data.goldInHand.entries.map(
                  (e) => AppCard(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    child: Row(
                      children: [
                        Container(
                          width: 10.w,
                          height: 10.w,
                          decoration: BoxDecoration(
                            color: AppTokens.gold,
                            shape: BoxShape.circle,
                          ),
                        ),
                        HGap(12),
                        Expanded(
                          child: Text(
                            formatPurityLabel(double.parse(e.key)),
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                        Text(
                          formatWeight(e.value),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              VGap(20),
              SectionHeader(title: 'Quick Actions'),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: [
                  _QuickAction(
                    icon: Icons.add,
                    label: 'New Lot',
                    onTap: () => _createLot(context, ref),
                  ),
                  _QuickAction(
                    icon: Icons.inventory_2_outlined,
                    label: 'View Lots',
                    onTap: () => context.go('/lots'),
                  ),
                  _QuickAction(
                    icon: Icons.payments_outlined,
                    label: 'Cashout',
                    onTap: () => context.go('/partners/cashout'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
            autofocus: true,
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
      ref.read(dashboardRefreshProvider.notifier).state++;
      if (context.mounted) context.go('/lots/${lot.id}');
    }
  }
}

class _DemoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppTokens.gold.withValues(alpha: 0.12),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppTokens.gold, size: AppTokens.iconLg),
          HGap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Demo Mode',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                VGap(4),
                Text(
                  'Supabase not configured. Using local in-memory data.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.data});
  final DashboardSummary data;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppTokens.statGridSpacing,
      crossAxisSpacing: AppTokens.statGridSpacing,
      childAspectRatio: AppTokens.statAspectRatio,
      children: [
        StatCard(
          label: 'Open Lots',
          value: '${data.openLots}',
          icon: Icons.inventory_2_outlined,
        ),
        StatCard(
          label: 'Supplier Balance',
          value: formatMyr(data.supplierBalance),
          icon: Icons.store_outlined,
        ),
        StatCard(
          label: 'Realised P&L',
          value: formatMyr(data.realisedPnl),
          icon: Icons.trending_up,
          valueColor: data.realisedPnl >= 0 ? Colors.green : Colors.red,
        ),
        StatCard(
          label: 'Unrealised',
          value: formatMyr(data.unrealisedPnl),
          icon: Icons.hourglass_empty_outlined,
        ),
        StatCard(
          label: 'Cash In',
          value: formatMyr(data.cashIn),
          icon: Icons.arrow_downward,
        ),
        StatCard(
          label: 'Cash Out',
          value: formatMyr(data.cashOut),
          icon: Icons.arrow_upward,
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: AppTokens.iconSm),
      label: Text(label),
      onPressed: onTap,
    );
  }
}

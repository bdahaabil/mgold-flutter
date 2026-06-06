import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../app/design/app_spacing.dart';
import '../../app/design/tokens.dart';
import '../../core/models/partner.dart';
import '../../core/providers/partner_providers.dart';
import '../../core/providers/providers.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/form_dialog.dart';
import '../../core/widgets/section_header.dart';

class PartnersScreen extends ConsumerWidget {
  const PartnersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(partnersRefreshProvider);
    final partners = ref.watch(partnersProvider);
    final distributions = ref.watch(distributionsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Partners'),
        actions: [
          IconButton(
            icon: Icon(Icons.payments_outlined, size: AppTokens.iconLg),
            tooltip: 'Record Cashout',
            onPressed: () => context.go('/partners/cashout'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addPartner(context, ref),
        child: Icon(Icons.person_add, size: AppTokens.iconLg),
      ),
      body: ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          SectionHeader(title: 'Partners'),
          partners.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('$e'),
            data: (list) => Column(
              children: (list as List).cast<Partner>().map((p) {
                return AppCard(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
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
                              p.email ?? 'No email',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.15),
                          borderRadius: AppTokens.borderRadiusSm,
                        ),
                        child: Text(
                          '${p.sharePercent}%',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          VGap(24),
          SectionHeader(title: 'Cashout History'),
          distributions.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('$e'),
            data: (list) {
              if (list.isEmpty) {
                return AppCard(
                  child: Text(
                    'No cashouts recorded.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                );
              }
              return Column(
                children: list.map((d) {
                  return AppCard(
                    padding: EdgeInsets.zero,
                    child: ExpansionTile(
                      tilePadding: EdgeInsets.symmetric(horizontal: 16.w),
                      title: Text(
                        '${d.periodStart.toIso8601String().split('T').first} → ${d.periodEnd.toIso8601String().split('T').first}',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      subtitle: Text(formatMyr(d.totalProfitMyr)),
                      children: d.lines
                          .map(
                            (l) => ListTile(
                              title: Text(l.partnerName ?? 'Partner'),
                              trailing: Text(
                                formatMyr(l.amountMyr),
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _addPartner(BuildContext context, WidgetRef ref) async {
    final name = TextEditingController();
    final email = TextEditingController();
    final share = TextEditingController(text: '50');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => FormDialog(
        title: 'Add Partner',
        scrollable: false,
        children: [
          TextField(
            controller: name,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          TextField(
            controller: email,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          TextField(
            controller: share,
            decoration: const InputDecoration(labelText: 'Share %'),
            keyboardType: TextInputType.number,
          ),
        ],
        onCancel: () => Navigator.pop(ctx),
        onSave: () => Navigator.pop(ctx, true),
      ),
    );
    if (ok == true && name.text.isNotEmpty) {
      await ref.read(partnerRepositoryProvider).createPartner(Partner(
        id: '',
        name: name.text.trim(),
        sharePercent: double.tryParse(share.text) ?? 0,
        email: email.text.isEmpty ? null : email.text.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
      ref.read(partnersRefreshProvider.notifier).state++;
    }
  }
}

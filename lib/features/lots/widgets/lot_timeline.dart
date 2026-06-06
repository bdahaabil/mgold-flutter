import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/design/app_spacing.dart';
import '../../../app/design/tokens.dart';
import '../../../core/models/assay_result.dart';
import '../../../core/models/exchange.dart';
import '../../../core/models/expense.dart';
import '../../../core/models/payment.dart';
import '../../../core/models/purchase.dart';
import '../../../core/models/refining_job.dart';
import '../../../core/models/sale.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';

enum TimelineEventType { purchase, assay, refining, exchange, sale, expense, payment }

class TimelineEvent {
  const TimelineEvent({
    required this.date,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.type,
    this.model,
  });

  final DateTime date;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final TimelineEventType? type;
  final Object? model;
}

class LotTimeline extends StatelessWidget {
  const LotTimeline({
    super.key,
    required this.purchases,
    required this.assays,
    required this.refinings,
    this.exchanges = const [],
    required this.sales,
    required this.expenses,
    required this.payments,
    this.onEditPurchase,
    this.onEditAssay,
    this.onEditSale,
  });

  final List<Purchase> purchases;
  final List<AssayResult> assays;
  final List<RefiningJob> refinings;
  final List<Exchange> exchanges;
  final List<Sale> sales;
  final List<Expense> expenses;
  final List<Payment> payments;
  final void Function(Purchase)? onEditPurchase;
  final void Function(AssayResult)? onEditAssay;
  final void Function(Sale)? onEditSale;

  List<TimelineEvent> _events() {
    final events = <TimelineEvent>[];
    for (final p in purchases) {
      events.add(TimelineEvent(
        date: p.purchaseDate,
        title: 'Purchase',
        subtitle:
            '${formatWeight(p.weightG)} @ ${formatPurityLabel(p.claimedPurity)} · ${formatMyr(p.totalMyr)}',
        icon: Icons.shopping_cart_outlined,
        color: Colors.blue,
        type: TimelineEventType.purchase,
        model: p,
      ));
    }
    for (final a in assays) {
      events.add(TimelineEvent(
        date: a.assayDate,
        title: 'Assay Result',
        subtitle:
            '${formatWeight(a.actualWeightG)} @ ${formatPurityLabel(a.actualPurity)} · Adj ${formatMyr(a.adjustmentMyr)}',
        icon: Icons.science_outlined,
        color: Colors.purple,
        type: TimelineEventType.assay,
        model: a,
      ));
    }
    for (final r in refinings) {
      events.add(TimelineEvent(
        date: r.receivedDate ?? r.sentDate,
        title: r.receivedDate != null ? 'Refined Received' : 'Sent to Refinery',
        subtitle:
            'In ${formatWeight(r.inputWeightG)}${r.outputWeightG != null ? ' → Out ${formatWeight(r.outputWeightG!)}' : ''}',
        icon: Icons.precision_manufacturing_outlined,
        color: Colors.orange,
        type: TimelineEventType.refining,
      ));
    }
    for (final x in exchanges) {
      events.add(TimelineEvent(
        date: x.exchangeDate,
        title: 'Exchange',
        subtitle:
            '${formatWeight(x.inputWeightG)} → ${formatWeight(x.outputWeightG)} @ ${formatPurityLabel(x.outputPurity)}'
            '${x.expenseMyr > 0 ? ' · Exp ${formatMyr(x.expenseMyr)}' : ''}'
            '${x.counterparty != null ? ' · ${x.counterparty}' : ''}',
        icon: Icons.swap_horiz,
        color: Colors.indigo,
        type: TimelineEventType.exchange,
      ));
    }
    for (final s in sales) {
      events.add(TimelineEvent(
        date: s.saleDate,
        title: 'Sale (${s.saleType.label})',
        subtitle:
            '${s.customerName} · ${formatWeight(s.weightG)} · ${formatMyr(s.totalMyr)}'
            '${s.cogsMyr != null ? ' · Profit ${formatMyr(s.profit)}' : ''}',
        icon: Icons.sell_outlined,
        color: Colors.green,
        type: TimelineEventType.sale,
        model: s,
      ));
    }
    for (final e in expenses) {
      events.add(TimelineEvent(
        date: e.expenseDate,
        title: 'Expense (${e.expenseType.label})',
        subtitle: formatMyr(e.amountMyr),
        icon: Icons.receipt_long_outlined,
        color: Colors.red,
        type: TimelineEventType.expense,
      ));
    }
    for (final p in payments) {
      events.add(TimelineEvent(
        date: p.paymentDate,
        title: p.direction.label,
        subtitle: formatMyr(p.amountMyr),
        icon: Icons.payments_outlined,
        color: Colors.teal,
        type: TimelineEventType.payment,
      ));
    }
    events.sort((a, b) => b.date.compareTo(a.date));
    return events;
  }

  VoidCallback? _editCallback(TimelineEvent e) {
    switch (e.type) {
      case TimelineEventType.purchase:
        if (onEditPurchase != null && e.model is Purchase) {
          return () => onEditPurchase!(e.model! as Purchase);
        }
      case TimelineEventType.assay:
        if (onEditAssay != null && e.model is AssayResult) {
          return () => onEditAssay!(e.model! as AssayResult);
        }
      case TimelineEventType.sale:
        if (onEditSale != null && e.model is Sale) {
          return () => onEditSale!(e.model! as Sale);
        }
      default:
        return null;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final events = _events();
    if (events.isEmpty) {
      return const EmptyState(
        message: 'No activity yet. Add a purchase to begin.',
        icon: Icons.timeline,
      );
    }
    return Column(
      children: events.map((e) {
        final onEdit = _editCallback(e);
        return AppCard(
          margin: EdgeInsets.only(bottom: 8.h),
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: e.color.withValues(alpha: 0.15),
                  borderRadius: AppTokens.borderRadiusMd,
                ),
                child: Icon(e.icon, color: e.color, size: AppTokens.iconMd),
              ),
              HGap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            e.title,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        Text(
                          formatDate(e.date),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    VGap(4),
                    Text(
                      e.subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (onEdit != null)
                IconButton(
                  icon: Icon(Icons.edit_outlined, size: AppTokens.iconMd),
                  tooltip: 'Edit',
                  onPressed: onEdit,
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

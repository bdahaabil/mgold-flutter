import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../app/design/app_spacing.dart';
import '../../../app/design/tokens.dart';

enum LotAction {
  purchase,
  assay,
  refine,
  exchange,
  sale,
  expense,
  payment,
}

Future<LotAction?> showLotActionSheet(BuildContext context) {
  return showModalBottomSheet<LotAction>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          VGap(8),
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          VGap(16),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Add to Lot',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          VGap(8),
          _ActionTile(
            icon: Icons.shopping_cart_outlined,
            title: 'Add Purchase',
            action: LotAction.purchase,
          ),
          _ActionTile(
            icon: Icons.science_outlined,
            title: 'Record Assay',
            action: LotAction.assay,
          ),
          _ActionTile(
            icon: Icons.precision_manufacturing_outlined,
            title: 'Refining',
            action: LotAction.refine,
          ),
          _ActionTile(
            icon: Icons.swap_horiz,
            title: 'Exchange',
            action: LotAction.exchange,
          ),
          _ActionTile(
            icon: Icons.sell_outlined,
            title: 'Add Sale',
            action: LotAction.sale,
          ),
          _ActionTile(
            icon: Icons.receipt_long_outlined,
            title: 'Add Expense',
            action: LotAction.expense,
          ),
          _ActionTile(
            icon: Icons.payments_outlined,
            title: 'Add Payment',
            action: LotAction.payment,
          ),
          VGap(8),
        ],
      ),
    ),
  );
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.action,
  });

  final IconData icon;
  final String title;
  final LotAction action;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
          borderRadius: AppTokens.borderRadiusMd,
        ),
        child: Icon(icon, size: AppTokens.iconMd),
      ),
      title: Text(title),
      onTap: () => Navigator.pop(context, action),
    );
  }
}

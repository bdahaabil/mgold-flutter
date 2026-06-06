import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../app/design/app_spacing.dart';

class SummaryRow {
  const SummaryRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;
}

class SummaryRows extends StatelessWidget {
  const SummaryRows({
    super.key,
    required this.rows,
    this.showDividerBeforeLast = true,
  });

  final List<SummaryRow> rows;
  final bool showDividerBeforeLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (showDividerBeforeLast && i == rows.length - 1) ...[
            const Divider(),
            VGap(4),
          ],
          _SummaryRowItem(row: rows[i]),
        ],
      ],
    );
  }
}

class _SummaryRowItem extends StatelessWidget {
  const _SummaryRowItem({required this.row});
  final SummaryRow row;

  @override
  Widget build(BuildContext context) {
    final style = row.bold
        ? Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            )
        : Theme.of(context).textTheme.bodyMedium;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(row.label, style: style),
          Text(
            row.value,
            style: style?.copyWith(
              color: row.valueColor,
              fontWeight: row.bold ? FontWeight.w700 : style.fontWeight,
            ),
          ),
        ],
      ),
    );
  }
}

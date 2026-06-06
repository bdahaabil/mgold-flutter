import 'package:intl/intl.dart';

final _myrFormat = NumberFormat.currency(locale: 'ms_MY', symbol: 'RM ');
final _weightFormat = NumberFormat('#,##0.####');
final _purityFormat = NumberFormat('#,##0.###');
final _dateFormat = DateFormat('dd MMM yyyy');

String formatMyr(num value) => _myrFormat.format(value);
String formatWeight(num value) => '${_weightFormat.format(value)} g';
String formatPurity(num value) => _purityFormat.format(value);

String formatPurityLabel(num value) =>
    '${_purityFormat.format(value)} (${(value / 100).toStringAsFixed(2)}%)';
String formatDate(DateTime value) => _dateFormat.format(value);

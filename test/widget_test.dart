import 'package:flutter_test/flutter_test.dart';

import 'package:mgold_flutter/core/utils/pnl_calculator.dart';

void main() {
  test('partner share splits profit by percent', () {
    final shares = partnerShares(
      netProfit: 1000,
      partnerPercents: {'a': 60, 'b': 40},
    );
    expect(shares['a'], 600);
    expect(shares['b'], 400);
  });

  test('lot pnl equals revenue minus cost and expenses', () {
    final pnl = calculateLotPnl(
      purchases: const [],
      assays: const [],
      sales: const [],
      expenses: const [],
    );
    expect(pnl.netProfit, 0);
  });
}

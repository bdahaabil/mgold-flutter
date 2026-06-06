enum LotStatus {
  open,
  assayed,
  refined,
  sold,
  closed;

  String get label => switch (this) {
        LotStatus.open => 'Open',
        LotStatus.assayed => 'Assayed',
        LotStatus.refined => 'Refined',
        LotStatus.sold => 'Sold',
        LotStatus.closed => 'Closed',
      };

  static LotStatus fromString(String value) =>
      LotStatus.values.firstWhere((e) => e.name == value);
}

enum SaleType {
  direct,
  refined,
  exchange916;

  String get label => switch (this) {
        SaleType.direct => 'Direct',
        SaleType.refined => 'Refined',
        SaleType.exchange916 => '916 Exchange',
      };

  static SaleType fromString(String value) =>
      SaleType.values.firstWhere((e) => e.name == value);
}

enum ExpenseType {
  assay,
  refine,
  transport,
  other;

  String get label => switch (this) {
        ExpenseType.assay => 'Assay',
        ExpenseType.refine => 'Refine',
        ExpenseType.transport => 'Transport',
        ExpenseType.other => 'Other',
      };

  static ExpenseType fromString(String value) =>
      ExpenseType.values.firstWhere((e) => e.name == value);
}

enum PaymentDirection {
  out,
  in_;

  String get label => switch (this) {
        PaymentDirection.out => 'To Supplier',
        PaymentDirection.in_ => 'From Customer',
      };

  static PaymentDirection fromString(String value) =>
      value == 'in' ? PaymentDirection.in_ : PaymentDirection.out;

  String toJson() => this == PaymentDirection.in_ ? 'in' : 'out';
}

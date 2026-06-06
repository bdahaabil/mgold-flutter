class Exchange {
  const Exchange({
    required this.id,
    required this.lotId,
    this.sourceHoldingId,
    this.outputHoldingId,
    required this.inputWeightG,
    required this.outputWeightG,
    required this.outputPurity,
    required this.expenseMyr,
    this.counterparty,
    required this.exchangeDate,
    this.notes,
    required this.createdAt,
    this.sourceHoldingLabel,
  });

  final String id;
  final String lotId;
  final String? sourceHoldingId;
  final String? outputHoldingId;
  final double inputWeightG;
  final double outputWeightG;
  final double outputPurity;
  final double expenseMyr;
  final String? counterparty;
  final DateTime exchangeDate;
  final String? notes;
  final DateTime createdAt;
  final String? sourceHoldingLabel;

  factory Exchange.fromJson(Map<String, dynamic> json) => Exchange(
        id: json['id'] as String,
        lotId: json['lot_id'] as String,
        sourceHoldingId: json['source_holding_id'] as String?,
        outputHoldingId: json['output_holding_id'] as String?,
        inputWeightG: (json['input_weight_g'] as num).toDouble(),
        outputWeightG: (json['output_weight_g'] as num).toDouble(),
        outputPurity: (json['output_purity'] as num).toDouble(),
        expenseMyr: (json['expense_myr'] as num).toDouble(),
        counterparty: json['counterparty'] as String?,
        exchangeDate: DateTime.parse(json['exchange_date'] as String),
        notes: json['notes'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        sourceHoldingLabel: json['holdings'] != null
            ? (json['holdings'] as Map<String, dynamic>)['label'] as String?
            : null,
      );

  Map<String, dynamic> toInsertJson() => {
        'lot_id': lotId,
        'source_holding_id': sourceHoldingId,
        'output_holding_id': outputHoldingId,
        'input_weight_g': inputWeightG,
        'output_weight_g': outputWeightG,
        'output_purity': outputPurity,
        'expense_myr': expenseMyr,
        'counterparty': counterparty,
        'exchange_date': exchangeDate.toIso8601String().split('T').first,
        'notes': notes,
      };
}

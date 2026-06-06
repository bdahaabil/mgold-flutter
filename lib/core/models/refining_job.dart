class RefiningJob {
  const RefiningJob({
    required this.id,
    required this.lotId,
    required this.inputWeightG,
    this.outputWeightG,
    this.outputPurity,
    this.refinery,
    required this.sentDate,
    this.receivedDate,
    this.notes,
    required this.createdAt,
  });

  final String id;
  final String lotId;
  final double inputWeightG;
  final double? outputWeightG;
  final double? outputPurity;
  final String? refinery;
  final DateTime sentDate;
  final DateTime? receivedDate;
  final String? notes;
  final DateTime createdAt;

  factory RefiningJob.fromJson(Map<String, dynamic> json) => RefiningJob(
        id: json['id'] as String,
        lotId: json['lot_id'] as String,
        inputWeightG: (json['input_weight_g'] as num).toDouble(),
        outputWeightG: json['output_weight_g'] != null
            ? (json['output_weight_g'] as num).toDouble()
            : null,
        outputPurity: json['output_purity'] != null
            ? (json['output_purity'] as num).toDouble()
            : null,
        refinery: json['refinery'] as String?,
        sentDate: DateTime.parse(json['sent_date'] as String),
        receivedDate: json['received_date'] != null
            ? DateTime.parse(json['received_date'] as String)
            : null,
        notes: json['notes'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toInsertJson() => {
        'lot_id': lotId,
        'input_weight_g': inputWeightG,
        'output_weight_g': outputWeightG,
        'output_purity': outputPurity ?? 9950,
        'refinery': refinery,
        'sent_date': sentDate.toIso8601String().split('T').first,
        'received_date': receivedDate?.toIso8601String().split('T').first,
        'notes': notes,
      };
}

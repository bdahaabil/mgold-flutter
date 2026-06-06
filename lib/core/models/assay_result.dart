class AssayResult {
  const AssayResult({
    required this.id,
    required this.lotId,
    this.purchaseId,
    required this.actualPurity,
    required this.actualWeightG,
    this.assayLab,
    required this.adjustmentMyr,
    required this.assayDate,
    this.notes,
    required this.createdAt,
  });

  final String id;
  final String lotId;
  final String? purchaseId;
  final double actualPurity;
  final double actualWeightG;
  final String? assayLab;
  final double adjustmentMyr;
  final DateTime assayDate;
  final String? notes;
  final DateTime createdAt;

  factory AssayResult.fromJson(Map<String, dynamic> json) => AssayResult(
        id: json['id'] as String,
        lotId: json['lot_id'] as String,
        purchaseId: json['purchase_id'] as String?,
        actualPurity: (json['actual_purity'] as num).toDouble(),
        actualWeightG: (json['actual_weight_g'] as num).toDouble(),
        assayLab: json['assay_lab'] as String?,
        adjustmentMyr: (json['adjustment_myr'] as num).toDouble(),
        assayDate: DateTime.parse(json['assay_date'] as String),
        notes: json['notes'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toInsertJson() => {
        'lot_id': lotId,
        'purchase_id': purchaseId,
        'actual_purity': actualPurity,
        'actual_weight_g': actualWeightG,
        'assay_lab': assayLab,
        'assay_date': assayDate.toIso8601String().split('T').first,
        'notes': notes,
      };

  Map<String, dynamic> toUpdateJson() => {
        'purchase_id': purchaseId,
        'actual_purity': actualPurity,
        'actual_weight_g': actualWeightG,
        'assay_lab': assayLab,
        'assay_date': assayDate.toIso8601String().split('T').first,
        'notes': notes,
      };
}

class Holding {
  const Holding({
    required this.id,
    required this.lotId,
    required this.label,
    required this.purity,
    required this.weightG,
    required this.originalWeightG,
    required this.costBasisMyr,
    required this.source,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String lotId;
  final String label;
  final double purity;
  final double weightG;
  final double originalWeightG;
  final double costBasisMyr;
  final String source;
  final String status;
  final DateTime createdAt;

  bool get isInHand => status == 'in_hand' && weightG > 0;

  double get costPerG => weightG > 0 ? costBasisMyr / weightG : 0;

  factory Holding.fromJson(Map<String, dynamic> json) => Holding(
        id: json['id'] as String,
        lotId: json['lot_id'] as String,
        label: json['label'] as String,
        purity: (json['purity'] as num).toDouble(),
        weightG: (json['weight_g'] as num).toDouble(),
        originalWeightG: (json['original_weight_g'] as num).toDouble(),
        costBasisMyr: (json['cost_basis_myr'] as num).toDouble(),
        source: json['source'] as String,
        status: json['status'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toInsertJson() => {
        'lot_id': lotId,
        'label': label,
        'purity': purity,
        'weight_g': weightG,
        'original_weight_g': originalWeightG,
        'cost_basis_myr': costBasisMyr,
        'source': source,
        'status': status,
      };

  Map<String, dynamic> toUpdateJson() => {
        'purity': purity,
        'weight_g': weightG,
        'cost_basis_myr': costBasisMyr,
        'status': status,
      };

  Holding copyWith({
    String? label,
    double? purity,
    double? weightG,
    double? costBasisMyr,
    String? status,
  }) =>
      Holding(
        id: id,
        lotId: lotId,
        label: label ?? this.label,
        purity: purity ?? this.purity,
        weightG: weightG ?? this.weightG,
        originalWeightG: originalWeightG,
        costBasisMyr: costBasisMyr ?? this.costBasisMyr,
        source: source,
        status: status ?? this.status,
        createdAt: createdAt,
      );
}

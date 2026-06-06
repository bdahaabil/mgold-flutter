class ProfitDistributionLine {
  const ProfitDistributionLine({
    required this.id,
    required this.distributionId,
    required this.partnerId,
    required this.amountMyr,
    this.paidAt,
    this.notes,
    required this.createdAt,
    this.partnerName,
  });

  final String id;
  final String distributionId;
  final String partnerId;
  final double amountMyr;
  final DateTime? paidAt;
  final String? notes;
  final DateTime createdAt;
  final String? partnerName;

  factory ProfitDistributionLine.fromJson(Map<String, dynamic> json) =>
      ProfitDistributionLine(
        id: json['id'] as String,
        distributionId: json['distribution_id'] as String,
        partnerId: json['partner_id'] as String,
        amountMyr: (json['amount_myr'] as num).toDouble(),
        paidAt: json['paid_at'] != null
            ? DateTime.parse(json['paid_at'] as String)
            : null,
        notes: json['notes'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        partnerName: json['partners'] != null
            ? (json['partners'] as Map<String, dynamic>)['name'] as String?
            : null,
      );

  Map<String, dynamic> toInsertJson() => {
        'distribution_id': distributionId,
        'partner_id': partnerId,
        'amount_myr': amountMyr,
        'paid_at': paidAt?.toIso8601String(),
        'notes': notes,
      };
}

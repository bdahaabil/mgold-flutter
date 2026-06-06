import 'profit_distribution_line.dart';

class ProfitDistribution {
  const ProfitDistribution({
    required this.id,
    required this.periodStart,
    required this.periodEnd,
    required this.totalProfitMyr,
    this.notes,
    required this.createdAt,
    this.lines = const [],
  });

  final String id;
  final DateTime periodStart;
  final DateTime periodEnd;
  final double totalProfitMyr;
  final String? notes;
  final DateTime createdAt;
  final List<ProfitDistributionLine> lines;

  factory ProfitDistribution.fromJson(Map<String, dynamic> json) =>
      ProfitDistribution(
        id: json['id'] as String,
        periodStart: DateTime.parse(json['period_start'] as String),
        periodEnd: DateTime.parse(json['period_end'] as String),
        totalProfitMyr: (json['total_profit_myr'] as num).toDouble(),
        notes: json['notes'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        lines: json['profit_distribution_lines'] != null
            ? (json['profit_distribution_lines'] as List)
                .map((e) =>
                    ProfitDistributionLine.fromJson(e as Map<String, dynamic>))
                .toList()
            : [],
      );

  Map<String, dynamic> toInsertJson() => {
        'period_start': periodStart.toIso8601String().split('T').first,
        'period_end': periodEnd.toIso8601String().split('T').first,
        'total_profit_myr': totalProfitMyr,
        'notes': notes,
      };
}

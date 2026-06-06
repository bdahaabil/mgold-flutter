import 'enums.dart';

class Sale {
  const Sale({
    required this.id,
    required this.lotId,
    required this.saleType,
    required this.weightG,
    required this.purity,
    required this.pricePerG,
    required this.totalMyr,
    required this.customerName,
    required this.saleDate,
    this.holdingId,
    this.cogsMyr,
    this.notes,
    required this.createdAt,
    this.lotNumber,
  });

  final String id;
  final String lotId;
  final SaleType saleType;
  final double weightG;
  final double purity;
  final double pricePerG;
  final double totalMyr;
  final String customerName;
  final DateTime saleDate;
  final String? holdingId;
  final double? cogsMyr;
  final String? notes;
  final DateTime createdAt;
  final String? lotNumber;

  double get profit => totalMyr - (cogsMyr ?? 0);

  factory Sale.fromJson(Map<String, dynamic> json) => Sale(
        id: json['id'] as String,
        lotId: json['lot_id'] as String,
        saleType: SaleType.fromString(json['sale_type'] as String),
        weightG: (json['weight_g'] as num).toDouble(),
        purity: (json['purity'] as num).toDouble(),
        pricePerG: (json['price_per_g'] as num).toDouble(),
        totalMyr: (json['total_myr'] as num).toDouble(),
        customerName: json['customer_name'] as String,
        saleDate: DateTime.parse(json['sale_date'] as String),
        holdingId: json['holding_id'] as String?,
        cogsMyr: json['cogs_myr'] != null
            ? (json['cogs_myr'] as num).toDouble()
            : null,
        notes: json['notes'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        lotNumber: json['lots'] != null
            ? (json['lots'] as Map<String, dynamic>)['lot_number'] as String?
            : null,
      );

  Map<String, dynamic> toInsertJson() => {
        'lot_id': lotId,
        'sale_type': saleType.name,
        'weight_g': weightG,
        'purity': purity,
        'price_per_g': pricePerG,
        'total_myr': totalMyr,
        'customer_name': customerName,
        'sale_date': saleDate.toIso8601String().split('T').first,
        'holding_id': holdingId,
        'cogs_myr': cogsMyr,
        'notes': notes,
      };
}

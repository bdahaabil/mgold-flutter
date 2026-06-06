class Purchase {
  const Purchase({
    required this.id,
    required this.lotId,
    required this.supplierId,
    required this.claimedPurity,
    required this.weightG,
    required this.pricePerG,
    required this.totalMyr,
    required this.purchaseDate,
    this.notes,
    required this.createdAt,
    this.supplierName,
  });

  final String id;
  final String lotId;
  final String supplierId;
  final double claimedPurity;
  final double weightG;
  final double pricePerG;
  final double totalMyr;
  final DateTime purchaseDate;
  final String? notes;
  final DateTime createdAt;
  final String? supplierName;

  factory Purchase.fromJson(Map<String, dynamic> json) => Purchase(
        id: json['id'] as String,
        lotId: json['lot_id'] as String,
        supplierId: json['supplier_id'] as String,
        claimedPurity: (json['claimed_purity'] as num).toDouble(),
        weightG: (json['weight_g'] as num).toDouble(),
        pricePerG: (json['price_per_g'] as num).toDouble(),
        totalMyr: (json['total_myr'] as num).toDouble(),
        purchaseDate: DateTime.parse(json['purchase_date'] as String),
        notes: json['notes'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        supplierName: json['suppliers'] != null
            ? (json['suppliers'] as Map<String, dynamic>)['name'] as String?
            : null,
      );

  Map<String, dynamic> toInsertJson() => {
        'lot_id': lotId,
        'supplier_id': supplierId,
        'claimed_purity': claimedPurity,
        'weight_g': weightG,
        'price_per_g': pricePerG,
        'total_myr': totalMyr,
        'purchase_date': purchaseDate.toIso8601String().split('T').first,
        'notes': notes,
      };
}

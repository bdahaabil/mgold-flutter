import 'enums.dart';

class Payment {
  const Payment({
    required this.id,
    this.lotId,
    required this.direction,
    this.referenceType,
    this.referenceId,
    this.supplierId,
    required this.amountMyr,
    required this.paymentDate,
    this.notes,
    required this.createdAt,
    this.supplierName,
  });

  final String id;
  final String? lotId;
  final PaymentDirection direction;
  final String? referenceType;
  final String? referenceId;
  final String? supplierId;
  final double amountMyr;
  final DateTime paymentDate;
  final String? notes;
  final DateTime createdAt;
  final String? supplierName;

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
        id: json['id'] as String,
        lotId: json['lot_id'] as String?,
        direction: PaymentDirection.fromString(json['direction'] as String),
        referenceType: json['reference_type'] as String?,
        referenceId: json['reference_id'] as String?,
        supplierId: json['supplier_id'] as String?,
        amountMyr: (json['amount_myr'] as num).toDouble(),
        paymentDate: DateTime.parse(json['payment_date'] as String),
        notes: json['notes'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        supplierName: json['suppliers'] != null
            ? (json['suppliers'] as Map<String, dynamic>)['name'] as String?
            : null,
      );

  Map<String, dynamic> toInsertJson() => {
        'lot_id': lotId,
        'direction': direction.toJson(),
        'reference_type': referenceType,
        'reference_id': referenceId,
        'supplier_id': supplierId,
        'amount_myr': amountMyr,
        'payment_date': paymentDate.toIso8601String().split('T').first,
        'notes': notes,
      };
}

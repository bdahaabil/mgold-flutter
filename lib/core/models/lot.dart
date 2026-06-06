import 'enums.dart';

class Lot {
  const Lot({
    required this.id,
    required this.lotNumber,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String lotNumber;
  final LotStatus status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Lot.fromJson(Map<String, dynamic> json) => Lot(
        id: json['id'] as String,
        lotNumber: json['lot_number'] as String,
        status: LotStatus.fromString(json['status'] as String),
        notes: json['notes'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'lot_number': lotNumber,
        'status': status.name,
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  Lot copyWith({
    String? lotNumber,
    LotStatus? status,
    String? notes,
  }) =>
      Lot(
        id: id,
        lotNumber: lotNumber ?? this.lotNumber,
        status: status ?? this.status,
        notes: notes ?? this.notes,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

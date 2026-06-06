class Partner {
  const Partner({
    required this.id,
    this.userId,
    required this.name,
    required this.sharePercent,
    this.email,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String? userId;
  final String name;
  final double sharePercent;
  final String? email;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Partner.fromJson(Map<String, dynamic> json) => Partner(
        id: json['id'] as String,
        userId: json['user_id'] as String?,
        name: json['name'] as String,
        sharePercent: (json['share_percent'] as num).toDouble(),
        email: json['email'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'name': name,
        'share_percent': sharePercent,
        'email': email,
      };

  Map<String, dynamic> toInsertJson() => {
        'name': name,
        'share_percent': sharePercent,
        'email': email,
        'user_id': userId,
      };
}

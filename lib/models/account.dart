class Account {
  final String? id;
  final double balance;
  final double dailyRate;
  final DateTime? lastCalculatedAt;
  final DateTime? updatedAt;

  const Account({
    this.id,
    required this.balance,
    required this.dailyRate,
    this.lastCalculatedAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'balance': balance,
      'dailyRate': dailyRate,
      'lastCalculatedAt': lastCalculatedAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory Account.fromMap(Map<String, dynamic> map, {String? id}) {
    return Account(
      id: id,
      balance: _toDouble(map['balance']),
      dailyRate: _toDouble(map['dailyRate']) ?? 0.0001, // 0.01% annually = 0.0001 daily
      lastCalculatedAt: _parseDateTime(map['lastCalculatedAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
    );
  }

  factory Account.fromJson(Map<String, dynamic> json, {String? id}) {
    return Account.fromMap(json, id: id);
  }

  Account copyWith({
    String? id,
    double? balance,
    double? dailyRate,
    DateTime? lastCalculatedAt,
    DateTime? updatedAt,
  }) {
    return Account(
      id: id ?? this.id,
      balance: balance ?? this.balance,
      dailyRate: dailyRate ?? this.dailyRate,
      lastCalculatedAt: lastCalculatedAt ?? this.lastCalculatedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }
}
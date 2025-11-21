enum OperationType {
  dailyInterest,
  task,
  bonus,
  transfer,
  goalDeposit,
}

extension OperationTypeExtension on OperationType {
  String get value {
    switch (this) {
      case OperationType.dailyInterest:
        return 'daily_interest';
      case OperationType.task:
        return 'task';
      case OperationType.bonus:
        return 'bonus';
      case OperationType.transfer:
        return 'transfer';
      case OperationType.goalDeposit:
        return 'goal_deposit';
    }
  }

  static OperationType fromString(String value) {
    switch (value) {
      case 'daily_interest':
        return OperationType.dailyInterest;
      case 'task':
        return OperationType.task;
      case 'bonus':
        return OperationType.bonus;
      case 'transfer':
        return OperationType.transfer;
      case 'goal_deposit':
        return OperationType.goalDeposit;
      default:
        return OperationType.bonus;
    }
  }
}

class Operation {
  final String? id;
  final OperationType type;
  final double amount;
  final String reason;
  final DateTime timestamp;
  final double balanceBefore;
  final double balanceAfter;

  const Operation({
    this.id,
    required this.type,
    required this.amount,
    required this.reason,
    required this.timestamp,
    required this.balanceBefore,
    required this.balanceAfter,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type.value,
      'amount': amount,
      'reason': reason,
      'timestamp': timestamp.toIso8601String(),
      'balanceBefore': balanceBefore,
      'balanceAfter': balanceAfter,
    };
  }

  factory Operation.fromMap(Map<String, dynamic> map, {String? id}) {
    return Operation(
      id: id,
      type: OperationTypeExtension.fromString(map['type'] ?? 'bonus'),
      amount: _toDouble(map['amount']),
      reason: map['reason'] ?? '',
      timestamp: _parseDateTime(map['timestamp']) ?? DateTime.now(),
      balanceBefore: _toDouble(map['balanceBefore']) ?? 0.0,
      balanceAfter: _toDouble(map['balanceAfter']) ?? 0.0,
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }
}